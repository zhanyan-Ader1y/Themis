package validate_test

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/validate"
)

// issueCodes fixes the closed set of machine-decidable contract issue codes
// this package may emit. Any code produced by validate.Candidate must be a
// member of this set.
var issueCodes = map[string]struct{}{
	"type.unregistered":                {},
	"type.zone_incompatible":           {},
	"type.not_confirmed":               {},
	"l2.payload_invalid":               {},
	"markdown.frontmatter_forbidden":   {},
	"markdown.missing_h1":              {},
	"markdown.missing_heading":         {},
	"markdown.unknown_heading":         {},
	"markdown.heading_order":           {},
	"digest.l1_mismatch":               {},
	"digest.l2_mismatch":               {},
	"digest.l3_mismatch":               {},
	"candidate.revision_stale":         {},
	"source.stale":                     {},
	"source.unreadable":                {},
	"relation.type_forbidden":          {},
	"relation.target_invalid":          {},
	"relation.target_missing":          {},
	"relation.cross_zone_not_explicit": {},
}

func TestCandidateAcceptsValidRevisionForEachType(t *testing.T) {
	for _, knowledgeType := range []model.KnowledgeType{
		model.TypeDesignDecision,
		model.TypeDevelopmentStandard,
		model.TypeDevelopmentExperience,
	} {
		t.Run(string(knowledgeType), func(t *testing.T) {
			fixture := newFixture(t)
			created := fixture.confirmedCandidate(t, knowledgeType, fullContent(t, knowledgeType, "标题"))
			report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
			if !report.OK || len(report.Issues) != 0 {
				t.Fatalf("report=%+v want OK with no issues", report)
			}
			if report.CandidateID != created.CandidateID || report.CandidateRevision != created.Revision {
				t.Fatalf("report identity=%+v want candidate=%s revision=%s", report, created.CandidateID, created.Revision)
			}
		})
	}
}

func TestCandidateRejectsMalformedL3(t *testing.T) {
	for _, test := range []struct {
		name    string
		content string
		code    string
	}{
		{
			name:    "frontmatter",
			content: "---\ntitle: x\n---\n\n# 标题\n\n## 背景与问题\n正文\n",
			code:    "markdown.frontmatter_forbidden",
		},
		{
			name:    "missing heading",
			content: string(designDecisionContentWithout(t, "约束")),
			code:    "markdown.missing_heading",
		},
		{
			name:    "unknown heading",
			content: string(designDecisionContent(t)) + "\n## 额外章节\n正文\n",
			code:    "markdown.unknown_heading",
		},
		{
			name:    "heading order",
			content: string(designDecisionContentSwapped(t, "决策", "约束")),
			code:    "markdown.heading_order",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			created := fixture.confirmedCandidate(t, model.TypeDesignDecision, []byte(test.content))
			report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
			if report.OK || !hasIssue(report, test.code) {
				t.Fatalf("report=%+v want issue %s", report, test.code)
			}
		})
	}
}

// TestCandidateFlagsMissingH1 covers markdown.missing_h1, which the table in
// TestCandidateRejectsMalformedL3 does not exercise (every fixture there keeps
// exactly one H1 while breaking something else).
func TestCandidateFlagsMissingH1(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.confirmedCandidate(t, model.TypeDesignDecision, designDecisionContentWithoutH1(t))
	report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if report.OK || !hasIssue(report, "markdown.missing_h1") {
		t.Fatalf("report=%+v want issue markdown.missing_h1", report)
	}
}

// TestCandidateFlagsInvalidTypedPayload covers l2.payload_invalid. Neither
// candidate.Service.Create nor Inspect decodes the typed L2 payload, so an
// unknown field survives all the way to validate.Candidate, where
// factory.DecodePayload is the first and only place it is rejected.
func TestCandidateFlagsInvalidTypedPayload(t *testing.T) {
	fixture := newFixture(t)
	request := fixture.baseRequest(t, model.TypeDesignDecision, designDecisionContent(t))
	request.L2.Payload = json.RawMessage(`{"x":1}`)
	created := fixture.build(t, request)
	report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if report.OK || !hasIssue(report, "l2.payload_invalid") {
		t.Fatalf("report=%+v want issue l2.payload_invalid", report)
	}
}

