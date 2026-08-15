package query

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/governance"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestSearchReturnsOnlyCurrentActiveL1InStableOrder(t *testing.T) {
	fixture := newFixture(t)
	decision := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})
	standard := fixture.publish(t, model.TypeDevelopmentStandard, "themis", []string{"core"}, []string{"review"})
	experience := fixture.publish(t, model.TypeDevelopmentExperience, "themis", []string{"store"}, []string{"commit"})

	result, err := Search(context.Background(), fixture.store, Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		ContentBudgetBytes: 1 << 20,
	})
	if err != nil {
		t.Fatal(err)
	}

	got := recordIDs(result.Candidates)
	want := sortedIDs(decision.RecordID, standard.RecordID)
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("candidates=%v want %v (experience %s is in the other zone)", got, want, experience.RecordID)
	}
	for _, candidate := range result.Candidates {
		if candidate.Status != model.RecordStatusActive {
			t.Fatalf("non-active candidate: %+v", candidate)
		}
	}
}

func TestSearchAppliesDeterministicFilters(t *testing.T) {
	fixture := newFixture(t)
	matching := fixture.publishWithL1(t, model.TypeDesignDecision, model.L1{
		Title: "决策", Summary: "摘要", Triggers: []string{"发布"}, Tags: []string{"governance"},
	})
	fixture.publishWithL1(t, model.TypeDesignDecision, model.L1{
		Title: "其他", Summary: "摘要", Triggers: []string{"查询"}, Tags: []string{"query"},
	})

	for _, test := range []struct {
		name    string
		request Request
	}{
		{name: "tags", request: Request{TagsAny: []string{"governance"}}},
		{name: "triggers", request: Request{TriggersAny: []string{"发布"}}},
		{name: "types", request: Request{Types: []model.KnowledgeType{model.TypeDesignDecision}, TagsAny: []string{"governance"}}},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := test.request
			request.Zones = []model.Zone{model.ZoneProjectKnowledge}
			request.ContentBudgetBytes = 1 << 20

			result, err := Search(context.Background(), fixture.store, request)
			if err != nil {
				t.Fatal(err)
			}
			if len(result.Candidates) != 1 || result.Candidates[0].RecordID != matching.RecordID {
				t.Fatalf("candidates=%v want only %s", recordIDs(result.Candidates), matching.RecordID)
			}
		})
	}
}

func TestSearchRejectsMissingZonesAndOutOfRangeBudget(t *testing.T) {
	fixture := newFixture(t)
	fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	for _, test := range []struct {
		name    string
		request Request
	}{
		{name: "no zones", request: Request{ContentBudgetBytes: 1 << 20}},
		{name: "zero budget", request: Request{Zones: []model.Zone{model.ZoneProjectKnowledge}, ContentBudgetBytes: 0}},
		{name: "over max budget", request: Request{Zones: []model.Zone{model.ZoneProjectKnowledge}, ContentBudgetBytes: (16 << 20) + 1}},
	} {
		t.Run(test.name, func(t *testing.T) {
			if _, err := Search(context.Background(), fixture.store, test.request); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("error: %v want %v", err, store.ErrValidation)
			}
		})
	}
}

func TestSearchEnforcesExactBudget(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	exact := mustSearchBytes(t, fixture.store, published.RecordID)
	if _, err := Search(context.Background(), fixture.store, Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		ContentBudgetBytes: exact,
	}); err != nil {
		t.Fatalf("exact budget must succeed: %v", err)
	}

	result, err := Search(context.Background(), fixture.store, Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		ContentBudgetBytes: exact - 1,
	})
	if !errors.Is(err, ErrBudgetExceeded) {
		t.Fatalf("error: %v want ErrBudgetExceeded", err)
	}
	if len(result.Candidates) != 0 {
		t.Fatalf("budget failure returned partial candidates: %+v", result.Candidates)
	}
}

func TestInspectReturnsRequestedDepth(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	for _, test := range []struct {
		depth  int
		wantL2 bool
		wantL3 bool
	}{
		{depth: 1, wantL2: false, wantL3: false},
		{depth: 2, wantL2: true, wantL3: false},
		{depth: 3, wantL2: true, wantL3: true},
	} {
		t.Run(fmt.Sprintf("depth-%d", test.depth), func(t *testing.T) {
			result, err := Inspect(context.Background(), fixture.store, InspectRequest{
				RecordIDs:          []string{published.RecordID},
				Depth:              test.depth,
				ContentBudgetBytes: 1 << 20,
			})
			if err != nil {
				t.Fatal(err)
			}
			item := result.Items[0]
			if (item.L2 != nil) != test.wantL2 || (item.L3 != "") != test.wantL3 {
				t.Fatalf("depth %d: L2=%v L3=%v", test.depth, item.L2 != nil, item.L3 != "")
			}
		})
	}
}

