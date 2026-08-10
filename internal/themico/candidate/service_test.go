package candidate

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestCreateBindsCandidatePayloadContentSourcesAndCurrentPointer(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source-v1"))

	created, err := fixture.service.Create(context.Background(), validCreateRequest())
	if err != nil {
		t.Fatal(err)
	}
	if !validID("cand_", created.CandidateID) || !validID("crev_", created.Revision) {
		t.Fatalf("unexpected IDs: %q %q", created.CandidateID, created.Revision)
	}
	if created.Status != model.CandidateStatusProposed || created.KnowledgeType != "" {
		t.Fatalf("unexpected type state: %+v", created)
	}
	if created.Schema != "themico/candidate-revision" || created.CreatedAt != fixedTime.Format(time.RFC3339Nano) {
		t.Fatalf("unexpected authority fields: %+v", created)
	}
	if got, want := created.Sources, []model.SourceRef{{Path: "docs/source.txt", Digest: rawDigestForTest([]byte("source-v1"))}}; !reflect.DeepEqual(got, want) {
		t.Fatalf("sources=%+v want=%+v", got, want)
	}
	if created.L1Digest != mustDigest(t, created.L1) || created.L2Digest != mustDigest(t, created.L2) || created.L3Digest != rawDigestForTest(created.ContentMarkdown) {
		t.Fatalf("invalid digests: %+v", created)
	}

	manifest, err := fixture.store.Current()
	if err != nil {
		t.Fatal(err)
	}
	if manifest.Generation != 1 || len(manifest.CurrentCandidates) != 1 {
		t.Fatalf("manifest=%+v", manifest)
	}
	pointer := manifest.CurrentCandidates[0]
	payload := readCandidatePayload(t, fixture.store.Root(), created.CandidateID, created.Revision)
	if pointer.CandidateID != created.CandidateID || pointer.Revision != created.Revision || pointer.Status != created.Status || pointer.Digest != mustDigest(t, json.RawMessage(payload)) {
		t.Fatalf("pointer=%+v created=%+v", pointer, created)
	}
	if got := readCandidateContent(t, fixture.store.Root(), created.CandidateID, created.Revision); !bytes.Equal(got, created.ContentMarkdown) {
		t.Fatalf("content=%q want=%q", got, created.ContentMarkdown)
	}

	inspected, err := fixture.service.Inspect(context.Background(), created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(inspected, created) {
		t.Fatalf("inspect=%+v created=%+v", inspected, created)
	}
	inspected.ContentMarkdown[0] = 'X'
	again, err := fixture.service.Inspect(context.Background(), created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Equal(inspected.ContentMarkdown, again.ContentMarkdown) {
		t.Fatal("Inspect returned shared content bytes")
	}
}

func TestReviseCreatesImmutableRevisionAndPreservesCandidateAuthority(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source-v1"))
	created := mustCreate(t, fixture.service, validCreateRequest())
	oldPayload := readCandidatePayload(t, fixture.store.Root(), created.CandidateID, created.Revision)
	oldContent := readCandidateContent(t, fixture.store.Root(), created.CandidateID, created.Revision)

	writeSource(t, fixture.root, "docs/source.txt", []byte("source-v2"))
	request := validReviseRequest(created)
	request.L1.Title = "Revised title"
	request.ContentMarkdown = []byte("# revised\n")
	revised, err := fixture.service.Revise(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	if revised.Revision == created.Revision || !validID("crev_", revised.Revision) {
		t.Fatalf("revision=%q", revised.Revision)
	}
	if revised.CandidateID != created.CandidateID || revised.Zone != created.Zone || !reflect.DeepEqual(revised.Scope, created.Scope) || revised.ProposedBy != created.ProposedBy || revised.ClassificationRationale != created.ClassificationRationale || revised.PublishedRecordID != created.PublishedRecordID {
		t.Fatalf("authority drifted: created=%+v revised=%+v", created, revised)
	}
	if revised.RevisedBy != request.RevisedBy || revised.CreatedAt != fixedTime.Format(time.RFC3339Nano) {
		t.Fatalf("revision metadata=%+v", revised)
	}
	if got := readCandidatePayload(t, fixture.store.Root(), created.CandidateID, created.Revision); !bytes.Equal(got, oldPayload) {
		t.Fatal("old payload changed")
	}
	if got := readCandidateContent(t, fixture.store.Root(), created.CandidateID, created.Revision); !bytes.Equal(got, oldContent) {
		t.Fatal("old content changed")
	}
	current := mustInspect(t, fixture.service, created.CandidateID)
	if current.Revision != revised.Revision || current.Sources[0].Digest != rawDigestForTest([]byte("source-v2")) {
		t.Fatalf("current=%+v", current)
	}
}

func TestReviseRejectsStaleExpectedRevisionWithoutVisibleMutation(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	created := mustCreate(t, fixture.service, validCreateRequest())
	before := mustCurrent(t, fixture.store)
	request := validReviseRequest(created)
	request.ExpectedRevision = "crev_ffffffffffffffffffffffffffffffff"

	if _, err := fixture.service.Revise(context.Background(), request); !errors.Is(err, store.ErrConflict) {
		t.Fatalf("err=%v", err)
	}
	assertCurrentUnchanged(t, fixture.store, before)
}

func TestCreateRejectsRegistryAndZoneErrorsWithoutMutation(t *testing.T) {
	tests := []struct {
		name   string
		modify func(*CreateRequest)
	}{
		{name: "unknown proposed type", modify: func(request *CreateRequest) { request.ProposedType = "unknown" }},
		{name: "type zone mismatch", modify: func(request *CreateRequest) { request.Zone = model.ZoneProjectKnowledge }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
			before := mustCurrent(t, fixture.store)
			request := validCreateRequest()
			test.modify(&request)
			if _, err := fixture.service.Create(context.Background(), request); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("err=%v", err)
			}
			assertCurrentUnchanged(t, fixture.store, before)
		})
	}
}

func TestCreateValidatesContent(t *testing.T) {
	tests := []struct {
		name    string
		content []byte
	}{
		{name: "nil", content: nil},
		{name: "empty", content: []byte{}},
		{name: "over limit", content: bytes.Repeat([]byte{'x'}, (4<<20)+1)},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
			request := validCreateRequest()
			request.ContentMarkdown = test.content
			if _, err := fixture.service.Create(context.Background(), request); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("err=%v", err)
			}
		})
	}
}