// TestCandidateFlagsUnconfirmedAndUnregisteredType covers both
// type.not_confirmed and type.unregistered together: skipping ConfirmType
// leaves the candidate in CandidateStatusProposed with an empty
// KnowledgeType, which Inspect returns as-is (proposed candidates are
// required to carry an empty KnowledgeType, not an error state).
func TestCandidateFlagsUnconfirmedAndUnregisteredType(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.proposedCandidate(t, model.TypeDesignDecision, designDecisionContent(t))
	report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if report.OK {
		t.Fatalf("report=%+v want not OK", report)
	}
	if !hasIssue(report, "type.not_confirmed") {
		t.Fatalf("report=%+v want issue type.not_confirmed", report)
	}
	if !hasIssue(report, "type.unregistered") {
		t.Fatalf("report=%+v want issue type.unregistered", report)
	}
	if len(report.Issues) != 2 {
		t.Fatalf("report=%+v want exactly type.not_confirmed and type.unregistered", report)
	}
}

// TestCandidateFlagsMalformedRelationTarget covers relation.target_invalid:
// a syntactically wrong target record ID must be rejected before any lookup.
func TestCandidateFlagsMalformedRelationTarget(t *testing.T) {
	fixture := newFixture(t)
	id, revision := fixture.candidateWithRelation(t, model.Relation{
		Type:           model.RelationRelatedTo,
		TargetRecordID: "kr_short",
	})
	report := mustValidate(t, fixture.store, id, revision)
	if report.OK || !hasIssue(report, "relation.target_invalid") {
		t.Fatalf("report=%+v want issue relation.target_invalid", report)
	}
}

// TestCandidateFlagsUnreadableSource covers source.unreadable: a source bound
// at creation time that later disappears from the repository must be
// reported, not silently skipped.
func TestCandidateFlagsUnreadableSource(t *testing.T) {
	fixture := newFixture(t)
	id, revision := fixture.candidateWithSource(t, "docs/vanish.txt", []byte("v1"))
	if err := os.Remove(filepath.Join(fixture.root, "docs", "vanish.txt")); err != nil {
		t.Fatal(err)
	}
	report := mustValidate(t, fixture.store, id, revision)
	if report.OK || !hasIssue(report, "source.unreadable") {
		t.Fatalf("report=%+v want issue source.unreadable", report)
	}
}

func TestCandidateChecksProvidedRelationsAndSources(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publishedRecord(t)

	for _, test := range []struct {
		name   string
		mutate func(*testing.T, *fixtureState) (string, string)
		code   string
	}{
		{
			name: "forbidden type",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationSupersedes,
					TargetRecordID: published.RecordID,
				})
			},
			code: "relation.type_forbidden",
		},
		{
			name: "missing target",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationRelatedTo,
					TargetRecordID: "kr_99999999999999999999999999999999",
				})
			},
			code: "relation.target_missing",
		},
		{
			name: "implicit cross zone",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationRelatedTo,
					TargetRecordID: published.RecordID,
				})
			},
			code: "relation.cross_zone_not_explicit",
		},
		{
			name: "source drift",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				id, revision := state.candidateWithSource(t, "docs/source.txt", []byte("v1"))
				writeSource(t, state.root, "docs/source.txt", []byte("v2"))
				return id, revision
			},
			code: "source.stale",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			id, revision := test.mutate(t, fixture)
			report := mustValidate(t, fixture.store, id, revision)
			if report.OK || !hasIssue(report, test.code) {
				t.Fatalf("report=%+v want issue %s", report, test.code)
			}
		})
	}
}

func TestCandidateRejectsStaleRevision(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.confirmedCandidate(t, model.TypeDevelopmentExperience, experienceContent(t))
	report := mustValidate(t, fixture.store, created.CandidateID, "crev_ffffffffffffffffffffffffffffffff")
	if report.OK || !hasIssue(report, "candidate.revision_stale") {
		t.Fatalf("report=%+v want issue candidate.revision_stale", report)
	}
	if len(report.Issues) != 1 {
		t.Fatalf("stale revision must short-circuit remaining checks: report=%+v", report)
	}
}

