// Package integration drives Themico exclusively through cli.Run(ctx, args,
// stdout, stderr) int — the "themico" command surface — instead of calling
// candidate/validate/governance/query/store service APIs directly. That is
// the point of this package: it proves the command surface itself is real,
// end to end, not just the service layer underneath it. The one documented
// exception lives in interruption_test.go (see its package comment).
//
// This file (lifecycle_test.go) owns the shared CLI-driving and fixture
// helpers every other file in this package reuses, plus the end-to-end
// happy path, the type-immutability rejection, the concurrent-publish race,
// and the init/control-plane layout tests.
package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/cli"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/query"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

// Governance artifact schema constants. These mirror unexported constants in
// internal/themico/candidate and internal/themico/governance (confirmationSchema,
// assessmentSchema, approvalSchema) that this test package cannot import;
// their exact values are fixed by the task brief and by
// docs/superpowers/specs/2026-07-29-themico-design.md.
const (
	typeConfirmationSchema   = "themico-type-confirmation"
	semanticAssessmentSchema = "themico/semantic-assessment"
	approvalSchema           = "themico/approval"
	operationPublish         = "publish"
)

// ---- CLI driving helpers ----
//
// Every helper below drives Themico only through cli.Run. None of them
// import candidate/validate/governance/query as executable services — model,
// query, and candidate types are used strictly as JSON DTOs to build request
// files and to decode response envelopes.

// runCLIRaw invokes cli.Run and decodes its single JSON envelope. It never
// touches *testing.T, so it is the only CLI-driving helper safe to call from
// a background goroutine (see the concurrency test below).
func runCLIRaw(args ...string) (result.Envelope, string, error) {
	var stdout, stderr bytes.Buffer
	code := cli.Run(context.Background(), args, &stdout, &stderr)
	var envelope result.Envelope
	if err := json.Unmarshal(stdout.Bytes(), &envelope); err != nil {
		return result.Envelope{}, stderr.String(), fmt.Errorf("decode envelope for %v: %w (stdout=%s stderr=%s)", args, err, stdout.String(), stderr.String())
	}
	wantCode, err := result.ExitCode(envelope.Status)
	if err != nil {
		return envelope, stderr.String(), fmt.Errorf("envelope for %v carries unknown status %q", args, envelope.Status)
	}
	if code != wantCode {
		return envelope, stderr.String(), fmt.Errorf("exit code %d does not match status %q (want %d) for %v", code, envelope.Status, wantCode, args)
	}
	return envelope, stderr.String(), nil
}

func runCLI(t *testing.T, args ...string) result.Envelope {
	t.Helper()
	envelope, stderr, err := runCLIRaw(args...)
	if err != nil {
		t.Fatalf("%v (stderr=%s)", err, stderr)
	}
	return envelope
}

func mustRunCLI(t *testing.T, want result.Status, args ...string) result.Envelope {
	t.Helper()
	envelope := runCLI(t, args...)
	if envelope.Status != want {
		t.Fatalf("status=%s want=%s args=%v issues=%+v", envelope.Status, want, args, envelope.Issues)
	}
	return envelope
}

func runCLIStatus(t *testing.T, args ...string) result.Status {
	t.Helper()
	return runCLI(t, args...).Status
}

func decodeOutput(t *testing.T, envelope result.Envelope, dest any) {
	t.Helper()
	if err := json.Unmarshal(envelope.Output, dest); err != nil {
		t.Fatalf("decode output: %v raw=%s", err, string(envelope.Output))
	}
}

// ---- file fixture helpers ----

func writeJSONFile(t *testing.T, dir, name string, value any) string {
	t.Helper()
	data, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal %s: %v", name, err)
	}
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
	return path
}

func writeRawFile(t *testing.T, dir, name string, data []byte) string {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
	return path
}

func nowRFC3339() string {
	return time.Now().UTC().Format(time.RFC3339)
}