func TestCreateRejectsUnsafeOrInvalidSources(t *testing.T) {
	tests := []struct {
		name string
		path func(*testing.T, string) string
	}{
		{name: "empty", path: func(*testing.T, string) string { return "" }},
		{name: "dot", path: func(*testing.T, string) string { return "." }},
		{name: "absolute", path: func(t *testing.T, root string) string {
			path := filepath.Join(root, "outside.txt")
			if err := os.WriteFile(path, []byte("outside"), 0o600); err != nil {
				t.Fatal(err)
			}
			return path
		}},
		{name: "parent segment", path: func(*testing.T, string) string { return "docs/../docs/source.txt" }},
		{name: "backslash ambiguity", path: func(*testing.T, string) string { return `docs\source.txt` }},
		{name: "nonexistent", path: func(*testing.T, string) string { return "docs/missing.txt" }},
		{name: "directory", path: func(t *testing.T, root string) string {
			if err := os.MkdirAll(filepath.Join(root, "docs", "dir"), 0o700); err != nil {
				t.Fatal(err)
			}
			return "docs/dir"
		}},
		{name: "over limit", path: func(t *testing.T, root string) string {
			writeSource(t, root, "docs/large.bin", bytes.Repeat([]byte{'x'}, (16<<20)+1))
			return "docs/large.bin"
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
			before := mustCurrent(t, fixture.store)
			request := validCreateRequest()
			request.SourcePaths = []string{test.path(t, fixture.root)}
			if _, err := fixture.service.Create(context.Background(), request); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("err=%v", err)
			}
			assertCurrentUnchanged(t, fixture.store, before)
		})
	}
}

