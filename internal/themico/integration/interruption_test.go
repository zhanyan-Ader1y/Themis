// Every other file in this package drives Themico exclusively through
// cli.Run (see lifecycle_test.go's package comment). This file is the one
// documented exception task-11-brief.md's ruling 2 grants, and only for the
// "before rename" scenario below: cli.Run never exposes
// store.Options.BeforeGenerationRename, and there is no CLI flag, env var,
// or command that can inject a fault immediately before the generation-
// visible rename — the only place that hook can be wired in is store.Init's
// own Options argument. So TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged
// drives internal/themico/{store,candidate,governance} directly to
// *construct* that one interrupted commit, then verifies every observable
// outcome (current generation, query results, inspect results, candidate
// and record pointers) exclusively through cli.Run against the same --root,
// exactly like every other test in this package.
//
// The other scenario below, TestPublishInterruptedDuringPayloadWriteLeavesOrphanInvisible,
// needs no such exception: it reaches the same class of outcome (a
// mid-commit interruption that leaves orphan immutable payloads on disk
// while the generation never advances) by planting one colliding file at a
// path the CLI's own "prepare publish" output already told it about, using
// store.WorkspaceRoot purely as a path helper. Every Themico operation in
// that test — init, candidate create, confirm-type, prepare publish,
// publish — runs through cli.Run.
package integration

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/governance"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/query"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

// TestPublishInterruptedDuringPayloadWriteLeavesOrphanInvisible interrupts a
// commit mid-way through store.Commit's immutable-write loop (see
// internal/themico/store/generation.go): it plants a file at the exact path
// Publish's *second* write (records/.../content.md) will target, so
// Publish's first write (record.json) lands as a genuine orphan on disk
// before the second write fails closed with "immutable target exists"
// (store.ErrPrecondition) — well before the generation directory is even
// opened. This is a real interruption store.Commit's own immutable-write
// contract already guarantees, reached by planting one file: no direct
// store/governance API call is needed, so this scenario stays 100%
// CLI-driven.
func TestPublishInterruptedDuringPayloadWriteLeavesOrphanInvisible(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	prepare := prepareReadyCandidate(t, repository, model.TypeDesignDecision)

	collisionPath := filepath.Join(store.WorkspaceRoot(repository), "records", prepare.RecordID, "revisions", prepare.RecordRevision, "content.md")
	if err := os.MkdirAll(filepath.Dir(collisionPath), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(collisionPath, []byte("pre-existing collision, not written by Themico"), 0o600); err != nil {
		t.Fatal(err)
	}

	before := queryZone(t, repository, model.ZoneProjectKnowledge)

	dir := t.TempDir()
	approvalPath := writeJSONFile(t, dir, "approval.json", approvalFor(prepare))
	mustRunCLI(t, result.StatusPreconditionFailed, "publish", "--root", repository,
		"--prepare", prepare.PrepareID, "--approval", approvalPath)

	after := queryZone(t, repository, model.ZoneProjectKnowledge)
	if after.Generation != before.Generation {
		t.Fatalf("interrupted publish advanced generation %d -> %d", before.Generation, after.Generation)
	}
	if len(after.Candidates) != len(before.Candidates) {
		t.Fatalf("interrupted publish changed query candidates: before=%+v after=%+v", before.Candidates, after.Candidates)
	}
	if containsRecord(after.Candidates, prepare.RecordID) {
		t.Fatalf("interrupted publish's record leaked into query: %+v", after.Candidates)
	}

	inspectDir := t.TempDir()
	inspectPath := writeJSONFile(t, inspectDir, "inspect.json", query.InspectRequest{
		RecordIDs: []string{prepare.RecordID}, Depth: 1, ContentBudgetBytes: 4096,
	})
	mustRunCLI(t, result.StatusNotFound, "inspect", "--root", repository, "--request", inspectPath)

	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "inspect", "--root", repository, "--id", prepare.CandidateID)
	var candidateAfter model.CandidateRevision
	decodeOutput(t, envelope, &candidateAfter)
	if candidateAfter.Status != model.CandidateStatusTypeConfirmed || candidateAfter.PublishedRecordID != "" {
		t.Fatalf("interrupted publish still marked the candidate published: %+v", candidateAfter)
	}

	// Prove the orphan genuinely exists on disk: it is real, unreferenced,
	// unreachable bytes, not merely "absent". Every read path above already
	// proved no current pointer or projection ever references it.
	orphanRecordPath := filepath.Join(store.WorkspaceRoot(repository), "records", prepare.RecordID, "revisions", prepare.RecordRevision, "record.json")
	if _, err := os.Stat(orphanRecordPath); err != nil {
		t.Fatalf("expected orphan record.json to exist on disk: %v", err)
	}
}

// TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged is the one
// documented CLI exception in this package; see the package comment above
// for why.
func TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged(t *testing.T) {
	root := t.TempDir()

	var counter atomic.Uint64
	var faultArmed atomic.Bool
	opts := store.Options{
		Clock: func() time.Time { return time.Date(2026, 8, 17, 1, 2, 3, 0, time.UTC) },
		NewID: func(prefix string) (string, error) {
			return fmt.Sprintf("%s%032x", prefix, counter.Add(1)), nil
		},
		BeforeGenerationRename: func() error {
			if faultArmed.Load() {
				return errors.New("injected pre-rename fault")
			}
			return nil
		},
	}
	st, err := store.Init(root, opts)
	if err != nil {
		t.Fatal(err)
	}

	candidateService := candidate.New(st)
	governanceService := governance.New(st)
	ctx := context.Background()

	created, err := candidateService.Create(ctx, candidate.CreateRequest{
		Zone:                    model.ZoneProjectKnowledge,
		Scope:                   model.Scope{Project: "Themis"},
		ProposedType:            model.TypeDesignDecision,
		ClassificationRationale: "test classification",
		L1:                      model.L1{Title: "标题", Summary: "摘要"},
		L2:                      model.L2{CoreConclusion: "结论", Payload: typedPayload(t, model.TypeDesignDecision)},
		ProposedBy:              "agent:proposer",
		ContentMarkdown:         typedContent(t, model.TypeDesignDecision, "标题"),
	})
	if err != nil {
		t.Fatal(err)
	}
	confirmed, err := candidateService.ConfirmType(ctx, candidate.TypeConfirmation{
		Schema:            typeConfirmationSchema,
		CandidateID:       created.CandidateID,
		CandidateRevision: created.Revision,
		KnowledgeType:     model.TypeDesignDecision,
		ConfirmedBy:       "human:reviewer",
		ConfirmedAt:       nowRFC3339(),
		AuthorityRef:      "review/1",
	})
	if err != nil {
		t.Fatal(err)
	}
	prepare, err := governanceService.PreparePublish(ctx, governance.PrepareRequest{
		CandidateID: confirmed.CandidateID,
		Assessment: model.SemanticAssessment{
			Schema:            semanticAssessmentSchema,
			CandidateID:       confirmed.CandidateID,
			CandidateRevision: confirmed.Revision,
			Status:            model.AssessmentPass,
			CheckerIdentity:   "agent:checker",
			CheckedAt:         nowRFC3339(),
			Notes:             "looks good",
		},
	})
	if err != nil {
		t.Fatal(err)
	}

	before := queryZone(t, root, model.ZoneProjectKnowledge)

	// Setup (create/confirm-type/prepare) must not observe the fault; it is
	// armed only for the Publish call under test.
	faultArmed.Store(true)
	if _, err := governanceService.Publish(ctx, governance.PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  approvalFor(prepare),
	}); err == nil {
		t.Fatal("interrupted publish unexpectedly succeeded")
	}

	after := queryZone(t, root, model.ZoneProjectKnowledge)
	if after.Generation != before.Generation {
		t.Fatalf("interrupted publish advanced generation %d -> %d", before.Generation, after.Generation)
	}
	if len(after.Candidates) != 0 {
		t.Fatalf("interrupted publish exposed a record via query: %+v", after.Candidates)
	}

	inspectDir := t.TempDir()
	inspectPath := writeJSONFile(t, inspectDir, "inspect.json", query.InspectRequest{
		RecordIDs: []string{prepare.RecordID}, Depth: 1, ContentBudgetBytes: 4096,
	})
	mustRunCLI(t, result.StatusNotFound, "inspect", "--root", root, "--request", inspectPath)

	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "inspect", "--root", root, "--id", confirmed.CandidateID)
	var candidateAfter model.CandidateRevision
	decodeOutput(t, envelope, &candidateAfter)
	if candidateAfter.Status != model.CandidateStatusTypeConfirmed || candidateAfter.Revision != confirmed.Revision || candidateAfter.PublishedRecordID != "" {
		t.Fatalf("interrupted publish changed the candidate pointer: %+v", candidateAfter)
	}

	// The four frozen writes (record.json, content.md, l1.json, l2.json) are
	// real orphans on disk: written unconditionally before the generation
	// staging directory was ever touched, and never referenced by any
	// current pointer above.
	for _, orphan := range []string{
		filepath.Join(store.WorkspaceRoot(root), "records", prepare.RecordID, "revisions", prepare.RecordRevision, "record.json"),
		filepath.Join(store.WorkspaceRoot(root), "records", prepare.RecordID, "revisions", prepare.RecordRevision, "content.md"),
		filepath.Join(store.WorkspaceRoot(root), "projections", prepare.RecordID, prepare.RecordRevision, "l1.json"),
		filepath.Join(store.WorkspaceRoot(root), "projections", prepare.RecordID, prepare.RecordRevision, "l2.json"),
	} {
		if _, err := os.Stat(orphan); err != nil {
			t.Fatalf("expected orphan write to exist on disk: %s: %v", orphan, err)
		}
	}

	// The generation staging directory store.Commit builds before the
	// rename is always removed via defer on any failure path, so no stray
	// ".staging-*" entry should remain under generations/.
	generationsDir := filepath.Join(store.WorkspaceRoot(root), "generations")
	entries, err := os.ReadDir(generationsDir)
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if entry.Name() != "gen-00000000000000000000" && entry.Name() != "gen-00000000000000000001" && entry.Name() != "gen-00000000000000000002" && entry.Name() != "gen-00000000000000000003" {
			t.Fatalf("unexpected leftover generations entry after interrupted publish: %s", entry.Name())
		}
	}
}
