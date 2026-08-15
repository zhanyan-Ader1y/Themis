package governance

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestPublishGatesFailClosed(t *testing.T) {
	for _, test := range []struct {
		name    string
		arrange func(*testing.T, *fixtureState) PublishRequest
		wantErr error
	}{
		{name: "missing approval", arrange: withoutApproval, wantErr: store.ErrPrecondition},
		{name: "wrong operation", arrange: withApprovalOperation("supersede"), wantErr: store.ErrPrecondition},
		{name: "wrong prepare digest", arrange: withApprovalDigest("sha256:" + strings.Repeat("0", 64)), wantErr: store.ErrPrecondition},
		{name: "empty approver", arrange: withApprovalApprover(""), wantErr: store.ErrPrecondition},
		{name: "source drift", arrange: withSourceDrift, wantErr: store.ErrValidation},
		{name: "generation advanced", arrange: withAdvancedGeneration, wantErr: store.ErrConflict},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			request := test.arrange(t, fixture)
			before := mustCurrent(t, fixture.store)

			if _, err := fixture.governance.Publish(context.Background(), request); !errors.Is(err, test.wantErr) {
				t.Fatalf("error: %v want %v", err, test.wantErr)
			}

			after := mustCurrent(t, fixture.store)
			if len(after.CurrentRecords) != len(before.CurrentRecords) {
				t.Fatalf("failed publish changed current records: %+v", after.CurrentRecords)
			}
			if after.Generation != before.Generation {
				t.Fatalf("failed publish advanced generation %d -> %d", before.Generation, after.Generation)
			}
		})
	}
}

func TestPreparedGenerationMatchesTheStateItsCommitProduces(t *testing.T) {
	fixture := newFixture(t)
	prepare := fixture.preparePublish(t)

	current, _, err := fixture.store.CurrentState()
	if err != nil {
		t.Fatal(err)
	}
	if prepare.ExpectedGeneration != current.Generation {
		t.Fatalf("prepare expects generation %d but the store is at %d — publish would always conflict",
			prepare.ExpectedGeneration, current.Generation)
	}
}

func TestPublishCommitsRecordProjectionAndCandidateBindingAtomically(t *testing.T) {
	fixture := newFixture(t)
	prepare := fixture.preparePublish(t)
	before := mustCurrent(t, fixture.store)

	record, err := fixture.governance.Publish(context.Background(), PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  fixture.approvalFor(t, prepare),
	})
	if err != nil {
		t.Fatal(err)
	}

	after := mustCurrent(t, fixture.store)
	if after.Generation != before.Generation+1 {
		t.Fatalf("generation %d -> %d want exactly one commit", before.Generation, after.Generation)
	}
	if record.Status != model.RecordStatusActive || record.RecordID != prepare.RecordID {
		t.Fatalf("record=%+v", record)
	}

	pointer, ok := recordPointer(after, prepare.RecordID)
	if !ok || pointer.Revision != prepare.RecordRevision || pointer.Status != model.RecordStatusActive {
		t.Fatalf("record pointer=%+v ok=%v", pointer, ok)
	}
	projection, ok := projectionRef(after, prepare.RecordID)
	if !ok || projection.Revision != prepare.RecordRevision || projection.L3Digest != prepare.L3Digest {
		t.Fatalf("projection ref=%+v ok=%v", projection, ok)
	}
	candidatePtr, ok := candidatePointer(after, prepare.CandidateID)
	if !ok || candidatePtr.Status != model.CandidateStatusPublished || candidatePtr.RecordID != prepare.RecordID {
		t.Fatalf("candidate pointer=%+v ok=%v", candidatePtr, ok)
	}
}

func TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged(t *testing.T) {
	fixture := newFixtureWithOptions(t, func(opts *store.Options) {
		opts.BeforeGenerationRename = func() error { return errors.New("injected pre-rename fault") }
	})
	prepare := fixture.preparePublish(t)
	before := mustCurrent(t, fixture.store)

	if _, err := fixture.governance.Publish(context.Background(), PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  fixture.approvalFor(t, prepare),
	}); err == nil {
		t.Fatal("publish unexpectedly succeeded")
	}

	after := mustCurrent(t, fixture.store)
	if after.Generation != before.Generation {
		t.Fatalf("interrupted publish advanced generation %d -> %d", before.Generation, after.Generation)
	}
	if _, ok := recordPointer(after, prepare.RecordID); ok {
		t.Fatal("interrupted publish exposed a record pointer")
	}
}

// ---- fixture apparatus ----

var fixedTime = time.Date(2026, 8, 15, 1, 2, 3, 456789000, time.UTC)

