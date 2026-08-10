package candidate

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

var (
	ErrTypeImmutable = errors.New("themico candidate type is immutable")
	ErrNotFound      = errors.New("themico candidate not found")
)

const (
	candidateSchema    = "themico/candidate-revision"
	confirmationSchema = "themico-type-confirmation"
	maxMachineJSON     = 1 << 20
	maxContent         = 4 << 20
	maxSource          = 16 << 20
)

type CreateRequest struct {
	Zone                    model.Zone          `json:"zone"`
	Scope                   model.Scope         `json:"scope"`
	ProposedType            model.KnowledgeType `json:"proposed_type"`
	ClassificationRationale string              `json:"classification_rationale"`
	SourcePaths             []string            `json:"source_paths"`
	Relations               []model.Relation    `json:"relations"`
	L1                      model.L1            `json:"l1"`
	L2                      model.L2            `json:"l2"`
	ProposedBy              string              `json:"proposed_by"`
	ContentMarkdown         []byte              `json:"-"`
}

type ReviseRequest struct {
	CandidateID      string
	ExpectedRevision string
	ProposedType     model.KnowledgeType
	L1               model.L1
	L2               model.L2
	SourcePaths      []string
	Relations        []model.Relation
	ContentMarkdown  []byte
	RevisedBy        string
}

type TypeConfirmation struct {
	Schema            string              `json:"schema"`
	CandidateID       string              `json:"candidate_id"`
	CandidateRevision string              `json:"candidate_revision"`
	KnowledgeType     model.KnowledgeType `json:"knowledge_type"`
	ConfirmedBy       string              `json:"confirmed_by"`
	ConfirmedAt       string              `json:"confirmed_at"`
	AuthorityRef      string              `json:"authority_ref"`
}

type Service struct {
	store  *store.Store
	commit func(context.Context, store.CommitPlan) (model.Manifest, error)
}

func New(st *store.Store) *Service {
	var commit func(context.Context, store.CommitPlan) (model.Manifest, error)
	if st != nil {
		commit = st.Commit
	}
	return &Service{store: st, commit: commit}
}

func (s *Service) Create(ctx context.Context, request CreateRequest) (model.CandidateRevision, error) {
	if err := s.ready(ctx); err != nil {
		return model.CandidateRevision{}, err
	}
	if strings.TrimSpace(request.ProposedBy) == "" || strings.TrimSpace(request.ClassificationRationale) == "" {
		return model.CandidateRevision{}, validation("proposer and classification rationale are required", nil)
	}
	if err := validateContent(request.ContentMarkdown); err != nil {
		return model.CandidateRevision{}, err
	}
	if err := validateTypeZone(request.ProposedType, request.Zone); err != nil {
		return model.CandidateRevision{}, err
	}
	sources, err := s.bindSources(request.SourcePaths)
	if err != nil {
		return model.CandidateRevision{}, err
	}
	candidateID, err := s.store.AllocateID("cand_")
	if err != nil {
		return model.CandidateRevision{}, validation("allocate candidate ID", err)
	}
	revisionID, err := s.store.AllocateID("crev_")
	if err != nil {
		return model.CandidateRevision{}, validation("allocate candidate revision ID", err)
	}
	revision := model.CandidateRevision{
		Schema: candidateSchema, CandidateID: candidateID, Revision: revisionID,
		Status: model.CandidateStatusProposed, Zone: request.Zone,
		Scope: request.Scope, ProposedType: request.ProposedType,
		ClassificationRationale: request.ClassificationRationale,
		Sources:                 sources, Relations: request.Relations, L1: request.L1, L2: request.L2,
		ProposedBy: request.ProposedBy, CreatedAt: s.store.Now().Format(time.RFC3339Nano),
		ContentMarkdown: bytes.Clone(request.ContentMarkdown),
	}
	return s.persist(ctx, model.NormalizeCandidateRevision(revision), "")
}