// ---- typed knowledge fixtures ----
//
// Zone mapping and the three types' fixed L3 headings both come from the
// model registry (model.LookupFactory / model.Factories), not from
// hardcoded copies, so these fixtures can never silently drift from the
// registry the production code actually enforces.

func zoneFor(t *testing.T, knowledgeType model.KnowledgeType) model.Zone {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	return factory.Zone
}

func typedPayload(t *testing.T, knowledgeType model.KnowledgeType) json.RawMessage {
	t.Helper()
	var payload any
	switch knowledgeType {
	case model.TypeDesignDecision:
		payload = model.DesignDecisionL2{
			AffectedUnits:  []string{"unit-a"},
			Constraints:    []string{"约束1"},
			Alternatives:   []string{"备选1"},
			Consequences:   []string{"后果1"},
			ReevaluateWhen: []string{"条件1"},
		}
	case model.TypeDevelopmentStandard:
		payload = model.DevelopmentStandardL2{
			LifecycleStages:   []string{"implementation"},
			Trigger:           []string{"触发1"},
			RequiredActions:   []string{"必须1"},
			ProhibitedActions: []string{"禁止1"},
			Verification:      []string{"验证1"},
			ExceptionPolicy:   []string{"例外1"},
		}
	case model.TypeDevelopmentExperience:
		payload = model.DevelopmentExperienceL2{
			Symptoms:          []string{"现象1"},
			Preconditions:     []string{"前置1"},
			ObservedFacts:     []string{"事实1"},
			RecommendedAction: []string{"行动1"},
			EvidenceStrength:  "strong",
			Risks:             []string{"风险1"},
			StopConditions:    []string{"停止1"},
		}
	default:
		t.Fatalf("unhandled knowledge type %s", knowledgeType)
	}
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal typed payload: %v", err)
	}
	return json.RawMessage(data)
}

func typedContent(t *testing.T, knowledgeType model.KnowledgeType, title string) []byte {
	t.Helper()
	factory, ok := model.LookupFactory(knowledgeType)
	if !ok {
		t.Fatalf("unknown knowledge type %s", knowledgeType)
	}
	var builder strings.Builder
	builder.WriteString("# " + title + "\n\n")
	for _, heading := range factory.L3Headings {
		builder.WriteString("## " + heading + "\n正文内容。\n\n")
	}
	return []byte(strings.TrimRight(builder.String(), "\n") + "\n")
}

func createCandidateRequest(t *testing.T, knowledgeType model.KnowledgeType) candidate.CreateRequest {
	t.Helper()
	return candidate.CreateRequest{
		Zone:                    zoneFor(t, knowledgeType),
		Scope:                   model.Scope{Project: "Themis", Domains: []string{"core"}},
		ProposedType:            knowledgeType,
		ClassificationRationale: "test classification",
		L1: model.L1{
			Title: "标题", Summary: "摘要",
			Triggers: []string{"trigger1"}, Tags: []string{"tag1"},
		},
		L2: model.L2{
			CoreConclusion:    "结论",
			ApplicableWhen:    []string{"适用a"},
			NotApplicableWhen: []string{"不适用b"},
			Impact:            []string{"影响c"},
			EvidenceSummary:   []string{"证据d"},
			UpgradeWhen:       []string{"升级e"},
			Payload:           typedPayload(t, knowledgeType),
		},
		ProposedBy: "agent:proposer",
	}
}

// createCandidate drives `candidate create` and returns the new candidate's
// (candidate_id, candidate_revision).
func createCandidate(t *testing.T, repository string, knowledgeType model.KnowledgeType) (string, string) {
	t.Helper()
	dir := t.TempDir()
	inputPath := writeJSONFile(t, dir, "candidate.json", createCandidateRequest(t, knowledgeType))
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, knowledgeType, "标题"))
	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "create", "--root", repository, "--input", inputPath, "--content", contentPath)
	var revision model.CandidateRevision
	decodeOutput(t, envelope, &revision)
	return revision.CandidateID, revision.Revision
}

