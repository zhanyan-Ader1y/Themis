// Package query implements Themico's read side: deterministic discovery
// (Search) and depth-bounded exact-ID reads (Inspect) over the current
// manifest. Both are CLI machine authority only — filtering, selection, and
// byte-budget accounting are replayable facts; relevance and semantic
// explanation stay with the Agent. Neither function implements history,
// relation expansion, cross-Zone search, or relevance ranking: those belong
// to a later plan and are deliberately absent from these request shapes.
package query

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

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

// ErrBudgetExceeded reports that returning every matched item would exceed
// the caller's declared byte budget. The whole request fails closed: Search
// and Inspect never truncate, summarize, or return a partial result.
var ErrBudgetExceeded = errors.New("themico query budget exceeded")

const (
	maxMachineJSONBytes = 1 << 20
	maxContentBytes     = 4 << 20
	minContentBudget    = 1
	maxContentBudget    = 16 << 20
)

// Request is a deterministic, Zone-scoped discovery filter over the current
// manifest's active records. Zones is required and non-empty; empty Types
// means every registered knowledge type, and empty Statuses means active
// only. The *Any fields require a non-empty set intersection; Project
// requires an exact match when non-empty.
type Request struct {
	Zones              []model.Zone          `json:"zones"`
	Types              []model.KnowledgeType `json:"types"`
	Statuses           []model.RecordStatus  `json:"statuses"`
	Project            string                `json:"project"`
	DomainsAny         []string              `json:"domains_any"`
	ArchitectureAny    []string              `json:"architecture_units_any"`
	FeaturesAny        []string              `json:"features_any"`
	TagsAny            []string              `json:"tags_any"`
	TriggersAny        []string              `json:"triggers_any"`
	ContentBudgetBytes int64                 `json:"content_budget_bytes"`
}

// Candidate is one L1 discovery row. It never carries L2 or L3 content, even
// though the current on-disk projection happens to also hold the full
// record's L2: the discovery/upgrade boundary is an API-level guarantee, not
// an accident of storage layout.
type Candidate struct {
	RecordID string              `json:"record_id"`
	Revision string              `json:"record_revision"`
	Zone     model.Zone          `json:"zone"`
	Type     model.KnowledgeType `json:"knowledge_type"`
	Status   model.RecordStatus  `json:"status"`
	L1       model.L1            `json:"l1"`
}

// Result is Search's return value.
type Result struct {
	Generation uint64      `json:"generation"`
	Candidates []Candidate `json:"candidates"`
	Trace      Trace       `json:"trace"`
}

// Trace records replayable machine facts only. Agent relevance and semantic
// explanation stay outside CLI authority.
type Trace struct {
	ObservedGeneration uint64   `json:"observed_generation"`
	SearchedZones      []string `json:"searched_zones"`
	CandidateIDs       []string `json:"candidate_ids"`
	SelectedIDs        []string `json:"selected_ids"`
	ExcludedIDs        []string `json:"excluded_ids"`
	ContentBytes       int64    `json:"content_bytes"`
	RemainingBytes     int64    `json:"remaining_bytes"`
}