func TestCreateRejectsRootExternalSymlinkWhenFixtureAvailable(t *testing.T) {
	fixture := newFixture(t)
	outside := filepath.Join(t.TempDir(), "outside.txt")
	if err := os.WriteFile(outside, []byte("outside"), 0o600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(fixture.root, "escape-link")
	if err := os.Symlink(outside, link); err != nil {
		if isSymlinkUnavailable(err) {
			t.Skipf("symlink fixture unavailable: %v", err)
		}
		t.Fatal(err)
	}
	request := validCreateRequest()
	request.SourcePaths = []string{"escape-link"}
	if _, err := fixture.service.Create(context.Background(), request); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("err=%v", err)
	}
}

func TestCreateRejectsSourceThroughSymlinkedDirectoryWhenFixtureAvailable(t *testing.T) {
	fixture := newFixture(t)
	outside := t.TempDir()
	if err := os.WriteFile(filepath.Join(outside, "source.txt"), []byte("outside"), 0o600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(fixture.root, "linked-dir")
	if err := os.Symlink(outside, link); err != nil {
		if isSymlinkUnavailable(err) {
			t.Skipf("directory symlink fixture unavailable: %v", err)
		}
		t.Fatal(err)
	}
	request := validCreateRequest()
	request.SourcePaths = []string{"linked-dir/source.txt"}
	if _, err := fixture.service.Create(context.Background(), request); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("err=%v", err)
	}
}

func TestSourceDigestBindsActualBytesAndHistoricalRevisionDoesNotDrift(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source-v1"))
	created := mustCreate(t, fixture.service, validCreateRequest())
	writeSource(t, fixture.root, "docs/source.txt", []byte("source-v2"))

	persisted := decodeCandidatePayload(t, readCandidatePayload(t, fixture.store.Root(), created.CandidateID, created.Revision))
	if got, want := persisted.Sources[0].Digest, rawDigestForTest([]byte("source-v1")); got != want {
		t.Fatalf("digest=%q want=%q", got, want)
	}
}

func TestConfirmTypeRejectsInvalidConfirmationWithoutMutation(t *testing.T) {
	tests := []struct {
		name   string
		modify func(*TypeConfirmation)
	}{
		{name: "schema", modify: func(value *TypeConfirmation) { value.Schema = "wrong" }},
		{name: "confirmed by", modify: func(value *TypeConfirmation) { value.ConfirmedBy = "" }},
		{name: "authority ref", modify: func(value *TypeConfirmation) { value.AuthorityRef = "" }},
		{name: "confirmed at", modify: func(value *TypeConfirmation) { value.ConfirmedAt = "not-a-time" }},
		{name: "unknown type", modify: func(value *TypeConfirmation) { value.KnowledgeType = "unknown" }},
		{name: "zone mismatch", modify: func(value *TypeConfirmation) { value.KnowledgeType = model.TypeDesignDecision }},
		{name: "candidate stale", modify: func(value *TypeConfirmation) { value.CandidateID = "cand_ffffffffffffffffffffffffffffffff" }},
		{name: "revision stale", modify: func(value *TypeConfirmation) {
			value.CandidateRevision = "crev_ffffffffffffffffffffffffffffffff"
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
			created := mustCreate(t, fixture.service, validCreateRequest())
			before := mustCurrent(t, fixture.store)
			confirmation := validConfirmation(created)
			test.modify(&confirmation)
			_, err := fixture.service.ConfirmType(context.Background(), confirmation)
			if test.name == "candidate stale" || test.name == "revision stale" {
				if !errors.Is(err, store.ErrConflict) {
					t.Fatalf("err=%v", err)
				}
			} else if !errors.Is(err, store.ErrValidation) {
				t.Fatalf("err=%v", err)
			}
			assertCurrentUnchanged(t, fixture.store, before)
		})
	}
}