// confirmType drives `candidate confirm-type` and returns the resulting
// candidate_revision.
func confirmType(t *testing.T, repository, candidateID, candidateRevision string, knowledgeType model.KnowledgeType) string {
	t.Helper()
	dir := t.TempDir()
	confirmation := candidate.TypeConfirmation{
		Schema:            typeConfirmationSchema,
		CandidateID:       candidateID,
		CandidateRevision: candidateRevision,
		KnowledgeType:     knowledgeType,
		ConfirmedBy:       "human:reviewer",
		ConfirmedAt:       nowRFC3339(),
		AuthorityRef:      "review/1",
	}
	path := writeJSONFile(t, dir, "confirmation.json", confirmation)
	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "confirm-type", "--root", repository, "--confirmation", path)
	var revision model.CandidateRevision
	decodeOutput(t, envelope, &revision)
	return revision.Revision
}

// preparePublish drives `prepare publish` with a passing assessment bound to
// candidateID/candidateRevision and returns the frozen model.Prepare.
func preparePublish(t *testing.T, repository, candidateID, candidateRevision string) model.Prepare {
	t.Helper()
	dir := t.TempDir()
	assessment := model.SemanticAssessment{
		Schema:            semanticAssessmentSchema,
		CandidateID:       candidateID,
		CandidateRevision: candidateRevision,
		Status:            model.AssessmentPass,
		CheckerIdentity:   "agent:checker", // must differ from candidate's proposed_by ("agent:proposer")
		CheckedAt:         nowRFC3339(),
		Notes:             "looks good",
	}
	path := writeJSONFile(t, dir, "assessment.json", assessment)
	envelope := mustRunCLI(t, result.StatusSucceeded, "prepare", "publish", "--root", repository, "--candidate", candidateID, "--assessment", path)
	var prepare model.Prepare
	decodeOutput(t, envelope, &prepare)
	return prepare
}

// approvalFor builds one Approval bound exactly to prepare.
func approvalFor(prepare model.Prepare) model.Approval {
	return model.Approval{
		Schema:        approvalSchema,
		Operation:     operationPublish,
		PrepareID:     prepare.PrepareID,
		PrepareDigest: prepare.Digest,
		ApprovedBy:    "human:approver",
		ApprovedAt:    nowRFC3339(),
		AuthorityRef:  "approval/1",
	}
}

// publish drives `publish` for prepare and returns the committed record.
func publish(t *testing.T, repository string, prepare model.Prepare) model.RecordRevision {
	t.Helper()
	dir := t.TempDir()
	path := writeJSONFile(t, dir, "approval.json", approvalFor(prepare))
	envelope := mustRunCLI(t, result.StatusSucceeded, "publish", "--root", repository, "--prepare", prepare.PrepareID, "--approval", path)
	var record model.RecordRevision
	decodeOutput(t, envelope, &record)
	return record
}

// prepareReadyCandidate drives create -> confirm-type -> prepare publish for
// a fresh candidate of knowledgeType, all through the CLI, and returns the
// frozen Prepare ready for `publish`.
func prepareReadyCandidate(t *testing.T, repository string, knowledgeType model.KnowledgeType) model.Prepare {
	t.Helper()
	candidateID, revision := createCandidate(t, repository, knowledgeType)
	confirmed := confirmType(t, repository, candidateID, revision, knowledgeType)
	return preparePublish(t, repository, candidateID, confirmed)
}

// queryZone drives `query` scoped to one zone with a generous byte budget
// and returns the matching L1 candidates.
func queryZone(t *testing.T, repository string, zone model.Zone) query.Result {
	t.Helper()
	dir := t.TempDir()
	request := query.Request{Zones: []model.Zone{zone}, ContentBudgetBytes: 1 << 20}
	path := writeJSONFile(t, dir, "query.json", request)
	envelope := mustRunCLI(t, result.StatusSucceeded, "query", "--root", repository, "--request", path)
	var res query.Result
	decodeOutput(t, envelope, &res)
	return res
}