type fixtureState struct {
	root       string
	store      *store.Store
	candidates *candidate.Service
	governance *Service
	// armFault, when non-nil, activates a mutate-supplied
	// BeforeGenerationRename fault starting with the next commit. It is
	// called once fixture setup (candidate creation, PreparePublish's own
	// commit) has finished, so only the commit under test observes the
	// injected fault instead of every setup commit along the way.
	armFault func()
}

func newFixture(t *testing.T) *fixtureState {
	t.Helper()
	return newFixtureWithOptions(t, nil)
}

func newFixtureWithOptions(t *testing.T, mutate func(*store.Options)) *fixtureState {
	t.Helper()
	root := t.TempDir()
	var counter atomic.Uint64
	var activeHook atomic.Pointer[func() error]
	opts := store.Options{
		Clock: func() time.Time { return fixedTime },
		NewID: func(prefix string) (string, error) {
			return fmt.Sprintf("%s%032x", prefix, counter.Add(1)), nil
		},
		BeforeGenerationRename: func() error {
			if hook := activeHook.Load(); hook != nil {
				return (*hook)()
			}
			return nil
		},
	}
	var requested store.Options
	if mutate != nil {
		mutate(&requested)
	}
	st, err := store.Init(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	fixture := &fixtureState{root: root, store: st, candidates: candidate.New(st), governance: New(st), armFault: func() {}}
	if requested.BeforeGenerationRename != nil {
		hook := requested.BeforeGenerationRename
		fixture.armFault = func() { activeHook.Store(&hook) }
	}
	return fixture
}

// baseCandidateRequest builds a minimal, structurally valid design_decision
// CreateRequest whose content satisfies validate.Candidate's deterministic
// contract, so fixture.preparePublish can drive PreparePublish end to end.
func (f *fixtureState) baseCandidateRequest(t *testing.T) candidate.CreateRequest {
	t.Helper()
	return candidate.CreateRequest{
		Zone:                    model.ZoneProjectKnowledge,
		Scope:                   model.Scope{Project: "Themis"},
		ProposedType:            model.TypeDesignDecision,
		ClassificationRationale: "test classification",
		L1:                      model.L1{Title: "标题", Summary: "summary"},
		L2:                      model.L2{CoreConclusion: "conclusion", Payload: json.RawMessage(`{}`)},
		ProposedBy:              "agent:proposer",
		ContentMarkdown:         designDecisionContent(t),
	}
}

// preparePublish creates and type-confirms a fresh candidate, then prepares a
// publish for it with a passing semantic assessment.
func (f *fixtureState) preparePublish(t *testing.T) model.Prepare {
	t.Helper()
	return f.preparePublishFromRequest(t, f.baseCandidateRequest(t))
}

func (f *fixtureState) preparePublishFromRequest(t *testing.T, request candidate.CreateRequest) model.Prepare {
	t.Helper()
	created, err := f.candidates.Create(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	confirmed, err := f.candidates.ConfirmType(context.Background(), candidate.TypeConfirmation{
		Schema:            "themico-type-confirmation",
		CandidateID:       created.CandidateID,
		CandidateRevision: created.Revision,
		KnowledgeType:     request.ProposedType,
		ConfirmedBy:       "human:reviewer",
		ConfirmedAt:       f.store.Now().Format(time.RFC3339),
		AuthorityRef:      "review/1",
	})
	if err != nil {
		t.Fatal(err)
	}
	assessment := model.SemanticAssessment{
		Schema:            assessmentSchema,
		CandidateID:       confirmed.CandidateID,
		CandidateRevision: confirmed.Revision,
		Status:            model.AssessmentPass,
		CheckerIdentity:   "agent:checker",
		CheckedAt:         f.store.Now().Format(time.RFC3339),
		Notes:             "looks good",
	}
	prepare, err := f.governance.PreparePublish(context.Background(), PrepareRequest{
		CandidateID: confirmed.CandidateID,
		Assessment:  assessment,
	})
	if err != nil {
		t.Fatal(err)
	}
	// Setup is done; only commits from here on (i.e. the Publish call under
	// test) should observe a fixture-requested BeforeGenerationRename fault.
	f.armFault()
	return prepare
}

func (f *fixtureState) approvalFor(t *testing.T, prepare model.Prepare) model.Approval {
	t.Helper()
	return model.Approval{
		Schema:        approvalSchema,
		Operation:     operationPublish,
		PrepareID:     prepare.PrepareID,
		PrepareDigest: prepare.Digest,
		ApprovedBy:    "human:approver",
		ApprovedAt:    f.store.Now().Format(time.RFC3339),
		AuthorityRef:  "approval/1",
	}
}

func mustCurrent(t *testing.T, st *store.Store) model.Manifest {
	t.Helper()
	manifest, err := st.Current()
	if err != nil {
		t.Fatal(err)
	}
	return manifest
}

func recordPointer(manifest model.Manifest, recordID string) (model.RecordPointer, bool) {
	for _, pointer := range manifest.CurrentRecords {
		if pointer.RecordID == recordID {
			return pointer, true
		}
	}
	return model.RecordPointer{}, false
}

func projectionRef(manifest model.Manifest, recordID string) (model.ProjectionRef, bool) {
	for _, ref := range manifest.Projections {
		if ref.RecordID == recordID {
			return ref, true
		}
	}
	return model.ProjectionRef{}, false
}

func candidatePointer(manifest model.Manifest, candidateID string) (model.CandidatePointer, bool) {
	for _, pointer := range manifest.CurrentCandidates {
		if pointer.CandidateID == candidateID {
			return pointer, true
		}
	}
	return model.CandidatePointer{}, false
}

// ---- publish gate arrange helpers ----

func withoutApproval(t *testing.T, fixture *fixtureState) PublishRequest {
	t.Helper()
	prepare := fixture.preparePublish(t)
	approval := fixture.approvalFor(t, prepare)
	// A well-formed approval that is simply not bound to this prepare: no
	// approval was ever actually granted for prepare.PrepareID.
	approval.PrepareID = "prep_ffffffffffffffffffffffffffffffff"
	return PublishRequest{PrepareID: prepare.PrepareID, Approval: approval}
}

func withApprovalOperation(operation string) func(*testing.T, *fixtureState) PublishRequest {
	return func(t *testing.T, fixture *fixtureState) PublishRequest {
		prepare := fixture.preparePublish(t)
		approval := fixture.approvalFor(t, prepare)
		approval.Operation = operation
		return PublishRequest{PrepareID: prepare.PrepareID, Approval: approval}
	}
}

func withApprovalDigest(digest string) func(*testing.T, *fixtureState) PublishRequest {
	return func(t *testing.T, fixture *fixtureState) PublishRequest {
		prepare := fixture.preparePublish(t)
		approval := fixture.approvalFor(t, prepare)
		approval.PrepareDigest = digest
		return PublishRequest{PrepareID: prepare.PrepareID, Approval: approval}
	}
}

func withApprovalApprover(approver string) func(*testing.T, *fixtureState) PublishRequest {
	return func(t *testing.T, fixture *fixtureState) PublishRequest {
		prepare := fixture.preparePublish(t)
		approval := fixture.approvalFor(t, prepare)
		approval.ApprovedBy = approver
		return PublishRequest{PrepareID: prepare.PrepareID, Approval: approval}
	}
}

func withSourceDrift(t *testing.T, fixture *fixtureState) PublishRequest {
	t.Helper()
	path := "docs/source.txt"
	writeSource(t, fixture.root, path, []byte("v1"))
	request := fixture.baseCandidateRequest(t)
	request.SourcePaths = []string{path}
	prepare := fixture.preparePublishFromRequest(t, request)
	writeSource(t, fixture.root, path, []byte("v2"))
	return PublishRequest{PrepareID: prepare.PrepareID, Approval: fixture.approvalFor(t, prepare)}
}

func withAdvancedGeneration(t *testing.T, fixture *fixtureState) PublishRequest {
	t.Helper()
	prepare := fixture.preparePublish(t)
	approval := fixture.approvalFor(t, prepare)
	current, views, err := fixture.store.CurrentState()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := fixture.store.Commit(context.Background(), store.CommitPlan{
		ExpectedGeneration: current.Generation,
		Manifest:           current,
		Views:              views,
	}); err != nil {
		t.Fatal(err)
	}
	return PublishRequest{PrepareID: prepare.PrepareID, Approval: approval}
}

// ---- typed Chinese Markdown content builders ----

func typeHeadings(t *testing.T, knowledgeType model.KnowledgeType) []string {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	return factory.L3Headings
}

func buildContent(title string, headings []string) []byte {
	var builder strings.Builder
	builder.WriteString("# ")
	builder.WriteString(title)
	builder.WriteString("\n\n")
	for _, heading := range headings {
		builder.WriteString("## ")
		builder.WriteString(heading)
		builder.WriteString("\n正文内容。\n\n")
	}
	return []byte(strings.TrimRight(builder.String(), "\n") + "\n")
}

func designDecisionContent(t *testing.T) []byte {
	t.Helper()
	return buildContent("设计决策标题", typeHeadings(t, model.TypeDesignDecision))
}

func writeSource(t *testing.T, root, relative string, data []byte) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}
