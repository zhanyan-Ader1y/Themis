// Package governance implements the deterministic publish chain: an
// independent semantic assessment, a frozen prepare artifact, Human
// Approval, and a single atomic generation commit that turns a candidate
// into a formal record. The CLI is the only machine authority here; it
// proves structure, binding, and currentness, and never itself decides
// whether a candidate's content is correct.
package governance

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/validate"
)

const (
	operationPublish = "publish"
	prepareSchema    = "themico/prepare"
	recordSchema     = "themico/record-revision"
	projectionSchema = "themico/projection"

	maxMachineJSON = 1 << 20
	maxSourceBytes = 16 << 20
)

// Service governs candidate publication: semantic assessment binding,
// prepare freezing, approval binding, and the single generation commit that
// makes a record current.
type Service struct {
	store *store.Store
}

// New creates a Service bound to st.
func New(st *store.Store) *Service {
	return &Service{store: st}
}

// PrepareRequest asks the Service to freeze one candidate revision, its
// independent semantic assessment, and the exact record/projection bytes one
// later Publish call may commit.
type PrepareRequest struct {
	CandidateID string
	Assessment  model.SemanticAssessment
}

// PreparePublish proves the candidate passes the deterministic validate gate
// and carries a binding, passing semantic assessment, then freezes every
// input one authorized Publish call may commit. Its own commit only adds the
// immutable prepare and assessment artifacts; it never changes a current
// pointer.
func (s *Service) PreparePublish(ctx context.Context, request PrepareRequest) (model.Prepare, error) {
	if err := s.ready(ctx); err != nil {
		return model.Prepare{}, err
	}

	candidateService := candidate.New(s.store)
	candidateRevision, err := candidateService.Inspect(ctx, request.CandidateID)
	if err != nil {
		return model.Prepare{}, err
	}

	report, err := validate.Candidate(ctx, s.store, request.CandidateID, candidateRevision.Revision)
	if err != nil {
		return model.Prepare{}, err
	}
	if !report.OK {
		return model.Prepare{}, validationError("candidate failed deterministic validation", nil)
	}

	if err := checkAssessment(request.Assessment, candidateRevision); err != nil {
		return model.Prepare{}, err
	}

	manifest, views, err := s.store.CurrentState()
	if err != nil {
		return model.Prepare{}, err
	}

	recordID, err := s.store.AllocateID("kr_")
	if err != nil {
		return model.Prepare{}, err
	}
	recordRevisionID, err := s.store.AllocateID("rev_")
	if err != nil {
		return model.Prepare{}, err
	}
	prepareID, err := s.store.AllocateID("prep_")
	if err != nil {
		return model.Prepare{}, err
	}

	createdAt := s.store.Now().Format(time.RFC3339Nano)
	// store.Commit sets the new manifest's generation to current+1; this
	// prepare's own commit below is itself such a commit, so the generation
	// it freezes for the later publish must be current+1, not current.
	expectedGeneration := manifest.Generation + 1

	// AuthorizationDigest is unknown until a real Approval exists, so it is
	// frozen here as an empty placeholder; content.md, l1.json, and l2.json
	// do not depend on it and are fully determined at this point.
	record := buildRecordRevision(candidateRevision, recordID, recordRevisionID, createdAt, expectedGeneration, "")
	recordBytes, err := canonical.Encode(record)
	if err != nil {
		return model.Prepare{}, validationError("encode record revision", err)
	}
	contentBytes := append([]byte(nil), candidateRevision.ContentMarkdown...)

	projection := buildProjection(record)
	projectionBytes, err := canonical.Encode(projection)
	if err != nil {
		return model.Prepare{}, validationError("encode projection", err)
	}

	candidateDigest, err := canonical.Digest(candidateRevision)
	if err != nil {
		return model.Prepare{}, validationError("digest candidate revision", err)
	}

	assessmentBytes, err := canonical.Encode(request.Assessment)
	if err != nil {
		return model.Prepare{}, validationError("encode assessment", err)
	}
	assessmentDigest := rawDigest(assessmentBytes)

	prepare := model.Prepare{
		Schema:             prepareSchema,
		PrepareID:          prepareID,
		Operation:          operationPublish,
		CandidateID:        candidateRevision.CandidateID,
		CandidateRevision:  candidateRevision.Revision,
		CandidateDigest:    candidateDigest,
		AssessmentDigest:   assessmentDigest,
		Sources:            append([]model.SourceRef(nil), candidateRevision.Sources...),
		ExpectedGeneration: expectedGeneration,
		RecordID:           recordID,
		RecordRevision:     recordRevisionID,
		L1Digest:           record.L1Digest,
		L2Digest:           record.L2Digest,
		L3Digest:           record.L3Digest,
		Writes: []model.PreparedWrite{
			{Path: recordPath(recordID, recordRevisionID, "record.json"), Digest: rawDigest(recordBytes)},
			{Path: recordPath(recordID, recordRevisionID, "content.md"), Digest: rawDigest(contentBytes)},
			{Path: projectionPath(recordID, recordRevisionID, "l1.json"), Digest: rawDigest(projectionBytes)},
			{Path: projectionPath(recordID, recordRevisionID, "l2.json"), Digest: rawDigest(projectionBytes)},
		},
		Invalidations: []model.ProjectionRef{},
		CreatedAt:     createdAt,
	}
	prepareDigest, err := computePrepareDigest(prepare)
	if err != nil {
		return model.Prepare{}, err
	}
	prepare.Digest = prepareDigest

	prepareBytes, err := canonical.Encode(prepare)
	if err != nil {
		return model.Prepare{}, validationError("encode prepare", err)
	}
	assessmentPathValue, err := assessmentPath(assessmentDigest)
	if err != nil {
		return model.Prepare{}, err
	}

	if _, err := s.store.Commit(ctx, store.CommitPlan{
		ExpectedGeneration: manifest.Generation,
		Writes: []store.ImmutableWrite{
			{Path: preparePath(prepareID), Data: prepareBytes},
			{Path: assessmentPathValue, Data: assessmentBytes},
		},
		Manifest: manifest,
		Views:    views,
	}); err != nil {
		return model.Prepare{}, err
	}

	return prepare, nil
}