func TestConfirmTypeCreatesBoundRevisionWithoutSemanticDrift(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	created := mustCreate(t, fixture.service, validCreateRequest())
	confirmation := validConfirmation(created)
	confirmed, err := fixture.service.ConfirmType(context.Background(), confirmation)
	if err != nil {
		t.Fatal(err)
	}
	if confirmed.Revision == created.Revision || confirmed.Status != model.CandidateStatusTypeConfirmed || confirmed.ProposedType != created.ProposedType || confirmed.KnowledgeType != model.TypeDevelopmentExperience {
		t.Fatalf("confirmed=%+v", confirmed)
	}
	if !reflect.DeepEqual(confirmed.Scope, created.Scope) || !reflect.DeepEqual(confirmed.Sources, created.Sources) || !reflect.DeepEqual(confirmed.Relations, created.Relations) || !reflect.DeepEqual(confirmed.L1, created.L1) || !reflect.DeepEqual(confirmed.L2, created.L2) || !bytes.Equal(confirmed.ContentMarkdown, created.ContentMarkdown) || confirmed.L1Digest != created.L1Digest || confirmed.L2Digest != created.L2Digest || confirmed.L3Digest != created.L3Digest {
		t.Fatalf("confirmation drifted content: created=%+v confirmed=%+v", created, confirmed)
	}
	if confirmed.RevisedBy != confirmation.ConfirmedBy || confirmed.CreatedAt != fixedTime.Format(time.RFC3339Nano) || confirmed.CreatedAt == confirmation.ConfirmedAt {
		t.Fatalf("confirmation metadata=%+v", confirmed)
	}
}

func TestConfirmationMayChooseCompatibleTypeDifferentFromProposal(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	request := validCreateRequest()
	request.Zone = model.ZoneProjectKnowledge
	request.ProposedType = model.TypeDesignDecision
	created := mustCreate(t, fixture.service, request)
	confirmation := validConfirmation(created)
	confirmation.KnowledgeType = model.TypeDevelopmentStandard

	confirmed, err := fixture.service.ConfirmType(context.Background(), confirmation)
	if err != nil {
		t.Fatal(err)
	}
	if confirmed.ProposedType != model.TypeDesignDecision || confirmed.KnowledgeType != model.TypeDevelopmentStandard {
		t.Fatalf("confirmed=%+v", confirmed)
	}
}