func TestInspectRejectsInvalidDepthAndEnforcesExactBudget(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	for _, depth := range []int{0, 4, -1} {
		if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
			RecordIDs:          []string{published.RecordID},
			Depth:              depth,
			ContentBudgetBytes: 1 << 20,
		}); !errors.Is(err, store.ErrValidation) {
			t.Fatalf("depth %d: %v", depth, err)
		}
	}

	exact := mustInspectBytes(t, fixture.store, published.RecordID, 3)
	if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{published.RecordID},
		Depth:              3,
		ContentBudgetBytes: exact,
	}); err != nil {
		t.Fatalf("exact budget must succeed: %v", err)
	}
	result, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{published.RecordID},
		Depth:              3,
		ContentBudgetBytes: exact - 1,
	})
	if !errors.Is(err, ErrBudgetExceeded) {
		t.Fatalf("error: %v want ErrBudgetExceeded", err)
	}
	if len(result.Items) != 0 {
		t.Fatalf("budget failure returned partial items: %+v", result.Items)
	}
}

func TestInspectRejectsEmptyRecordIDsAndUnknownRecord(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{},
		Depth:              1,
		ContentBudgetBytes: 1 << 20,
	}); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("empty record_ids: %v want %v", err, store.ErrValidation)
	}

	if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{published.RecordID, "kr_ffffffffffffffffffffffffffffffff"},
		Depth:              1,
		ContentBudgetBytes: 1 << 20,
	}); !errors.Is(err, store.ErrNotFound) {
		t.Fatalf("unknown record id: %v want %v", err, store.ErrNotFound)
	}
}

func TestReadsFailClosedWhenBindingsAreTampered(t *testing.T) {
	for _, test := range []struct {
		name   string
		tamper func(*testing.T, *fixtureState, model.RecordRevision)
	}{
		{name: "projection l1", tamper: overwriteProjectionL1},
		{name: "record content", tamper: overwriteRecordContent},
		{name: "record payload", tamper: overwriteRecordPayload},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})
			test.tamper(t, fixture, published)

			if _, err := Search(context.Background(), fixture.store, Request{
				Zones:              []model.Zone{model.ZoneProjectKnowledge},
				ContentBudgetBytes: 1 << 20,
			}); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("search error: %v want validation failure", err)
			}
			if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
				RecordIDs:          []string{published.RecordID},
				Depth:              3,
				ContentBudgetBytes: 1 << 20,
			}); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("inspect error: %v want validation failure", err)
			}
		})
	}
}

// ---- fixture apparatus ----

var fixedTime = time.Date(2026, 8, 15, 1, 2, 3, 456789000, time.UTC)

type fixtureState struct {
	root       string
	store      *store.Store
	candidates *candidate.Service
	governance *governance.Service
}

func newFixture(t *testing.T) *fixtureState {
	t.Helper()
	root := t.TempDir()
	var counter atomic.Uint64
	opts := store.Options{
		Clock: func() time.Time { return fixedTime },
		NewID: func(prefix string) (string, error) {
			return fmt.Sprintf("%s%032x", prefix, counter.Add(1)), nil
		},
	}
	st, err := store.Init(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	return &fixtureState{root: root, store: st, candidates: candidate.New(st), governance: governance.New(st)}
}

// publish creates and publishes a fresh record of knowledgeType. project and
// architectureUnits populate Scope; tags populate L1.Tags. The record's Zone
// is taken from the type's registered factory, matching the type/zone
// contract every other package in this module already enforces.
func (f *fixtureState) publish(t *testing.T, knowledgeType model.KnowledgeType, project string, architectureUnits, tags []string) model.RecordRevision {
	t.Helper()
	scope := model.Scope{Project: project, ArchitectureUnits: architectureUnits}
	l1 := model.L1{Title: "标题", Summary: "摘要", Tags: tags}
	return f.publishWithScope(t, knowledgeType, scope, l1)
}

// publishWithL1 creates and publishes a fresh record of knowledgeType with an
// explicit L1, keeping Scope minimal so tests can isolate L1-driven filters.
func (f *fixtureState) publishWithL1(t *testing.T, knowledgeType model.KnowledgeType, l1 model.L1) model.RecordRevision {
	t.Helper()
	return f.publishWithScope(t, knowledgeType, model.Scope{Project: "themis"}, l1)
}

func (f *fixtureState) publishWithScope(t *testing.T, knowledgeType model.KnowledgeType, scope model.Scope, l1 model.L1) model.RecordRevision {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}

	created, err := f.candidates.Create(context.Background(), candidate.CreateRequest{
		Zone:                    factory.Zone,
		Scope:                   scope,
		ProposedType:            knowledgeType,
		ClassificationRationale: "test classification",
		L1:                      l1,
		L2:                      model.L2{CoreConclusion: "conclusion", Payload: json.RawMessage(`{}`)},
		ProposedBy:              "agent:proposer",
		ContentMarkdown:         buildContent(t, knowledgeType),
	})
	if err != nil {
		t.Fatal(err)
	}
	confirmed, err := f.candidates.ConfirmType(context.Background(), candidate.TypeConfirmation{
		Schema:            "themico-type-confirmation",
		CandidateID:       created.CandidateID,
		CandidateRevision: created.Revision,
		KnowledgeType:     knowledgeType,
		ConfirmedBy:       "human:reviewer",
		ConfirmedAt:       f.store.Now().Format(time.RFC3339),
		AuthorityRef:      "review/1",
	})
	if err != nil {
		t.Fatal(err)
	}
	assessment := model.SemanticAssessment{
		Schema:            "themico/semantic-assessment",
		CandidateID:       confirmed.CandidateID,
		CandidateRevision: confirmed.Revision,
		Status:            model.AssessmentPass,
		CheckerIdentity:   "agent:checker",
		CheckedAt:         f.store.Now().Format(time.RFC3339),
		Notes:             "looks good",
	}
	prepare, err := f.governance.PreparePublish(context.Background(), governance.PrepareRequest{
		CandidateID: confirmed.CandidateID,
		Assessment:  assessment,
	})
	if err != nil {
		t.Fatal(err)
	}
	approval := model.Approval{
		Schema:        "themico/approval",
		Operation:     "publish",
		PrepareID:     prepare.PrepareID,
		PrepareDigest: prepare.Digest,
		ApprovedBy:    "human:approver",
		ApprovedAt:    f.store.Now().Format(time.RFC3339),
		AuthorityRef:  "approval/1",
	}
	record, err := f.governance.Publish(context.Background(), governance.PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  approval,
	})
	if err != nil {
		t.Fatal(err)
	}
	return record
}