func (s *Service) ready(ctx context.Context) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if s == nil || s.store == nil {
		return validationError("governance service requires a store", nil)
	}
	return nil
}

// computePrepareDigest mirrors the store's own manifest-digest pattern: the
// self field is cleared to empty before the canonical digest is computed.
func computePrepareDigest(prepare model.Prepare) (string, error) {
	prepare.Digest = ""
	digest, err := canonical.Digest(prepare)
	if err != nil {
		return "", validationError("digest prepare", err)
	}
	return digest, nil
}

// buildRecordRevision deterministically derives a record revision from a
// candidate revision. Every field but authorizationDigest is fully
// determined by the candidate and by the identifiers/generation frozen at
// prepare time, so this function produces byte-identical output whether it
// is called at prepare time (authorizationDigest empty) or at publish time
// (authorizationDigest filled from the real approval).
func buildRecordRevision(candidateRevision model.CandidateRevision, recordID, recordRevisionID, createdAt string, generation uint64, authorizationDigest string) model.RecordRevision {
	record := model.RecordRevision{
		Schema:              recordSchema,
		RecordID:            recordID,
		Revision:            recordRevisionID,
		KnowledgeType:       candidateRevision.KnowledgeType,
		Zone:                candidateRevision.Zone,
		Status:              model.RecordStatusActive,
		Scope:               candidateRevision.Scope,
		Sources:             candidateRevision.Sources,
		Relations:           candidateRevision.Relations,
		L1:                  candidateRevision.L1,
		L2:                  candidateRevision.L2,
		L1Digest:            candidateRevision.L1Digest,
		L2Digest:            candidateRevision.L2Digest,
		L3Digest:            candidateRevision.L3Digest,
		AuthorizationDigest: authorizationDigest,
		CreatedAt:           createdAt,
		Generation:          generation,
		ContentMarkdown:     candidateRevision.ContentMarkdown,
	}
	return model.NormalizeRecordRevision(record)
}

