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
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
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

func TestReportIssuesAreWithinClosedCodeSet(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publishedRecord(t)
	id, revision := fixture.candidateWithRelation(t, model.Relation{
		Type:           model.RelationRelatedTo,
		TargetRecordID: published.RecordID,
	})
	report := mustValidate(t, fixture.store, id, revision)
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

func (f *fixtureState) build(t *testing.T, knowledgeType model.KnowledgeType, content []byte, relations []model.Relation, sourcePaths []string) model.CandidateRevision {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	request := candidate.CreateRequest{
		Zone:                    factory.Zone,
		Scope:                   model.Scope{Project: "Themis"},
		ProposedType:            knowledgeType,
		ClassificationRationale: "test classification",
		SourcePaths:             sourcePaths,
		Relations:               relations,
		L1:                      model.L1{Title: "title", Summary: "summary"},
		L2:                      model.L2{CoreConclusion: "conclusion", Payload: json.RawMessage(`{}`)},
		ProposedBy:              "agent:test",
		ContentMarkdown:         content,
	}
	created, err := f.service.Create(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	confirmed, err := f.service.ConfirmType(context.Background(), candidate.TypeConfirmation{
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
	return confirmed
}

func (f *fixtureState) confirmedCandidate(t *testing.T, knowledgeType model.KnowledgeType, content []byte) model.CandidateRevision {
	t.Helper()
	return f.build(t, knowledgeType, content, nil, nil)
}

func (f *fixtureState) candidateWithRelation(t *testing.T, relation model.Relation) (string, string) {
	t.Helper()
	created := f.build(t, model.TypeDevelopmentExperience, experienceContent(t), []model.Relation{relation}, nil)
	return created.CandidateID, created.Revision
}

func (f *fixtureState) candidateWithSource(t *testing.T, path string, data []byte) (string, string) {
	t.Helper()
	writeSource(t, f.root, path, data)
	created := f.build(t, model.TypeDevelopmentExperience, experienceContent(t), nil, []string{path})
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