// Search applies deterministic Zone/Type/Status/Scope/tag/trigger filters to
// the current manifest and returns matching records' L1 projections in
// stable (record_id, record_revision) order. Every candidate's projection
// binding is independently re-verified against the manifest's frozen
// ProjectionRef before it is returned; any binding failure fails the whole
// request closed with store.ErrValidation instead of skipping the record.
func Search(ctx context.Context, st *store.Store, request Request) (Result, error) {
	if err := ctx.Err(); err != nil {
		return Result{}, err
	}
	if st == nil {
		return Result{}, validationError("query requires a store", nil)
	}
	if err := validateSearchRequest(request); err != nil {
		return Result{}, err
	}

	zones := zoneSet(request.Zones)
	types := typeSetOrDefault(request.Types)
	statuses := statusSetOrDefault(request.Statuses)

	manifest, err := st.Current()
	if err != nil {
		return Result{}, err
	}
	root, err := os.OpenRoot(st.Root())
	if err != nil {
		return Result{}, validationError("open store root", err)
	}
	defer root.Close()

	candidateIDs := []string{}
	selectedIDs := []string{}
	excludedIDs := []string{}
	candidates := []Candidate{}
	var totalBytes int64

	for _, pointer := range manifest.CurrentRecords {
		if err := ctx.Err(); err != nil {
			return Result{}, err
		}
		if !statuses[pointer.Status] {
			continue
		}
		ref, ok := findProjectionRef(manifest.Projections, pointer.RecordID, pointer.Revision)
		if !ok {
			return Result{}, validationError("record pointer has no matching projection reference", nil)
		}
		projection, err := readProjectionL1(root, ref)
		if err != nil {
			return Result{}, err
		}
		candidateIDs = append(candidateIDs, pointer.RecordID)

		if !zones[string(projection.Zone)] || !types[projection.KnowledgeType] || !matchesScope(request, projection.Scope, projection.L1) {
			excludedIDs = append(excludedIDs, pointer.RecordID)
			continue
		}

		candidate := Candidate{
			RecordID: projection.RecordID,
			Revision: projection.Revision,
			Zone:     projection.Zone,
			Type:     projection.KnowledgeType,
			Status:   projection.Status,
			L1:       projection.L1,
		}
		encoded, err := canonical.Encode(candidate)
		if err != nil {
			return Result{}, validationError("encode candidate", err)
		}
		totalBytes += int64(len(encoded))
		selectedIDs = append(selectedIDs, pointer.RecordID)
		candidates = append(candidates, candidate)
	}

	trace := Trace{
		ObservedGeneration: manifest.Generation,
		SearchedZones:      zoneStrings(request.Zones),
		CandidateIDs:       candidateIDs,
		SelectedIDs:        selectedIDs,
		ExcludedIDs:        excludedIDs,
		ContentBytes:       totalBytes,
		RemainingBytes:     request.ContentBudgetBytes - totalBytes,
	}

	if totalBytes > request.ContentBudgetBytes {
		trace.SelectedIDs = []string{}
		trace.ExcludedIDs = candidateIDs
		return Result{Generation: manifest.Generation, Candidates: []Candidate{}, Trace: trace}, ErrBudgetExceeded
	}

	return Result{Generation: manifest.Generation, Candidates: candidates, Trace: trace}, nil
}

func validateSearchRequest(request Request) error {
	if len(request.Zones) == 0 {
		return validationError("zones is required", nil)
	}
	for _, zone := range request.Zones {
		if !zone.Valid() {
			return validationError("zone is invalid", nil)
		}
	}
	for _, knowledgeType := range request.Types {
		if !knowledgeType.Valid() {
			return validationError("knowledge type is invalid", nil)
		}
	}
	for _, status := range request.Statuses {
		if !status.Valid() {
			return validationError("record status is invalid", nil)
		}
	}
	return validateBudget(request.ContentBudgetBytes)
}

func validateBudget(value int64) error {
	if value < minContentBudget || value > maxContentBudget {
		return validationError("content budget bytes must be between 1 and 16 MiB", nil)
	}
	return nil
}

func zoneSet(zones []model.Zone) map[string]bool {
	set := make(map[string]bool, len(zones))
	for _, zone := range zones {
		set[string(zone)] = true
	}
	return set
}

func zoneStrings(zones []model.Zone) []string {
	result := make([]string, 0, len(zones))
	for _, zone := range zones {
		result = append(result, string(zone))
	}
	return result
}

func typeSetOrDefault(types []model.KnowledgeType) map[model.KnowledgeType]bool {
	set := make(map[model.KnowledgeType]bool)
	if len(types) == 0 {
		for _, factory := range model.Factories() {
			set[factory.Type] = true
		}
		return set
	}
	for _, knowledgeType := range types {
		set[knowledgeType] = true
	}
	return set
}

func statusSetOrDefault(statuses []model.RecordStatus) map[model.RecordStatus]bool {
	set := make(map[model.RecordStatus]bool)
	if len(statuses) == 0 {
		set[model.RecordStatusActive] = true
		return set
	}
	for _, status := range statuses {
		set[status] = true
	}
	return set
}

func matchesScope(request Request, scope model.Scope, l1 model.L1) bool {
	if request.Project != "" && request.Project != scope.Project {
		return false
	}
	if len(request.DomainsAny) > 0 && !hasIntersection(request.DomainsAny, scope.Domains) {
		return false
	}
	if len(request.ArchitectureAny) > 0 && !hasIntersection(request.ArchitectureAny, scope.ArchitectureUnits) {
		return false
	}
	if len(request.FeaturesAny) > 0 && !hasIntersection(request.FeaturesAny, scope.Features) {
		return false
	}
	if len(request.TagsAny) > 0 && !hasIntersection(request.TagsAny, l1.Tags) {
		return false
	}
	if len(request.TriggersAny) > 0 && !hasIntersection(request.TriggersAny, l1.Triggers) {
		return false
	}
	return true
}