func buildContent(t *testing.T, knowledgeType model.KnowledgeType) []byte {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	var builder strings.Builder
	builder.WriteString("# 标题\n\n")
	for _, heading := range factory.L3Headings {
		builder.WriteString("## ")
		builder.WriteString(heading)
		builder.WriteString("\n正文内容。\n\n")
	}
	return []byte(strings.TrimRight(builder.String(), "\n") + "\n")
}

func recordIDs(candidates []Candidate) []string {
	ids := make([]string, 0, len(candidates))
	for _, item := range candidates {
		ids = append(ids, item.RecordID)
	}
	return ids
}

func sortedIDs(ids ...string) []string {
	sorted := append([]string(nil), ids...)
	sort.Strings(sorted)
	return sorted
}

func mustSearchBytes(t *testing.T, st *store.Store, recordID string) int64 {
	t.Helper()
	result, err := Search(context.Background(), st, Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		ContentBudgetBytes: 1 << 20,
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, candidate := range result.Candidates {
		if candidate.RecordID == recordID {
			data, err := canonical.Encode(candidate)
			if err != nil {
				t.Fatal(err)
			}
			return int64(len(data))
		}
	}
	t.Fatalf("record %s not found in search results", recordID)
	return 0
}

func mustInspectBytes(t *testing.T, st *store.Store, recordID string, depth int) int64 {
	t.Helper()
	result, err := Inspect(context.Background(), st, InspectRequest{
		RecordIDs:          []string{recordID},
		Depth:              depth,
		ContentBudgetBytes: 1 << 20,
	})
	if err != nil {
		t.Fatal(err)
	}
	data, err := canonical.Encode(result.Items[0])
	if err != nil {
		t.Fatal(err)
	}
	return int64(len(data))
}

// ---- tamper helpers ----

func overwriteProjectionL1(t *testing.T, fixture *fixtureState, published model.RecordRevision) {
	t.Helper()
	path := filepath.Join(fixture.store.Root(), "projections", published.RecordID, published.Revision, "l1.json")
	mustOverwrite(t, path, []byte(`{"tampered":true}`))
}

func overwriteRecordContent(t *testing.T, fixture *fixtureState, published model.RecordRevision) {
	t.Helper()
	path := filepath.Join(fixture.store.Root(), "records", published.RecordID, "revisions", published.Revision, "content.md")
	mustOverwrite(t, path, []byte("# 篡改\n\n篡改内容。\n"))
}

func overwriteRecordPayload(t *testing.T, fixture *fixtureState, published model.RecordRevision) {
	t.Helper()
	path := filepath.Join(fixture.store.Root(), "records", published.RecordID, "revisions", published.Revision, "record.json")
	mustOverwrite(t, path, []byte(`{"tampered":true}`))
}

func mustOverwrite(t *testing.T, path string, data []byte) {
	t.Helper()
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}