func TestConfirmedCandidateCannotChangeType(t *testing.T) {
	fixture, created := createAndConfirmExperienceCandidate(t)
	ctx := context.Background()
	current, err := fixture.service.Inspect(ctx, created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	request := ReviseRequest{
		CandidateID:      current.CandidateID,
		ExpectedRevision: current.Revision,
		ProposedType:     model.TypeDesignDecision,
		L1:               current.L1,
		L2:               current.L2,
		SourcePaths:      sourcePaths(current.Sources),
		Relations:        current.Relations,
		ContentMarkdown:  current.ContentMarkdown,
		RevisedBy:        "agent:revision-writer",
	}
	if _, err := fixture.service.Revise(ctx, request); !errors.Is(err, ErrTypeImmutable) {
		t.Fatalf("err=%v", err)
	}
	after, err := fixture.service.Inspect(ctx, created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	if after.Revision != current.Revision || after.KnowledgeType != model.TypeDevelopmentExperience {
		t.Fatalf("candidate changed: %+v", after)
	}
}

func TestConfirmedCandidateRevisionPreservesFixedKnowledgeType(t *testing.T) {
	fixture, confirmed := createAndConfirmExperienceCandidate(t)
	request := validReviseRequest(confirmed)
	request.ContentMarkdown = []byte("# revised confirmed\n")
	revised, err := fixture.service.Revise(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	if revised.Status != model.CandidateStatusTypeConfirmed || revised.ProposedType != confirmed.ProposedType || revised.KnowledgeType != confirmed.KnowledgeType {
		t.Fatalf("revised=%+v", revised)
	}
}

func TestInspectUsesOnlyCurrentPointerAndValidatesDigests(t *testing.T) {
	t.Run("orphan directory is not current", func(t *testing.T) {
		fixture := newFixture(t)
		candidateID := "cand_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		revisionID := "crev_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
		content := []byte("# orphan\n")
		payload := validPersistedRevision(t, candidateID, revisionID, content)
		writeImmutableFixture(t, fixture.store.Root(), candidateID, revisionID, payload, content)
		if _, err := fixture.service.Inspect(context.Background(), candidateID); !errors.Is(err, ErrNotFound) {
			t.Fatalf("err=%v", err)
		}
	})

	t.Run("old revision directory cannot replace pointer", func(t *testing.T) {
		fixture := newFixture(t)
		writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
		created := mustCreate(t, fixture.service, validCreateRequest())
		request := validReviseRequest(created)
		request.ContentMarkdown = []byte("# current revision\n")
		revised := mustRevise(t, fixture.service, request)
		orphanRevision := "crev_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		orphanContent := []byte("# newer-looking orphan\n")
		orphanPayload := validPersistedRevision(t, created.CandidateID, orphanRevision, orphanContent)
		writeImmutableFixture(t, fixture.store.Root(), created.CandidateID, orphanRevision, orphanPayload, orphanContent)
		current, err := fixture.service.Inspect(context.Background(), created.CandidateID)
		if err != nil {
			t.Fatal(err)
		}
		if current.Revision != revised.Revision {
			t.Fatalf("current=%+v", current)
		}
	})

	t.Run("payload digest mismatch", func(t *testing.T) {
		fixture := newFixture(t)
		writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
		created := mustCreate(t, fixture.service, validCreateRequest())
		path := candidatePayloadFilePath(fixture.store.Root(), created.CandidateID, created.Revision)
		if err := os.WriteFile(path, []byte(`{}`), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := fixture.service.Inspect(context.Background(), created.CandidateID); !errors.Is(err, store.ErrValidation) {
			t.Fatalf("err=%v", err)
		}
	})

	t.Run("content digest mismatch", func(t *testing.T) {
		fixture := newFixture(t)
		writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
		created := mustCreate(t, fixture.service, validCreateRequest())
		path := candidateContentPath(fixture.store.Root(), created.CandidateID, created.Revision)
		if err := os.WriteFile(path, []byte("tampered"), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := fixture.service.Inspect(context.Background(), created.CandidateID); !errors.Is(err, store.ErrValidation) {
			t.Fatalf("err=%v", err)
		}
	})
}

func TestCandidateCommitPreservesRecordsProjectionsAndViews(t *testing.T) {
	fixture := newFixture(t)
	seedAggregateState(t, fixture.store)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))

	created := mustCreate(t, fixture.service, validCreateRequest())
	if created.CandidateID == "" {
		t.Fatal("candidate not created")
	}
	current := mustCurrent(t, fixture.store)
	if len(current.CurrentRecords) != 1 || len(current.Projections) != 1 {
		t.Fatalf("aggregate pointers reset: %+v", current)
	}
	views := readCurrentViews(t, fixture.store.Root(), current.Generation)
	if got, want := string(views), `{"by_project":{"Themis":["kr_11111111111111111111111111111111"]}}`; got != want {
		t.Fatalf("views=%s want=%s", got, want)
	}
}

func TestCanceledMutationDoesNotChangeCurrent(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	before := mustCurrent(t, fixture.store)
	if _, err := fixture.service.Create(ctx, validCreateRequest()); !errors.Is(err, context.Canceled) {
		t.Fatalf("err=%v", err)
	}
	assertCurrentUnchanged(t, fixture.store, before)
}

func TestNilServiceStoreAndMissingCandidateAreStableFailures(t *testing.T) {
	if _, err := New(nil).Inspect(context.Background(), "cand_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("nil store err=%v", err)
	}
	fixture := newFixture(t)
	if _, err := fixture.service.Inspect(context.Background(), "cand_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("not found err=%v", err)
	}
}

var fixedTime = time.Date(2026, 8, 4, 1, 2, 3, 456789000, time.UTC)

type fixture struct {
	root    string
	store   *store.Store
	service *Service
}

func newFixture(t *testing.T) fixture {
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
	return fixture{root: root, store: st, service: New(st)}
}

func validCreateRequest() CreateRequest {
	return CreateRequest{
		Zone:                    model.ZoneProjectExperience,
		Scope:                   model.Scope{Project: "Themis", Domains: []string{"core", "core"}, ArchitectureUnits: []string{"themico"}, Features: []string{"candidates"}},
		ProposedType:            model.TypeDevelopmentExperience,
		ClassificationRationale: "Observed reusable implementation behavior",
		SourcePaths:             []string{"docs/source.txt"},
		Relations:               []model.Relation{{Type: model.RelationRelatedTo, TargetRecordID: "kr_11111111111111111111111111111111"}},
		L1:                      model.L1{Title: "Candidate lifecycle", Summary: "Bind candidate revisions", Triggers: []string{"candidate", "candidate"}, Tags: []string{"themico"}},
		L2: model.L2{
			CoreConclusion: "Use immutable revisions",
			ApplicableWhen: []string{"creating candidates"}, NotApplicableWhen: []string{}, Impact: []string{"storage"}, EvidenceSummary: []string{"tests"}, UpgradeWhen: []string{"full detail needed"},
			Payload: json.RawMessage(`{"symptoms":["drift"],"preconditions":["local store"],"observed_facts":["revisions are immutable"],"recommended_action":["commit a new generation"],"evidence_strength":"tested","risks":["stale writers"],"stop_conditions":["conflict"]}`),
		},
		ProposedBy:      "agent:proposal-writer",
		ContentMarkdown: []byte("# Candidate lifecycle\n\nbody\n"),
	}
}

func validReviseRequest(current model.CandidateRevision) ReviseRequest {
	return ReviseRequest{
		CandidateID: current.CandidateID, ExpectedRevision: current.Revision, ProposedType: current.ProposedType,
		L1: current.L1, L2: current.L2, SourcePaths: sourcePaths(current.Sources), Relations: current.Relations,
		ContentMarkdown: append([]byte(nil), current.ContentMarkdown...), RevisedBy: "agent:revision-writer",
	}
}

func validConfirmation(current model.CandidateRevision) TypeConfirmation {
	return TypeConfirmation{
		Schema: "themico-type-confirmation", CandidateID: current.CandidateID, CandidateRevision: current.Revision,
		KnowledgeType: current.ProposedType, ConfirmedBy: "human:reviewer", ConfirmedAt: "2026-08-03T20:00:00Z", AuthorityRef: "review/42",
	}
}

func createAndConfirmExperienceCandidate(t *testing.T) (fixture, model.CandidateRevision) {
	t.Helper()
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	created := mustCreate(t, fixture.service, validCreateRequest())
	confirmed, err := fixture.service.ConfirmType(context.Background(), validConfirmation(created))
	if err != nil {
		t.Fatal(err)
	}
	return fixture, confirmed
}

func mustCreate(t *testing.T, service *Service, request CreateRequest) model.CandidateRevision {
	t.Helper()
	created, err := service.Create(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	return created
}

func mustRevise(t *testing.T, service *Service, request ReviseRequest) model.CandidateRevision {
	t.Helper()
	revised, err := service.Revise(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	return revised
}

func mustInspect(t *testing.T, service *Service, candidateID string) model.CandidateRevision {
	t.Helper()
	current, err := service.Inspect(context.Background(), candidateID)
	if err != nil {
		t.Fatal(err)
	}
	return current
}

func mustCurrent(t *testing.T, st *store.Store) model.Manifest {
	t.Helper()
	current, err := st.Current()
	if err != nil {
		t.Fatal(err)
	}
	return current
}

func assertCurrentUnchanged(t *testing.T, st *store.Store, before model.Manifest) {
	t.Helper()
	after := mustCurrent(t, st)
	if !reflect.DeepEqual(after, before) {
		t.Fatalf("current changed: before=%+v after=%+v", before, after)
	}
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

func sourcePaths(sources []model.SourceRef) []string {
	paths := make([]string, len(sources))
	for index, source := range sources {
		paths[index] = source.Path
	}
	return paths
}

func candidatePayloadFilePath(root, candidateID, revision string) string {
	return filepath.Join(root, "candidates", candidateID, "revisions", revision, "candidate.json")
}

func candidateContentPath(root, candidateID, revision string) string {
	return filepath.Join(root, "candidates", candidateID, "revisions", revision, "content.md")
}

func readCandidatePayload(t *testing.T, root, candidateID, revision string) []byte {
	t.Helper()
	data, err := os.ReadFile(candidatePayloadFilePath(root, candidateID, revision))
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func readCandidateContent(t *testing.T, root, candidateID, revision string) []byte {
	t.Helper()
	data, err := os.ReadFile(candidateContentPath(root, candidateID, revision))
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func decodeCandidatePayload(t *testing.T, data []byte) model.CandidateRevision {
	t.Helper()
	var value model.CandidateRevision
	if err := json.Unmarshal(data, &value); err != nil {
		t.Fatal(err)
	}
	return value
}

func mustDigest(t *testing.T, value any) string {
	t.Helper()
	digest, err := canonical.Digest(value)
	if err != nil {
		t.Fatal(err)
	}
	return digest
}

func rawDigestForTest(data []byte) string {
	digest := sha256.Sum256(data)
	return fmt.Sprintf("sha256:%x", digest)
}

func validID(prefix, value string) bool {
	if len(value) != len(prefix)+32 || !strings.HasPrefix(value, prefix) {
		return false
	}
	for _, char := range value[len(prefix):] {
		if (char < '0' || char > '9') && (char < 'a' || char > 'f') {
			return false
		}
	}
	return true
}

func isSymlinkUnavailable(err error) bool {
	if runtime.GOOS != "windows" {
		return false
	}
	message := strings.ToLower(err.Error())
	return strings.Contains(message, "privilege") || strings.Contains(message, "not permitted") || strings.Contains(message, "access is denied")
}

func validPersistedRevision(t *testing.T, candidateID, revision string, content []byte) []byte {
	t.Helper()
	value := model.CandidateRevision{
		Schema: "themico/candidate-revision", CandidateID: candidateID, Revision: revision, Status: model.CandidateStatusProposed,
		Zone: model.ZoneProjectExperience, Scope: model.Scope{Project: "Themis", Domains: []string{}, ArchitectureUnits: []string{}, Features: []string{}},
		ProposedType: model.TypeDevelopmentExperience, ClassificationRationale: "test", Sources: []model.SourceRef{}, Relations: []model.Relation{},
		L1:         model.L1{Title: "title", Summary: "summary", Triggers: []string{}, Tags: []string{}},
		L2:         model.L2{CoreConclusion: "conclusion", ApplicableWhen: []string{}, NotApplicableWhen: []string{}, Impact: []string{}, EvidenceSummary: []string{}, UpgradeWhen: []string{}, Payload: json.RawMessage(`{}`)},
		ProposedBy: "agent:test", CreatedAt: fixedTime.Format(time.RFC3339Nano), ContentMarkdown: content,
	}
	value.L1Digest = mustDigest(t, value.L1)
	value.L2Digest = mustDigest(t, value.L2)
	value.L3Digest = rawDigestForTest(content)
	data, err := canonical.Encode(value)
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func writeImmutableFixture(t *testing.T, root, candidateID, revision string, payload, content []byte) {
	t.Helper()
	directory := filepath.Dir(candidatePayloadFilePath(root, candidateID, revision))
	if err := os.MkdirAll(directory, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(candidatePayloadFilePath(root, candidateID, revision), payload, 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(candidateContentPath(root, candidateID, revision), content, 0o600); err != nil {
		t.Fatal(err)
	}
}

func seedAggregateState(t *testing.T, st *store.Store) {
	t.Helper()
	current := mustCurrent(t, st)
	recordID := "kr_11111111111111111111111111111111"
	revisionID := "rev_22222222222222222222222222222222"
	content := []byte("# record\n")
	l1 := model.L1{Title: "record", Summary: "summary", Triggers: []string{}, Tags: []string{}}
	l2 := model.L2{CoreConclusion: "conclusion", ApplicableWhen: []string{}, NotApplicableWhen: []string{}, Impact: []string{}, EvidenceSummary: []string{}, UpgradeWhen: []string{}, Payload: json.RawMessage(`{}`)}
	record := model.RecordRevision{
		Schema: "themico/record-revision", RecordID: recordID, Revision: revisionID, KnowledgeType: model.TypeDesignDecision, Zone: model.ZoneProjectKnowledge, Status: model.RecordStatusActive,
		Scope: model.Scope{Project: "Themis", Domains: []string{}, ArchitectureUnits: []string{}, Features: []string{}}, Sources: []model.SourceRef{}, Relations: []model.Relation{}, L1: l1, L2: l2,
		L1Digest: mustDigest(t, l1), L2Digest: mustDigest(t, l2), L3Digest: rawDigestForTest(content), AuthorizationDigest: rawDigestForTest([]byte("approval")), CreatedAt: fixedTime.Format(time.RFC3339Nano), Generation: 1,
	}
	recordPayload, err := canonical.Encode(record)
	if err != nil {
		t.Fatal(err)
	}
	projection := model.Projection{Schema: "themico/projection", RecordID: recordID, Revision: revisionID, KnowledgeType: record.KnowledgeType, Zone: record.Zone, Status: record.Status, Scope: record.Scope, L1: l1, L2: l2, L1Digest: record.L1Digest, L2Digest: record.L2Digest, L3Digest: record.L3Digest}
	projectionPayload, err := canonical.Encode(projection)
	if err != nil {
		t.Fatal(err)
	}
	views := json.RawMessage(`{"by_project":{"Themis":["kr_11111111111111111111111111111111"]}}`)
	_, err = st.Commit(context.Background(), store.CommitPlan{
		ExpectedGeneration: current.Generation,
		Writes: []store.ImmutableWrite{
			{Path: strings.Join([]string{"records", recordID, "revisions", revisionID, "record.json"}, "/"), Data: recordPayload},
			{Path: strings.Join([]string{"records", recordID, "revisions", revisionID, "content.md"}, "/"), Data: content},
			{Path: strings.Join([]string{"projections", recordID, revisionID, "l1.json"}, "/"), Data: projectionPayload},
			{Path: strings.Join([]string{"projections", recordID, revisionID, "l2.json"}, "/"), Data: projectionPayload},
		},
		Manifest: model.Manifest{
			CurrentCandidates: current.CurrentCandidates,
			CurrentRecords:    []model.RecordPointer{{RecordID: recordID, Revision: revisionID, Status: record.Status, Digest: mustDigest(t, json.RawMessage(recordPayload))}},
			Projections:       []model.ProjectionRef{{RecordID: recordID, Revision: revisionID, L1Digest: mustDigest(t, json.RawMessage(projectionPayload)), L2Digest: mustDigest(t, json.RawMessage(projectionPayload)), L3Digest: record.L3Digest}},
		},
		Views: views,
	})
	if err != nil {
		t.Fatal(err)
	}
}

func readCurrentViews(t *testing.T, root string, generation uint64) []byte {
	t.Helper()
	path := filepath.Join(root, "generations", fmt.Sprintf("gen-%020d", generation), "views.json")
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return data
}