func containsRecord(candidates []query.Candidate, recordID string) bool {
	for _, c := range candidates {
		if c.RecordID == recordID {
			return true
		}
	}
	return false
}

// inspectRecord drives `inspect` for exactly one record ID at depth and
// returns its single Item.
func inspectRecord(t *testing.T, repository, recordID string, depth int) query.Item {
	t.Helper()
	dir := t.TempDir()
	request := query.InspectRequest{RecordIDs: []string{recordID}, Depth: depth, ContentBudgetBytes: 1 << 20}
	path := writeJSONFile(t, dir, "inspect.json", request)
	envelope := mustRunCLI(t, result.StatusSucceeded, "inspect", "--root", repository, "--request", path)
	var res query.InspectResult
	decodeOutput(t, envelope, &res)
	if len(res.Items) != 1 {
		t.Fatalf("inspect returned %d items, want 1", len(res.Items))
	}
	return res.Items[0]
}

// ---- step 1: full three-type happy path ----

func TestPublishAndReadEachKnowledgeType(t *testing.T) {
	for _, knowledgeType := range []model.KnowledgeType{
		model.TypeDesignDecision,
		model.TypeDevelopmentStandard,
		model.TypeDevelopmentExperience,
	} {
		t.Run(string(knowledgeType), func(t *testing.T) {
			repository := t.TempDir()
			mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

			candidateID, candidateRevision := createCandidate(t, repository, knowledgeType)
			confirmedRevision := confirmType(t, repository, candidateID, candidateRevision, knowledgeType)
			mustRunCLI(t, result.StatusSucceeded, "validate", "--root", repository,
				"--candidate", candidateID, "--revision", confirmedRevision)

			prepare := preparePublish(t, repository, candidateID, confirmedRevision)
			record := publish(t, repository, prepare)

			l1 := queryZone(t, repository, zoneFor(t, knowledgeType))
			if !containsRecord(l1.Candidates, record.RecordID) {
				t.Fatalf("query did not return %s among %+v", record.RecordID, l1.Candidates)
			}
			for depth := 1; depth <= 3; depth++ {
				item := inspectRecord(t, repository, record.RecordID, depth)
				if item.RecordID != record.RecordID || item.Type != knowledgeType {
					t.Fatalf("depth %d item=%+v want record %s type %s", depth, item, record.RecordID, knowledgeType)
				}
				if depth >= 2 && item.L2 == nil {
					t.Fatalf("depth %d missing L2", depth)
				}
				if depth < 2 && item.L2 != nil {
					t.Fatalf("depth %d unexpectedly carried L2", depth)
				}
				if depth >= 3 && item.L3 == "" {
					t.Fatalf("depth %d missing L3", depth)
				}
				if depth < 3 && item.L3 != "" {
					t.Fatalf("depth %d unexpectedly carried L3", depth)
				}
			}

			// The candidate pointer itself must now show published, bound to
			// this exact record.
			envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "inspect", "--root", repository, "--id", candidateID)
			var finalCandidate model.CandidateRevision
			decodeOutput(t, envelope, &finalCandidate)
			if finalCandidate.Status != model.CandidateStatusPublished || finalCandidate.PublishedRecordID != record.RecordID {
				t.Fatalf("candidate not marked published against %s: %+v", record.RecordID, finalCandidate)
			}
		})
	}
}

// ---- step 2: type immutability after confirmation ----

// reviseInput mirrors the CLI's own unexported cli.reviseInput DTO shape
// (internal/themico/cli/commands.go) so this test can build a --input file
// with the exact field names the CLI decodes, without importing an
// unexported type.
type reviseInput struct {
	CandidateID      string              `json:"candidate_id"`
	ExpectedRevision string              `json:"expected_revision"`
	ProposedType     model.KnowledgeType `json:"proposed_type"`
	L1               model.L1            `json:"l1"`
	L2               model.L2            `json:"l2"`
	SourcePaths      []string            `json:"source_paths"`
	Relations        []model.Relation    `json:"relations"`
	RevisedBy        string              `json:"revised_by"`
}