func TestCandidateProducesIdenticalReportsForIdenticalInput(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.confirmedCandidate(t, model.TypeDevelopmentExperience, experienceContent(t))

	first := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	second := mustValidate(t, fixture.store, created.CandidateID, created.Revision)

	firstBytes, err := canonical.Encode(first)
	if err != nil {
		t.Fatal(err)
	}
	secondBytes, err := canonical.Encode(second)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(firstBytes, secondBytes) {
		t.Fatalf("report is not deterministic:\n%s\n%s", firstBytes, secondBytes)
	}
	if !first.OK {
		t.Fatalf("valid candidate reported issues: %+v", first.Issues)
	}
}

// TestCandidateReportsFullOrderedIssueListAndIsDeterministic exercises a
// candidate with three simultaneous issues from three different checks
// (markdown, relation, source), each with a distinct Path, so the sort in
// candidate.go is the only thing that can produce the expected order. The
// natural append order inside Candidate is markdown -> source -> relation;
// sorting by Path flips that to markdown -> relation -> source, so this test
// fails if the sort were removed or the comparator broken.
func TestCandidateReportsFullOrderedIssueListAndIsDeterministic(t *testing.T) {
	fixture := newFixture(t)
	created := multiIssueCandidate(t, fixture)
	want := wantMultiIssueReport()

	first := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if first.OK {
		t.Fatalf("report=%+v want not OK", first)
	}
	if !reflect.DeepEqual(first.Issues, want) {
		t.Fatalf("issues=%+v want=%+v", first.Issues, want)
	}

	second := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	firstBytes, err := canonical.Encode(first)
	if err != nil {
		t.Fatal(err)
	}
	secondBytes, err := canonical.Encode(second)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(firstBytes, secondBytes) {
		t.Fatalf("report is not deterministic:\n%s\n%s", firstBytes, secondBytes)
	}
}

func TestReportIssuesAreWithinClosedCodeSet(t *testing.T) {
	fixture := newFixture(t)
	created := multiIssueCandidate(t, fixture)
	report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if len(report.Issues) < 2 {
		t.Fatalf("want a multi-issue report to make this check non-trivial, got %+v", report)
	}
	for _, item := range report.Issues {
		if _, ok := issueCodes[item.Code]; !ok {
			t.Fatalf("issue code %q is outside the closed set", item.Code)
		}
	}
}

func TestReportIssuesAreAlwaysNonNil(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.confirmedCandidate(t, model.TypeDevelopmentExperience, experienceContent(t))
	report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	if report.Issues == nil {
		t.Fatal("report.Issues must be non-nil even when empty")
	}
}

// ---- fixture apparatus ----

var fixedTime = time.Date(2026, 8, 15, 1, 2, 3, 456789000, time.UTC)

type fixtureState struct {
	root    string
	store   *store.Store
	service *candidate.Service
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
	return &fixtureState{root: root, store: st, service: candidate.New(st)}
}

// baseRequest builds a minimal, structurally valid CreateRequest for
// knowledgeType. Callers mutate the returned value (Relations, SourcePaths,
// L2.Payload, ...) before passing it to build or Create directly.
func (f *fixtureState) baseRequest(t *testing.T, knowledgeType model.KnowledgeType, content []byte) candidate.CreateRequest {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	return candidate.CreateRequest{
		Zone:                    factory.Zone,
		Scope:                   model.Scope{Project: "Themis"},
		ProposedType:            knowledgeType,
		ClassificationRationale: "test classification",
		L1:                      model.L1{Title: "title", Summary: "summary"},
		L2:                      model.L2{CoreConclusion: "conclusion", Payload: json.RawMessage(`{}`)},
		ProposedBy:              "agent:test",
		ContentMarkdown:         content,
	}
}