// buildProjection derives the shared projection object written identically
// to both l1.json and l2.json; the two paths carry the same bytes, and the
// manifest's ProjectionRef.L1Digest/L2Digest both equal that shared digest.
func buildProjection(record model.RecordRevision) model.Projection {
	projection := model.Projection{
		Schema:        projectionSchema,
		RecordID:      record.RecordID,
		Revision:      record.Revision,
		KnowledgeType: record.KnowledgeType,
		Zone:          record.Zone,
		Status:        record.Status,
		Scope:         record.Scope,
		L1:            record.L1,
		L2:            record.L2,
		L1Digest:      record.L1Digest,
		L2Digest:      record.L2Digest,
		L3Digest:      record.L3Digest,
	}
	return model.NormalizeProjection(projection)
}

// checkSourceCurrency re-reads every frozen source's actual repository bytes
// and compares them against the digest bound at prepare time.
func checkSourceCurrency(repositoryRoot string, sources []model.SourceRef) error {
	root, err := os.OpenRoot(repositoryRoot)
	if err != nil {
		return validationError("open repository root", err)
	}
	defer root.Close()
	for _, source := range sources {
		data, err := readLimited(root, filepath.FromSlash(source.Path), maxSourceBytes)
		if err != nil {
			return validationError("source cannot be read", err)
		}
		if rawDigest(data) != source.Digest {
			return validationError("source bytes changed after binding", nil)
		}
	}
	return nil
}

// ---- immutable path helpers ----

func candidatePath(candidateID, revision, name string) string {
	return strings.Join([]string{"candidates", candidateID, "revisions", revision, name}, "/")
}

func recordPath(recordID, revision, name string) string {
	return strings.Join([]string{"records", recordID, "revisions", revision, name}, "/")
}

func projectionPath(recordID, revision, name string) string {
	return strings.Join([]string{"projections", recordID, revision, name}, "/")
}

func preparePath(prepareID string) string {
	return strings.Join([]string{"preparations", prepareID, "prepare.json"}, "/")
}

// digestArtifactName converts a "sha256:<64 hex>" digest into the fixed
// "sha256-<64 hex>.json" file name the store's immutable path whitelist
// requires for assessments and approvals (a literal colon is not an allowed
// path character).
func digestArtifactName(digest string) (string, error) {
	const prefix = "sha256:"
	if !strings.HasPrefix(digest, prefix) || len(digest) != len(prefix)+64 {
		return "", validationError("digest has an unexpected shape", nil)
	}
	return "sha256-" + digest[len(prefix):] + ".json", nil
}

func assessmentPath(digest string) (string, error) {
	name, err := digestArtifactName(digest)
	if err != nil {
		return "", err
	}
	return strings.Join([]string{"assessments", name}, "/"), nil
}

func approvalPath(digest string) (string, error) {
	name, err := digestArtifactName(digest)
	if err != nil {
		return "", err
	}
	return strings.Join([]string{"approvals", name}, "/"), nil
}

func replaceCandidatePointer(current []model.CandidatePointer, pointer model.CandidatePointer) []model.CandidatePointer {
	result := make([]model.CandidatePointer, 0, len(current)+1)
	for _, existing := range current {
		if existing.CandidateID != pointer.CandidateID {
			result = append(result, existing)
		}
	}
	return append(result, pointer)
}

// ---- shared error, digest, and decode helpers ----

func validationError(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrValidation, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrValidation, message, err)
}

func preconditionError(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrPrecondition, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrPrecondition, message, err)
}

func conflictError(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrConflict, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrConflict, message, err)
}

func rawDigest(data []byte) string {
	value := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(value[:])
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