func (s *Service) Revise(ctx context.Context, request ReviseRequest) (model.CandidateRevision, error) {
	if err := s.ready(ctx); err != nil {
		return model.CandidateRevision{}, err
	}
	if strings.TrimSpace(request.RevisedBy) == "" {
		return model.CandidateRevision{}, validation("reviser is required", nil)
	}
	if err := validateContent(request.ContentMarkdown); err != nil {
		return model.CandidateRevision{}, err
	}
	current, err := s.Inspect(ctx, request.CandidateID)
	if err != nil {
		return model.CandidateRevision{}, err
	}
	if request.ExpectedRevision == "" || request.ExpectedRevision != current.Revision {
		return model.CandidateRevision{}, conflict("candidate revision is stale", nil)
	}
	if current.Status != model.CandidateStatusProposed && current.Status != model.CandidateStatusTypeConfirmed {
		return model.CandidateRevision{}, validation("candidate status cannot be revised", nil)
	}
	if current.Status == model.CandidateStatusTypeConfirmed {
		if request.ProposedType != current.ProposedType {
			return model.CandidateRevision{}, fmt.Errorf("%w: proposed type cannot change after confirmation", ErrTypeImmutable)
		}
	} else if err := validateTypeZone(request.ProposedType, current.Zone); err != nil {
		return model.CandidateRevision{}, err
	}
	sources, err := s.bindSources(request.SourcePaths)
	if err != nil {
		return model.CandidateRevision{}, err
	}
	revisionID, err := s.store.AllocateID("crev_")
	if err != nil {
		return model.CandidateRevision{}, validation("allocate candidate revision ID", err)
	}
	revision := model.CandidateRevision{
		Schema: candidateSchema, CandidateID: current.CandidateID, Revision: revisionID,
		Status: current.Status, Zone: current.Zone, Scope: current.Scope,
		ProposedType: request.ProposedType, ClassificationRationale: current.ClassificationRationale,
		KnowledgeType: current.KnowledgeType, Sources: sources, Relations: request.Relations,
		L1: request.L1, L2: request.L2, ProposedBy: current.ProposedBy, RevisedBy: request.RevisedBy,
		CreatedAt: s.store.Now().Format(time.RFC3339Nano), PublishedRecordID: current.PublishedRecordID,
		ContentMarkdown: bytes.Clone(request.ContentMarkdown),
	}
	return s.persist(ctx, model.NormalizeCandidateRevision(revision), current.Revision)
}

func (s *Service) ConfirmType(ctx context.Context, confirmation TypeConfirmation) (model.CandidateRevision, error) {
	if err := s.ready(ctx); err != nil {
		return model.CandidateRevision{}, err
	}
	if confirmation.Schema != confirmationSchema || strings.TrimSpace(confirmation.ConfirmedBy) == "" || strings.TrimSpace(confirmation.AuthorityRef) == "" {
		return model.CandidateRevision{}, validation("confirmation fields are invalid", nil)
	}
	if _, err := time.Parse(time.RFC3339, confirmation.ConfirmedAt); err != nil {
		return model.CandidateRevision{}, validation("confirmation time is invalid", err)
	}
	current, err := s.Inspect(ctx, confirmation.CandidateID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return model.CandidateRevision{}, conflict("confirmation candidate is stale", err)
		}
		return model.CandidateRevision{}, err
	}
	if confirmation.CandidateID != current.CandidateID || confirmation.CandidateRevision != current.Revision {
		return model.CandidateRevision{}, conflict("confirmation binding is stale", nil)
	}
	if current.Status != model.CandidateStatusProposed {
		return model.CandidateRevision{}, conflict("candidate is not awaiting type confirmation", nil)
	}
	if err := validateTypeZone(confirmation.KnowledgeType, current.Zone); err != nil {
		return model.CandidateRevision{}, err
	}
	revisionID, err := s.store.AllocateID("crev_")
	if err != nil {
		return model.CandidateRevision{}, validation("allocate candidate revision ID", err)
	}
	revision := current
	revision.Revision = revisionID
	revision.Status = model.CandidateStatusTypeConfirmed
	revision.KnowledgeType = confirmation.KnowledgeType
	revision.RevisedBy = confirmation.ConfirmedBy
	revision.CreatedAt = s.store.Now().Format(time.RFC3339Nano)
	return s.persist(ctx, model.NormalizeCandidateRevision(revision), current.Revision)
}

func (s *Service) Inspect(ctx context.Context, candidateID string) (model.CandidateRevision, error) {
	if err := s.ready(ctx); err != nil {
		return model.CandidateRevision{}, err
	}
	manifest, err := s.store.Current()
	if err != nil {
		return model.CandidateRevision{}, err
	}
	var pointer model.CandidatePointer
	found := false
	for _, candidate := range manifest.CurrentCandidates {
		if candidate.CandidateID == candidateID {
			pointer = candidate
			found = true
			break
		}
	}
	if !found {
		return model.CandidateRevision{}, fmt.Errorf("%w: %s", ErrNotFound, candidateID)
	}
	root, err := os.OpenRoot(s.store.Root())
	if err != nil {
		return model.CandidateRevision{}, validation("open store root", err)
	}
	defer root.Close()
	payloadPath := candidatePath(pointer.CandidateID, pointer.Revision, "candidate.json")
	payload, err := readLimited(root, payloadPath, maxMachineJSON)
	if err != nil {
		return model.CandidateRevision{}, validation("read candidate payload", err)
	}
	canonicalPayload, err := canonical.Encode(json.RawMessage(payload))
	if err != nil || !bytes.Equal(payload, canonicalPayload) {
		return model.CandidateRevision{}, validation("candidate payload is not canonical JSON", err)
	}
	if rawDigest(canonicalPayload) != pointer.Digest {
		return model.CandidateRevision{}, validation("candidate pointer digest mismatch", nil)
	}
	var revision model.CandidateRevision
	if err := decodeExact(canonicalPayload, &revision); err != nil {
		return model.CandidateRevision{}, validation("decode candidate payload", err)
	}
	if revision.Schema != candidateSchema || revision.CandidateID != pointer.CandidateID || revision.Revision != pointer.Revision || revision.Status != pointer.Status || revision.PublishedRecordID != pointer.RecordID {
		return model.CandidateRevision{}, validation("candidate pointer binding mismatch", nil)
	}
	if err := validatePersistedRevision(revision); err != nil {
		return model.CandidateRevision{}, err
	}
	content, err := readLimited(root, candidatePath(pointer.CandidateID, pointer.Revision, "content.md"), maxContent)
	if err != nil {
		return model.CandidateRevision{}, validation("read candidate content", err)
	}
	if rawDigest(content) != revision.L3Digest {
		return model.CandidateRevision{}, validation("candidate content digest mismatch", nil)
	}
	revision.ContentMarkdown = bytes.Clone(content)
	return model.NormalizeCandidateRevision(revision), nil
}