func TestCandidateReviseRejectsTypeChangeAfterConfirmation(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	candidateID, candidateRevision := createCandidate(t, repository, model.TypeDesignDecision)
	confirmedRevision := confirmType(t, repository, candidateID, candidateRevision, model.TypeDesignDecision)

	dir := t.TempDir()
	// development_standard shares design_decision's zone (project_knowledge),
	// so this exercises the type-immutability gate specifically, not a
	// zone-mismatch rejection.
	revise := reviseInput{
		CandidateID:      candidateID,
		ExpectedRevision: confirmedRevision,
		ProposedType:     model.TypeDevelopmentStandard,
		L1:               model.L1{Title: "改型标题", Summary: "改型摘要"},
		L2:               model.L2{CoreConclusion: "改型结论", Payload: typedPayload(t, model.TypeDevelopmentStandard)},
		RevisedBy:        "human:reviewer",
	}
	inputPath := writeJSONFile(t, dir, "revise.json", revise)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "revise", "--root", repository,
		"--input", inputPath, "--content", contentPath)

	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "inspect", "--root", repository, "--id", candidateID)
	var current model.CandidateRevision
	decodeOutput(t, envelope, &current)
	if current.KnowledgeType != model.TypeDesignDecision {
		t.Fatalf("candidate pointer knowledge_type changed to %s after rejected revise", current.KnowledgeType)
	}
	if current.Revision != confirmedRevision {
		t.Fatalf("candidate pointer revision changed to %s after rejected revise (want unchanged %s)", current.Revision, confirmedRevision)
	}
}

// ---- step 3: concurrent publish, exactly one winner ----

type publishAttempt struct {
	status result.Status
	record model.RecordRevision
	err    error
}

// TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting proves that when
// two prepares race to publish concurrently, exactly one commits and the
// other fails closed with conflict, never overwriting the winner's current
// state. The two prepares are created sequentially (each one's own setup
// commits advance the generation), so their ExpectedGeneration values are
// necessarily different — see task-11-brief.md's own ruling 1: the prepare
// whose ExpectedGeneration matches the generation actually current at
// publish time succeeds and advances the generation again; the other's
// ExpectedGeneration is then already stale and can only conflict. The two
// publish calls are still dispatched from real goroutines released by a
// shared start signal, so this exercises the store's actual concurrent
// commit path (the rename-based generation lock), not just a sequential
// call order.
func TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	firstPrepare := prepareReadyCandidate(t, repository, model.TypeDesignDecision)
	secondPrepare := prepareReadyCandidate(t, repository, model.TypeDesignDecision)
	if firstPrepare.ExpectedGeneration == secondPrepare.ExpectedGeneration {
		t.Fatalf("test setup expected distinct expected generations, both are %d", firstPrepare.ExpectedGeneration)
	}

	resultsCh := make(chan publishAttempt, 2)
	start := make(chan struct{})
	var waiter sync.WaitGroup
	for _, prepare := range []model.Prepare{firstPrepare, secondPrepare} {
		waiter.Add(1)
		go func(p model.Prepare) {
			defer waiter.Done()
			<-start
			resultsCh <- attemptPublish(repository, p)
		}(prepare)
	}
	close(start)
	waiter.Wait()
	close(resultsCh)

	var succeeded, conflicted int
	var winner model.RecordRevision
	for attempt := range resultsCh {
		if attempt.err != nil {
			t.Fatalf("publish attempt failed: %v", attempt.err)
		}
		switch attempt.status {
		case result.StatusSucceeded:
			succeeded++
			winner = attempt.record
		case result.StatusConflict:
			conflicted++
		default:
			t.Fatalf("unexpected status %s", attempt.status)
		}
	}
	if succeeded != 1 || conflicted != 1 {
		t.Fatalf("succeeded=%d conflicted=%d want exactly one each", succeeded, conflicted)
	}

	// The failed side must not have overwritten the winner: exactly the
	// winner's record is current.
	current := queryZone(t, repository, model.ZoneProjectKnowledge)
	if len(current.Candidates) != 1 {
		t.Fatalf("current records=%d want exactly the winner's record: %+v", len(current.Candidates), current.Candidates)
	}
	if current.Candidates[0].RecordID != winner.RecordID {
		t.Fatalf("current record=%s want winner %s", current.Candidates[0].RecordID, winner.RecordID)
	}
}