func hasIntersection(want, have []string) bool {
	haveSet := make(map[string]struct{}, len(have))
	for _, value := range have {
		haveSet[value] = struct{}{}
	}
	for _, value := range want {
		if _, ok := haveSet[value]; ok {
			return true
		}
	}
	return false
}

func findProjectionRef(refs []model.ProjectionRef, recordID, revision string) (model.ProjectionRef, bool) {
	for _, ref := range refs {
		if ref.RecordID == recordID && ref.Revision == revision {
			return ref, true
		}
	}
	return model.ProjectionRef{}, false
}

func findRecordPointer(pointers []model.RecordPointer, recordID string) (model.RecordPointer, bool) {
	for _, pointer := range pointers {
		if pointer.RecordID == recordID {
			return pointer, true
		}
	}
	return model.RecordPointer{}, false
}

// readProjectionL1 reads projections/<record-id>/<record-revision>/l1.json
// and independently re-verifies its binding to ref: identity, a recomputed
// L1 digest against ref.L1Digest, and the embedded L3Digest against
// ref.L3Digest. On disk today l1.json happens to be a byte-identical copy of
// the full projection (including L2) — a known store-layer constraint this
// package does not attempt to fix — but only RecordID/Revision/L1Digest/
// L3Digest are trusted from it, so this stays correct once l1.json and
// l2.json are split.
func readProjectionL1(root *os.Root, ref model.ProjectionRef) (model.Projection, error) {
	data, err := readMachineJSON(root, projectionPath(ref.RecordID, ref.Revision, "l1.json"))
	if err != nil {
		return model.Projection{}, err
	}
	if rawDigest(data) != ref.L1Digest {
		return model.Projection{}, validationError("projection l1 digest does not match reference", nil)
	}
	var projection model.Projection
	if err := decodeExact(data, &projection); err != nil {
		return model.Projection{}, validationError("decode projection l1", err)
	}
	if projection.RecordID != ref.RecordID || projection.Revision != ref.Revision {
		return model.Projection{}, validationError("projection l1 identity does not match reference", nil)
	}
	if projection.L3Digest != ref.L3Digest {
		return model.Projection{}, validationError("projection l3 digest does not match reference", nil)
	}
	return projection, nil
}

// readProjectionL2 reads projections/<record-id>/<record-revision>/l2.json
// independently of l1.json and verifies its own binding: identity and a
// recomputed L2 digest against ref.L2Digest.
func readProjectionL2(root *os.Root, ref model.ProjectionRef) (model.L2, error) {
	data, err := readMachineJSON(root, projectionPath(ref.RecordID, ref.Revision, "l2.json"))
	if err != nil {
		return model.L2{}, err
	}
	if rawDigest(data) != ref.L2Digest {
		return model.L2{}, validationError("projection l2 digest does not match reference", nil)
	}
	var projection model.Projection
	if err := decodeExact(data, &projection); err != nil {
		return model.L2{}, validationError("decode projection l2", err)
	}
	if projection.RecordID != ref.RecordID || projection.Revision != ref.Revision {
		return model.L2{}, validationError("projection l2 identity does not match reference", nil)
	}
	return projection.L2, nil
}

// readContentL3 reads records/<record-id>/revisions/<record-revision>/
// content.md and verifies its raw digest against ref.L3Digest.
func readContentL3(root *os.Root, recordID, revision string, ref model.ProjectionRef) (string, error) {
	data, err := readLimited(root, recordPath(recordID, revision, "content.md"), maxContentBytes)
	if err != nil {
		return "", validationError("read record content", err)
	}
	if rawDigest(data) != ref.L3Digest {
		return "", validationError("record content digest does not match projection reference", nil)
	}
	return string(data), nil
}

func readMachineJSON(root *os.Root, path string) ([]byte, error) {
	data, err := readLimited(root, path, maxMachineJSONBytes)
	if err != nil {
		return nil, validationError("read projection", err)
	}
	canonicalBytes, err := canonical.Encode(json.RawMessage(data))
	if err != nil {
		return nil, validationError("projection is not canonical JSON", err)
	}
	return canonicalBytes, nil
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

func projectionPath(recordID, revision, name string) string {
	return filepath.Join("projections", recordID, revision, name)
}

func recordPath(recordID, revision, name string) string {
	return filepath.Join("records", recordID, "revisions", revision, name)
}

func validationError(message string, err error) error {
	if err == nil {
		return fmt.Errorf("%w: %s", store.ErrValidation, message)
	}
	return fmt.Errorf("%w: %s: %v", store.ErrValidation, message, err)
}

func notFoundError(message string) error {
	return fmt.Errorf("%w: %s", store.ErrNotFound, message)
}