func (s *Service) persist(ctx context.Context, revision model.CandidateRevision, expectedRevision string) (model.CandidateRevision, error) {
	if err := ctx.Err(); err != nil {
		return model.CandidateRevision{}, err
	}
	var err error
	revision.L1Digest, err = canonical.Digest(revision.L1)
	if err != nil {
		return model.CandidateRevision{}, validation("digest L1", err)
	}
	revision.L2Digest, err = canonical.Digest(revision.L2)
	if err != nil {
		return model.CandidateRevision{}, validation("digest L2", err)
	}
	revision.L3Digest = rawDigest(revision.ContentMarkdown)
	payload, err := canonical.Encode(revision)
	if err != nil {
		return model.CandidateRevision{}, validation("encode candidate payload", err)
	}
	var committed model.CandidateRevision
	if err := decodeExact(payload, &committed); err != nil {
		return model.CandidateRevision{}, validation("decode committed candidate payload", err)
	}
	committed.ContentMarkdown = bytes.Clone(revision.ContentMarkdown)
	if len(payload) > maxMachineJSON {
		return model.CandidateRevision{}, validation("candidate payload exceeds size limit", nil)
	}
	manifest, views, err := s.store.CurrentState()
	if err != nil {
		return model.CandidateRevision{}, err
	}
	if expectedRevision != "" {
		matched := false
		for _, pointer := range manifest.CurrentCandidates {
			if pointer.CandidateID == revision.CandidateID {
				matched = pointer.Revision == expectedRevision
				break
			}
		}
		if !matched {
			return model.CandidateRevision{}, conflict("candidate revision changed", nil)
		}
	}
	pointer := model.CandidatePointer{CandidateID: revision.CandidateID, Revision: revision.Revision, Status: revision.Status, Digest: rawDigest(payload), RecordID: revision.PublishedRecordID}
	manifest.CurrentCandidates = replaceCandidatePointer(manifest.CurrentCandidates, pointer)
	_, err = s.commit(ctx, store.CommitPlan{
		ExpectedGeneration: manifest.Generation,
		Writes: []store.ImmutableWrite{
			{Path: candidatePath(revision.CandidateID, revision.Revision, "candidate.json"), Data: payload},
			{Path: candidatePath(revision.CandidateID, revision.Revision, "content.md"), Data: revision.ContentMarkdown},
		},
		Manifest: manifest,
		Views:    views,
	})
	if err != nil {
		return model.CandidateRevision{}, err
	}
	return model.NormalizeCandidateRevision(committed), nil
}

func (s *Service) ready(ctx context.Context) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if s == nil || s.store == nil || s.commit == nil {
		return validation("candidate service requires a store", nil)
	}
	return nil
}

func (s *Service) bindSources(paths []string) ([]model.SourceRef, error) {
	repositoryRoot := filepath.Dir(s.store.Root())
	root, err := os.OpenRoot(repositoryRoot)
	if err != nil {
		return nil, validation("open repository root", err)
	}
	defer root.Close()
	sources := make([]model.SourceRef, 0, len(paths))
	for _, requested := range paths {
		path, err := sourcePath(requested)
		if err != nil {
			return nil, err
		}
		if err := rejectSymlinkTraversal(repositoryRoot, path); err != nil {
			return nil, err
		}
		info, err := root.Lstat(path)
		if err != nil {
			return nil, validation("inspect source", err)
		}
		if info.Mode()&os.ModeSymlink != 0 || !info.Mode().IsRegular() {
			return nil, validation("source must be a regular non-symlink file", nil)
		}
		data, err := readLimited(root, path, maxSource)
		if err != nil {
			return nil, validation("read source", err)
		}
		sources = append(sources, model.SourceRef{Path: filepath.ToSlash(path), Digest: rawDigest(data)})
	}
	return model.NormalizeSources(sources), nil
}