// attemptPublish drives `publish` for one prepare without ever touching
// *testing.T, so it is safe to call from a background goroutine (see
// TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting above).
func attemptPublish(repository string, prepare model.Prepare) publishAttempt {
	dir, err := os.MkdirTemp("", "themico-approval-*")
	if err != nil {
		return publishAttempt{err: err}
	}
	defer os.RemoveAll(dir)
	data, err := json.Marshal(approvalFor(prepare))
	if err != nil {
		return publishAttempt{err: err}
	}
	path := filepath.Join(dir, "approval.json")
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return publishAttempt{err: err}
	}
	envelope, _, err := runCLIRaw("publish", "--root", repository, "--prepare", prepare.PrepareID, "--approval", path)
	if err != nil {
		return publishAttempt{err: err}
	}
	attempt := publishAttempt{status: envelope.Status}
	if envelope.Status == result.StatusSucceeded {
		if err := json.Unmarshal(envelope.Output, &attempt.record); err != nil {
			return publishAttempt{err: err}
		}
	}
	return attempt
}

// ---- step 6: init layout and control-plane independence ----

func TestInitLayoutAndControlPlane(t *testing.T) {
	repository := t.TempDir()

	// Pre-install a control plane before init, proving init neither
	// requires nor takes ownership of an existing core/.
	corePath := filepath.Join(repository, ".themico", "core", "references")
	if err := os.MkdirAll(corePath, 0o700); err != nil {
		t.Fatal(err)
	}
	preinstalled := []byte("# pre-installed reference\n")
	referenceFile := filepath.Join(corePath, "operation-contract.md")
	if err := os.WriteFile(referenceFile, preinstalled, 0o600); err != nil {
		t.Fatal(err)
	}

	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	if info, err := os.Stat(filepath.Join(repository, ".themico", "core")); err != nil || !info.IsDir() {
		t.Fatalf(".themico/core missing after init: %v", err)
	}
	workspaceRoot := filepath.Join(repository, ".themico", "workspace")
	if info, err := os.Stat(workspaceRoot); err != nil || !info.IsDir() {
		t.Fatalf(".themico/workspace missing after init: %v", err)
	}
	for _, dir := range []string{"candidates", "records", "projections", "preparations", "assessments", "approvals", "generations"} {
		if info, err := os.Stat(filepath.Join(workspaceRoot, dir)); err != nil || !info.IsDir() {
			t.Fatalf("workspace missing directory %s: %v", dir, err)
		}
	}

	// Pre-installed control-plane bytes are unchanged.
	got, err := os.ReadFile(referenceFile)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, preinstalled) {
		t.Fatalf("init modified pre-installed control-plane bytes: got %q want %q", got, preinstalled)
	}

	// A subsequent store-write command (candidate create, which commits a
	// new generation) must only ever land under workspace/: core/ must stay
	// exactly the single pre-installed file.
	createCandidate(t, repository, model.TypeDesignDecision)
	seenExtra := false
	if err := filepath.WalkDir(corePath, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() {
			return nil
		}
		if path != referenceFile {
			seenExtra = true
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	if seenExtra {
		t.Fatalf("a store write landed under core/ instead of workspace/")
	}

	mustRunCLI(t, result.StatusPreconditionFailed, "init", "--root", repository)
}