// build creates and type-confirms a candidate from request, using
// request.ProposedType as the confirmed knowledge type.
func (f *fixtureState) build(t *testing.T, request candidate.CreateRequest) model.CandidateRevision {
	t.Helper()
	created, err := f.service.Create(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	confirmed, err := f.service.ConfirmType(context.Background(), candidate.TypeConfirmation{
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
	return confirmed
}

// proposedCandidate creates a candidate but deliberately skips ConfirmType,
// leaving it in CandidateStatusProposed with an empty KnowledgeType.
func (f *fixtureState) proposedCandidate(t *testing.T, knowledgeType model.KnowledgeType, content []byte) model.CandidateRevision {
	t.Helper()
	created, err := f.service.Create(context.Background(), f.baseRequest(t, knowledgeType, content))
	if err != nil {
		t.Fatal(err)
	}
	return created
}

func (f *fixtureState) confirmedCandidate(t *testing.T, knowledgeType model.KnowledgeType, content []byte) model.CandidateRevision {
	t.Helper()
	return f.build(t, f.baseRequest(t, knowledgeType, content))
}

func (f *fixtureState) candidateWithRelation(t *testing.T, relation model.Relation) (string, string) {
	t.Helper()
	request := f.baseRequest(t, model.TypeDevelopmentExperience, experienceContent(t))
	request.Relations = []model.Relation{relation}
	created := f.build(t, request)
	return created.CandidateID, created.Revision
}

func (f *fixtureState) candidateWithSource(t *testing.T, path string, data []byte) (string, string) {
	t.Helper()
	writeSource(t, f.root, path, data)
	request := f.baseRequest(t, model.TypeDevelopmentExperience, experienceContent(t))
	request.SourcePaths = []string{path}
	created := f.build(t, request)
	return created.CandidateID, created.Revision
}

// publishedRecord commits a formal design_decision record directly into the
// store's current manifest so relation fixtures have a stable, cross-zone
// target that was never routed through the candidate pipeline.
func (f *fixtureState) publishedRecord(t *testing.T) model.RecordPointer {
	t.Helper()
	recordID, err := f.store.AllocateID("kr_")
	if err != nil {
		t.Fatal(err)
	}
	revisionID, err := f.store.AllocateID("rev_")
	if err != nil {
		t.Fatal(err)
	}
	content := fullContent(t, model.TypeDesignDecision, "已发布记录")
	l1 := model.L1{Title: "已发布记录", Summary: "summary"}
	l2 := model.L2{CoreConclusion: "conclusion", Payload: json.RawMessage(`{}`)}
	record := model.RecordRevision{
		Schema:              "themico/record-revision",
		RecordID:            recordID,
		Revision:            revisionID,
		KnowledgeType:       model.TypeDesignDecision,
		Zone:                model.ZoneProjectKnowledge,
		Status:              model.RecordStatusActive,
		Scope:               model.Scope{Project: "Themis"},
		L1:                  l1,
		L2:                  l2,
		L1Digest:            mustDigest(t, l1),
		L2Digest:            mustDigest(t, l2),
		L3Digest:            rawDigest(content),
		AuthorizationDigest: rawDigest([]byte("approval")),
		CreatedAt:           f.store.Now().Format(time.RFC3339Nano),
		Generation:          1,
	}
	payload, err := canonical.Encode(record)
	if err != nil {
		t.Fatal(err)
	}
	current, views, err := f.store.CurrentState()
	if err != nil {
		t.Fatal(err)
	}
	pointer := model.RecordPointer{RecordID: recordID, Revision: revisionID, Status: record.Status, Digest: rawDigest(payload)}
	manifest := model.Manifest{
		CurrentCandidates: current.CurrentCandidates,
		CurrentRecords:    append(append([]model.RecordPointer(nil), current.CurrentRecords...), pointer),
		Projections:       current.Projections,
	}
	_, err = f.store.Commit(context.Background(), store.CommitPlan{
		ExpectedGeneration: current.Generation,
		Writes: []store.ImmutableWrite{
			{Path: strings.Join([]string{"records", recordID, "revisions", revisionID, "record.json"}, "/"), Data: payload},
			{Path: strings.Join([]string{"records", recordID, "revisions", revisionID, "content.md"}, "/"), Data: content},
		},
		Manifest: manifest,
		Views:    views,
	})
	if err != nil {
		t.Fatal(err)
	}
	return pointer
}

// multiIssueCandidate builds a design_decision candidate that simultaneously
// fails three independent checks (markdown, relation, source), each with a
// distinct Issue.Path, so tests can assert a full ordered Issue list rather
// than merely "contains code X".
func multiIssueCandidate(t *testing.T, fixture *fixtureState) model.CandidateRevision {
	t.Helper()
	writeSource(t, fixture.root, "docs/multi.txt", []byte("v1"))
	request := fixture.baseRequest(t, model.TypeDesignDecision, designDecisionContentWithout(t, "约束"))
	request.SourcePaths = []string{"docs/multi.txt"}
	request.Relations = []model.Relation{{Type: model.RelationSupersedes, TargetRecordID: "kr_00000000000000000000000000000000"}}
	created := fixture.build(t, request)
	writeSource(t, fixture.root, "docs/multi.txt", []byte("v2"))
	return created
}

// wantMultiIssueReport is the exact, Path-sorted Issue list multiIssueCandidate
// must produce: "content.md#约束" < "relations[0]" < "sources[0]" by byte
// order, which differs from the natural append order inside Candidate
// (markdown, then source, then relation).
func wantMultiIssueReport() []result.Issue {
	return []result.Issue{
		{Code: "markdown.missing_heading", Path: "content.md#约束", Message: "required H2 is missing"},
		{Code: "relation.type_forbidden", Path: "relations[0]", Message: "relation type cannot be declared by a candidate"},
		{Code: "source.stale", Path: "sources[0]", Message: "source bytes changed after binding"},
	}
}

func mustValidate(t *testing.T, st *store.Store, candidateID, candidateRevision string) validate.Report {
	t.Helper()
	report, err := validate.Candidate(context.Background(), st, candidateID, candidateRevision)
	if err != nil {
		t.Fatal(err)
	}
	return report
}

func hasIssue(report validate.Report, code string) bool {
	for _, item := range report.Issues {
		if item.Code == code {
			return true
		}
	}
	return false
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

func mustDigest(t *testing.T, value any) string {
	t.Helper()
	digest, err := canonical.Digest(value)
	if err != nil {
		t.Fatal(err)
	}
	return digest
}

func rawDigest(data []byte) string {
	digest := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(digest[:])
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

func fullContent(t *testing.T, knowledgeType model.KnowledgeType, title string) []byte {
	t.Helper()
	return buildContent(title, typeHeadings(t, knowledgeType))
}

func designDecisionContent(t *testing.T) []byte {
	t.Helper()
	return fullContent(t, model.TypeDesignDecision, "设计决策标题")
}

func designDecisionContentWithout(t *testing.T, omit string) []byte {
	t.Helper()
	headings := typeHeadings(t, model.TypeDesignDecision)
	filtered := make([]string, 0, len(headings))
	for _, heading := range headings {
		if heading != omit {
			filtered = append(filtered, heading)
		}
	}
	return buildContent("设计决策标题", filtered)
}

// designDecisionContentWithoutH1 keeps every required H2 in order but omits
// the leading H1, isolating markdown.missing_h1 from every other check.
func designDecisionContentWithoutH1(t *testing.T) []byte {
	t.Helper()
	var builder strings.Builder
	for _, heading := range typeHeadings(t, model.TypeDesignDecision) {
		builder.WriteString("## ")
		builder.WriteString(heading)
		builder.WriteString("\n正文内容。\n\n")
	}
	return []byte(strings.TrimRight(builder.String(), "\n") + "\n")
}

func designDecisionContentSwapped(t *testing.T, first, second string) []byte {
	t.Helper()
	headings := append([]string(nil), typeHeadings(t, model.TypeDesignDecision)...)
	firstIndex, secondIndex := -1, -1
	for index, heading := range headings {
		switch heading {
		case first:
			firstIndex = index
		case second:
			secondIndex = index
		}
	}
	if firstIndex < 0 || secondIndex < 0 {
		t.Fatalf("headings %q and %q must both exist in design_decision", first, second)
	}
	headings[firstIndex], headings[secondIndex] = headings[secondIndex], headings[firstIndex]
	return buildContent("设计决策标题", headings)
}

func experienceContent(t *testing.T) []byte {
	t.Helper()
	return fullContent(t, model.TypeDevelopmentExperience, "开发经验标题")
}