func sourcePath(value string) (string, error) {
	if value == "" || value == "." || strings.Contains(value, `\`) || filepath.IsAbs(value) || filepath.VolumeName(value) != "" {
		return "", validation("source path is invalid", nil)
	}
	for _, part := range strings.Split(value, "/") {
		if part == "" || part == "." || part == ".." {
			return "", validation("source path contains an invalid segment", nil)
		}
	}
	cleaned := filepath.Clean(filepath.FromSlash(value))
	if cleaned == "." || cleaned == ".." || strings.HasPrefix(cleaned, ".."+string(filepath.Separator)) {
		return "", validation("source path escapes repository root", nil)
	}
	return cleaned, nil
}

func rejectSymlinkTraversal(repositoryRoot, relative string) error {
	current := repositoryRoot
	for _, segment := range strings.Split(filepath.ToSlash(relative), "/") {
		current = filepath.Join(current, segment)
		info, err := os.Lstat(current)
		if err != nil {
			return validation("inspect source path component", err)
		}
		if info.Mode()&os.ModeSymlink != 0 {
			return validation("source path traverses a symlink", nil)
		}
	}
	return nil
}

func validateContent(content []byte) error {
	if len(content) == 0 || len(content) > maxContent {
		return validation("candidate content is empty or exceeds size limit", nil)
	}
	return nil
}

func validateTypeZone(knowledgeType model.KnowledgeType, zone model.Zone) error {
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		return validation("knowledge type is not registered", nil)
	}
	if !zone.Valid() || factory.Zone != zone {
		return validation("knowledge type is incompatible with zone", nil)
	}
	return nil
}

func validatePersistedRevision(revision model.CandidateRevision) error {
	if !revision.Status.Valid() || !revision.Zone.Valid() {
		return validation("candidate status or zone is invalid", nil)
	}
	if err := validateTypeZone(revision.ProposedType, revision.Zone); err != nil {
		return err
	}
	if revision.Status == model.CandidateStatusProposed && revision.KnowledgeType != "" {
		return validation("proposed candidate has fixed knowledge type", nil)
	}
	if revision.Status == model.CandidateStatusTypeConfirmed {
		if revision.KnowledgeType == "" {
			return validation("confirmed candidate lacks knowledge type", nil)
		}
		if err := validateTypeZone(revision.KnowledgeType, revision.Zone); err != nil {
			return err
		}
	}
	l1Digest, err := canonical.Digest(revision.L1)
	if err != nil {
		return validation("digest candidate L1", err)
	}
	l2Digest, err := canonical.Digest(revision.L2)
	if err != nil {
		return validation("digest candidate L2", err)
	}
	if l1Digest != revision.L1Digest || l2Digest != revision.L2Digest {
		return validation("candidate L1 or L2 digest mismatch", nil)
	}
	if _, err := time.Parse(time.RFC3339Nano, revision.CreatedAt); err != nil {
		return validation("candidate creation time is invalid", err)
	}
	return nil
}

func replaceCandidatePointer(current []model.CandidatePointer, pointer model.CandidatePointer) []model.CandidatePointer {
	result := make([]model.CandidatePointer, 0, len(current)+1)
	for _, existing := range current {
		if existing.CandidateID != pointer.CandidateID {
			result = append(result, existing)
		}
	}
	result = append(result, pointer)
	slices.SortFunc(result, func(left, right model.CandidatePointer) int {
		return strings.Compare(left.CandidateID, right.CandidateID)
	})
	return result
}

func candidatePath(candidateID, revision, name string) string {
	return strings.Join([]string{"candidates", candidateID, "revisions", revision, name}, "/")
}

func readLimited(root *os.Root, path string, limit int64) ([]byte, error) {
	file, err := root.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return nil, err
	}
	if !info.Mode().IsRegular() {
		return nil, fmt.Errorf("not a regular file")
	}
	data, err := io.ReadAll(io.LimitReader(file, limit+1))
	if err != nil {
		return nil, err
	}
	if int64(len(data)) > limit {
		return nil, fmt.Errorf("file exceeds size limit")
	}
	return data, nil
}

func decodeExact(data []byte, destination any) error {
	if bytes.Equal(bytes.TrimSpace(data), []byte("null")) {
		return fmt.Errorf("payload must be an object")
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	decoder.UseNumber()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		if err == nil {
			return fmt.Errorf("trailing JSON value")
		}
		return err
	}
	return nil
}

func rawDigest(data []byte) string {
	value := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(value[:])
}

func validation(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrValidation, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrValidation, message, err)
}

func conflict(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrConflict, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrConflict, message, err)
}
