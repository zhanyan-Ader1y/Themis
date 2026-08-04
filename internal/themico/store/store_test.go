package store_test

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestInitMakesGenerationZeroVisibleAndOpenPreservesIdentity(t *testing.T) {
	root := t.TempDir()
	opts := testOptions()

	initialized, err := store.Init(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	if initialized.Root() != filepath.Join(root, ".themico") {
		t.Fatalf("root: %q", initialized.Root())
	}
	manifest, err := initialized.Current()
	if err != nil {
		t.Fatal(err)
	}
	assertGenesis(t, manifest)

	storeBytes, err := os.ReadFile(filepath.Join(root, ".themico", "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	wantStore := `{"created_at":"2026-08-03T12:34:56.123456789Z","genesis_manifest_digest":"` + manifest.Digest + `","schema":"themico/store","store_id":"op_00000000000000000000000000000001"}`
	if string(storeBytes) != wantStore {
		t.Fatalf("store.json:\n got: %s\nwant: %s", storeBytes, wantStore)
	}

	reopened, err := store.Open(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	reopenedManifest, err := reopened.Current()
	if err != nil {
		t.Fatal(err)
	}
	if reopenedManifest.Digest != manifest.Digest {
		t.Fatalf("reopened digest: got %s want %s", reopenedManifest.Digest, manifest.Digest)
	}
}

func TestInitRejectsInvalidInjectedStoreID(t *testing.T) {
	root := t.TempDir()
	opts := testOptions()
	opts.NewID = func(string) (string, error) { return "op_NOT_HEX", nil }
	if _, err := store.Init(root, opts); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("error: %v", err)
	}
	if _, err := os.Lstat(filepath.Join(root, ".themico")); !os.IsNotExist(err) {
		t.Fatalf("store unexpectedly exists: %v", err)
	}
}

func TestInitExistingStoreFailsWithoutChangingBytes(t *testing.T) {
	root := t.TempDir()
	storeRoot := filepath.Join(root, ".themico")
	if err := os.Mkdir(storeRoot, 0o755); err != nil {
		t.Fatal(err)
	}
	sentinel := filepath.Join(storeRoot, "sentinel")
	if err := os.WriteFile(sentinel, []byte("unchanged"), 0o600); err != nil {
		t.Fatal(err)
	}

	_, err := store.Init(root, testOptions())
	if !errors.Is(err, store.ErrPrecondition) {
		t.Fatalf("error: %v", err)
	}
	got, readErr := os.ReadFile(sentinel)
	if readErr != nil {
		t.Fatal(readErr)
	}
	if string(got) != "unchanged" {
		t.Fatalf("existing bytes changed: %q", got)
	}
}

func TestCommitRejectsUnsafeImmutablePaths(t *testing.T) {
	tests := []string{
		"",
		"../escape.json",
		"records/../escape.json",
		"./record.json",
		"records\\escape.json",
		"/absolute.json",
		"C:/absolute.json",
		"generations/.staging-attacker/manifest.json",
		"generations/gen-00000000000000000001/manifest.json",
		"records",
		"records/kr/revisions/rev/unexpected.json",
		"projections/kr/rev/content.md",
		"preparations/prep/other.json",
	}

	for _, path := range tests {
		t.Run(fmt.Sprintf("%q", path), func(t *testing.T) {
			root := t.TempDir()
			s := mustInit(t, root, testOptions())
			_, err := s.Commit(context.Background(), commitPlan(0, path, []byte("payload")))
			if !errors.Is(err, store.ErrValidation) {
				t.Fatalf("error: %v", err)
			}
		})
	}
}

func TestCommitRejectsSymlinkEscapeWhenSupported(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("standard-library symlink checks do not cover Windows junction/reparse points")
	}
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	outside := t.TempDir()
	link := filepath.Join(root, ".themico", "records", "escape")
	if err := os.Symlink(outside, link); err != nil {
		if runtime.GOOS == "windows" {
			t.Skipf("symlink unavailable: %v", err)
		}
		t.Fatal(err)
	}

	_, err := s.Commit(context.Background(), commitPlan(0, "records/escape/payload.json", []byte("payload")))
	if !errors.Is(err, store.ErrValidation) {
		t.Fatalf("error: %v", err)
	}
	if _, statErr := os.Stat(filepath.Join(outside, "payload.json")); !os.IsNotExist(statErr) {
		t.Fatalf("outside payload exists or stat failed unexpectedly: %v", statErr)
	}
}

func TestCommitRejectsSymlinkSwapBeforeImmutableCreateWhenSupported(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("standard-library symlink checks do not cover Windows junction/reparse points")
	}
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	outside := t.TempDir()
	parent := filepath.Join(root, ".themico", "records", "race")
	mustMkdirAll(t, parent)
	path := "records/race/payload.json"
	plan := commitPlan(0, path, []byte("payload"))

	if err := os.Remove(parent); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, parent); err != nil {
		if runtime.GOOS == "windows" {
			t.Skipf("symlink unavailable: %v", err)
		}
		t.Fatal(err)
	}
	_, err := s.Commit(context.Background(), plan)
	if !errors.Is(err, store.ErrValidation) {
		t.Fatalf("error: %v", err)
	}
	if _, statErr := os.Stat(filepath.Join(outside, "payload.json")); !os.IsNotExist(statErr) {
		t.Fatalf("outside payload exists or stat failed unexpectedly: %v", statErr)
	}
}

func TestCommitRejectsUnsupportedRootAndMismatchedManifestPointers(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())

	plan := commitPlan(0, "unknown/object.json", []byte(`{}`))
	if _, err := s.Commit(context.Background(), plan); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("unsupported root: %v", err)
	}

	plan = commitPlan(0, "records/kr_01/revisions/rev_01/content.md", []byte("payload"))
	plan.Manifest.CurrentRecords = []model.RecordPointer{{RecordID: "kr_missing", Revision: "rev_missing", Status: model.RecordStatusActive}}
	if _, err := s.Commit(context.Background(), plan); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("missing record pointer: %v", err)
	}
}

func TestCommitPublishesGenerationOneAndCopiesReturnedData(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	data := []byte("immutable")
	plan := commitPlan(0, "records/kr_01/revisions/rev_01/content.md", data)
	plan.Writes = append(plan.Writes, store.ImmutableWrite{Path: "records/kr_01/revisions/rev_01/record.json", Data: []byte(`{}`)})
	plan.Manifest.CurrentRecords = []model.RecordPointer{{RecordID: "kr_01", Revision: "rev_01", Status: model.RecordStatusActive}}

	got, err := s.Commit(context.Background(), plan)
	if err != nil {
		t.Fatal(err)
	}
	if got.Generation != 1 || got.ParentGeneration == nil || *got.ParentGeneration != 0 {
		t.Fatalf("manifest chain: %+v", got)
	}
	data[0] = 'X'
	got.CurrentRecords[0].RecordID = "mutated"

	payload, err := os.ReadFile(filepath.Join(root, ".themico", "records", "kr_01", "revisions", "rev_01", "content.md"))
	if err != nil {
		t.Fatal(err)
	}
	if string(payload) != "immutable" {
		t.Fatalf("payload mutated: %q", payload)
	}
	current, err := s.Current()
	if err != nil {
		t.Fatal(err)
	}
	if current.CurrentRecords[0].RecordID != "kr_01" {
		t.Fatalf("returned slice exposed state: %+v", current.CurrentRecords)
	}
	current.CurrentRecords[0].RecordID = "mutated again"
	currentAgain, err := s.Current()
	if err != nil {
		t.Fatal(err)
	}
	if currentAgain.CurrentRecords[0].RecordID != "kr_01" {
		t.Fatalf("Current returned mutable state: %+v", currentAgain.CurrentRecords)
	}
}

func TestCommitPreRenameFaultLeavesPriorCurrentAndOrphanPayload(t *testing.T) {
	root := t.TempDir()
	opts := testOptions()
	opts.BeforeGenerationRename = func() error { return errors.New("injected fault") }
	s := mustInit(t, root, opts)
	path := "records/kr_fault/revisions/rev_fault/content.md"

	_, err := s.Commit(context.Background(), commitPlan(0, path, []byte("orphan")))
	if err == nil || errors.Is(err, store.ErrConflict) {
		t.Fatalf("error: %v", err)
	}
	current, currentErr := s.Current()
	if currentErr != nil {
		t.Fatal(currentErr)
	}
	if current.Generation != 0 {
		t.Fatalf("generation: %d", current.Generation)
	}
	if got, readErr := os.ReadFile(filepath.Join(root, ".themico", filepath.FromSlash(path))); readErr != nil || string(got) != "orphan" {
		t.Fatalf("orphan payload: %q, %v", got, readErr)
	}
	entries, readErr := os.ReadDir(filepath.Join(root, ".themico", "generations"))
	if readErr != nil {
		t.Fatal(readErr)
	}
	for _, entry := range entries {
		if entry.Name() == "gen-00000000000000000001" {
			t.Fatal("failed generation became visible")
		}
	}
}

func TestCommitRefusesImmutableOverwriteWithoutChangingBytes(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	path := "records/kr_01/revisions/rev_01/content.md"
	if _, err := s.Commit(context.Background(), commitPlan(0, path, []byte("winner"))); err != nil {
		t.Fatal(err)
	}

	_, err := s.Commit(context.Background(), commitPlan(1, path, []byte("loser")))
	if !errors.Is(err, store.ErrPrecondition) {
		t.Fatalf("error: %v", err)
	}
	got, readErr := os.ReadFile(filepath.Join(root, ".themico", filepath.FromSlash(path)))
	if readErr != nil {
		t.Fatal(readErr)
	}
	if string(got) != "winner" {
		t.Fatalf("bytes overwritten: %q", got)
	}
}

func TestConcurrentCommitHasOneWinnerAndOneConflict(t *testing.T) {
	root := t.TempDir()
	s1 := mustInit(t, root, testOptions())
	s2, err := store.Open(root, testOptions())
	if err != nil {
		t.Fatal(err)
	}

	barrier := &renameBarrier{arrived: make(chan struct{}, 2), release: make(chan struct{})}
	s1 = mustOpen(t, root, optionsWithRenameHook(testOptionsWithStart(100), barrier.hook))
	s2 = mustOpen(t, root, optionsWithRenameHook(testOptionsWithStart(200), barrier.hook))

	start := make(chan struct{})
	type outcome struct {
		manifest model.Manifest
		err      error
	}
	outcomes := make(chan outcome, 2)
	var group sync.WaitGroup
	for i, item := range []struct {
		s    *store.Store
		path string
		data string
	}{
		{s: s1, path: "records/kr_a/revisions/rev_a/content.md", data: "alpha"},
		{s: s2, path: "records/kr_b/revisions/rev_b/content.md", data: "beta"},
	} {
		_ = i
		group.Add(1)
		go func(item struct {
			s    *store.Store
			path string
			data string
		}) {
			defer group.Done()
			<-start
			manifest, commitErr := item.s.Commit(context.Background(), commitPlan(0, item.path, []byte(item.data)))
			outcomes <- outcome{manifest: manifest, err: commitErr}
		}(item)
	}
	close(start)
	<-barrier.arrived
	<-barrier.arrived
	close(barrier.release)
	group.Wait()
	close(outcomes)

	successes, conflicts := 0, 0
	for result := range outcomes {
		switch {
		case result.err == nil:
			successes++
		case errors.Is(result.err, store.ErrConflict):
			conflicts++
		default:
			t.Fatalf("unexpected outcome: %v", result.err)
		}
	}
	if successes != 1 || conflicts != 1 {
		t.Fatalf("successes=%d conflicts=%d", successes, conflicts)
	}
	current, err := s1.Current()
	if err != nil {
		t.Fatal(err)
	}
	if current.Generation != 1 {
		t.Fatalf("generation: %d", current.Generation)
	}
}

func TestOpenIgnoresUnnumberedStagingGeneration(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	staging := filepath.Join(root, ".themico", "generations", ".staging-incomplete")
	mustMkdirAll(t, staging)
	mustWrite(t, filepath.Join(staging, "manifest.json"), []byte(`{}`))
	current, err := s.Current()
	if err != nil {
		t.Fatal(err)
	}
	if current.Generation != 0 {
		t.Fatalf("generation: %d", current.Generation)
	}
}

func TestOpenAndCurrentRejectInvalidGenerationChain(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(t *testing.T, root string, manifest model.Manifest)
	}{
		{
			name: "higher broken generation",
			mutate: func(t *testing.T, root string, _ model.Manifest) {
				dir := filepath.Join(root, ".themico", "generations", "gen-00000000000000000002")
				mustMkdirAll(t, dir)
				mustWrite(t, filepath.Join(dir, "manifest.json"), []byte(`{}`))
			},
		},
		{
			name: "parent mismatch",
			mutate: func(t *testing.T, root string, manifest model.Manifest) {
				dir := filepath.Join(root, ".themico", "generations", "gen-00000000000000000001")
				mustMkdirAll(t, dir)
				views := json.RawMessage(`{}`)
				viewsDigest, err := canonical.Digest(views)
				if err != nil {
					t.Fatal(err)
				}
				wrongParent := uint64(99)
				next := model.NormalizeManifest(model.Manifest{
					Schema:               "themico/manifest",
					Generation:           1,
					ParentGeneration:     &wrongParent,
					ParentManifestDigest: manifest.Digest,
					CurrentCandidates:    []model.CandidatePointer{},
					CurrentRecords:       []model.RecordPointer{},
					Projections:          []model.ProjectionRef{},
					ViewsDigest:          viewsDigest,
				})
				next.Digest = digestManifest(t, next)
				manifestBytes, err := canonical.Encode(next)
				if err != nil {
					t.Fatal(err)
				}
				viewsBytes, err := canonical.Encode(views)
				if err != nil {
					t.Fatal(err)
				}
				mustWrite(t, filepath.Join(dir, "manifest.json"), manifestBytes)
				mustWrite(t, filepath.Join(dir, "views.json"), viewsBytes)
			},
		},
		{
			name: "views digest mismatch",
			mutate: func(t *testing.T, root string, _ model.Manifest) {
				mustWrite(t, filepath.Join(root, ".themico", "generations", "gen-00000000000000000000", "views.json"), []byte(`{"broken":true}`))
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			s := mustInit(t, root, testOptions())
			manifest, err := s.Current()
			if err != nil {
				t.Fatal(err)
			}
			test.mutate(t, root, manifest)
			if _, err := store.Open(root, testOptions()); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("Open error: %v", err)
			}
			if _, err := s.Current(); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("Current error: %v", err)
			}
		})
	}
}

func TestOpenRejectsStrictMachineJSONViolations(t *testing.T) {
	for _, test := range []struct {
		name string
		data []byte
	}{
		{name: "unknown field", data: []byte(`{"schema":"themico/store","store_id":"op_00000000000000000000000000000001","created_at":"x","genesis_manifest_digest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","extra":true}`)},
		{name: "duplicate field", data: []byte(`{"schema":"themico/store","schema":"themico/store","store_id":"op_00000000000000000000000000000001","created_at":"x","genesis_manifest_digest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}`)},
		{name: "trailing JSON", data: []byte(`{} {}`)},
		{name: "invalid UTF-8", data: []byte{'{', '"', 'a', '"', ':', '"', 0xff, '"', '}'}},
	} {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			mustInit(t, root, testOptions())
			overwrite(t, filepath.Join(root, ".themico", "store.json"), test.data)
			if _, err := store.Open(root, testOptions()); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("error: %v", err)
			}
		})
	}
}

func TestOpenRejectsMissingOrMismatchedReferencedPayload(t *testing.T) {
	for _, test := range []struct {
		name   string
		mutate func(t *testing.T, path string)
	}{
		{name: "missing", mutate: func(t *testing.T, path string) {
			if err := os.Remove(path); err != nil {
				t.Fatal(err)
			}
		}},
		{name: "mismatched", mutate: func(t *testing.T, path string) { mustWrite(t, path, []byte(`{"changed":true}`)) }},
	} {
		t.Run(test.name, func(t *testing.T) {
			root := t.TempDir()
			s := mustInit(t, root, testOptions())
			record := []byte(`{}`)
			content := []byte("content")
			path := "records/kr_01/revisions/rev_01/content.md"
			plan := commitPlan(0, "records/kr_01/revisions/rev_01/record.json", record)
			plan.Writes = append(plan.Writes, store.ImmutableWrite{Path: path, Data: content})
			plan.Manifest.CurrentRecords = []model.RecordPointer{{RecordID: "kr_01", Revision: "rev_01", Status: model.RecordStatusActive}}
			plan.Manifest.Projections = []model.ProjectionRef{{RecordID: "kr_01", Revision: "rev_01", L3Digest: rawSHA256(content)}}
			if _, err := s.Commit(context.Background(), plan); err != nil {
				t.Fatal(err)
			}
			test.mutate(t, filepath.Join(root, ".themico", filepath.FromSlash(path)))
			if _, err := store.Open(root, testOptions()); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("Open error: %v", err)
			}
		})
	}
}

func TestHigherBrokenGenerationIsNotWriterBaseline(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	broken := filepath.Join(root, ".themico", "generations", "gen-00000000000000000002")
	mustMkdirAll(t, broken)
	mustWrite(t, filepath.Join(broken, "manifest.json"), []byte(`{}`))

	_, err := s.Commit(context.Background(), commitPlan(2, "records/kr/revisions/rev/content.md", []byte("payload")))
	if !errors.Is(err, store.ErrValidation) {
		t.Fatalf("error: %v", err)
	}
}

func TestCommitRejectsInvalidViewsWithoutWritingPayload(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())
	path := "records/kr/revisions/rev/content.md"
	plan := commitPlan(0, path, []byte("payload"))
	plan.Views = json.RawMessage(`{"duplicate":1,"duplicate":2}`)
	if _, err := s.Commit(context.Background(), plan); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("error: %v", err)
	}
	if _, err := os.Stat(filepath.Join(root, ".themico", filepath.FromSlash(path))); !os.IsNotExist(err) {
		t.Fatalf("payload written despite invalid views: %v", err)
	}
}

func TestCommitValidatesContextExpectedGenerationAndDuplicateTargets(t *testing.T) {
	root := t.TempDir()
	s := mustInit(t, root, testOptions())

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := s.Commit(ctx, commitPlan(0, "records/kr/revisions/rev/content.md", []byte("payload"))); !errors.Is(err, context.Canceled) {
		t.Fatalf("cancellation: %v", err)
	}
	if _, err := s.Commit(context.Background(), commitPlan(1, "records/kr/revisions/rev/content.md", []byte("payload"))); !errors.Is(err, store.ErrConflict) {
		t.Fatalf("expected generation: %v", err)
	}
	plan := commitPlan(0, "records/kr/revisions/rev/content.md", []byte("one"))
	plan.Writes = append(plan.Writes, store.ImmutableWrite{Path: plan.Writes[0].Path, Data: []byte("two")})
	if _, err := s.Commit(context.Background(), plan); !errors.Is(err, store.ErrValidation) {
		t.Fatalf("duplicate target: %v", err)
	}
}

func TestDefaultIDSourceUsesRequiredFormat(t *testing.T) {
	root := t.TempDir()
	opts := store.Options{Clock: func() time.Time { return time.Date(2026, 8, 3, 12, 34, 56, 0, time.UTC) }}
	if _, err := store.Init(root, opts); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(filepath.Join(root, ".themico", "store.json"))
	if err != nil {
		t.Fatal(err)
	}
	var metadata map[string]any
	if err := json.Unmarshal(data, &metadata); err != nil {
		t.Fatal(err)
	}
	id, _ := metadata["store_id"].(string)
	if len(id) != len("op_")+32 || id[:3] != "op_" {
		t.Fatalf("store ID: %q", id)
	}
	for _, char := range id[3:] {
		if !(char >= '0' && char <= '9') && !(char >= 'a' && char <= 'f') {
			t.Fatalf("store ID is not lowercase hex: %q", id)
		}
	}
}

type renameBarrier struct {
	arrived chan struct{}
	release chan struct{}
}

func (barrier *renameBarrier) hook() error {
	barrier.arrived <- struct{}{}
	<-barrier.release
	return nil
}

func optionsWithRenameHook(opts store.Options, hook func() error) store.Options {
	opts.BeforeGenerationRename = hook
	return opts
}

func mustOpen(t *testing.T, root string, opts store.Options) *store.Store {
	t.Helper()
	s, err := store.Open(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func testOptions() store.Options {
	return testOptionsWithStart(0)
}

func testOptionsWithStart(start uint64) store.Options {
	var counter atomic.Uint64
	counter.Store(start)
	return store.Options{
		Clock: func() time.Time {
			return time.Date(2026, 8, 3, 12, 34, 56, 123456789, time.UTC)
		},
		NewID: func(prefix string) (string, error) {
			value := counter.Add(1)
			return fmt.Sprintf("%s%032x", prefix, value), nil
		},
	}
}

func mustInit(t *testing.T, root string, opts store.Options) *store.Store {
	t.Helper()
	s, err := store.Init(root, opts)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func commitPlan(expected uint64, path string, data []byte) store.CommitPlan {
	return store.CommitPlan{
		ExpectedGeneration: expected,
		Writes:             []store.ImmutableWrite{{Path: path, Data: data}},
		Manifest: model.Manifest{
			Schema:            "caller-forged",
			Generation:        999,
			ParentGeneration:  uint64Pointer(999),
			CurrentCandidates: []model.CandidatePointer{},
			CurrentRecords:    []model.RecordPointer{},
			Projections:       []model.ProjectionRef{},
			ViewsDigest:       "caller-forged",
			Digest:            "caller-forged",
		},
		Views: json.RawMessage(`{}`),
	}
}

func assertGenesis(t *testing.T, manifest model.Manifest) {
	t.Helper()
	if manifest.Schema != "themico/manifest" || manifest.Generation != 0 || manifest.ParentGeneration != nil || manifest.ParentManifestDigest != "" {
		t.Fatalf("genesis: %+v", manifest)
	}
	if manifest.CurrentCandidates == nil || manifest.CurrentRecords == nil || manifest.Projections == nil {
		t.Fatalf("genesis slices must be non-nil: %+v", manifest)
	}
	if len(manifest.CurrentCandidates) != 0 || len(manifest.CurrentRecords) != 0 || len(manifest.Projections) != 0 {
		t.Fatalf("genesis pointers: %+v", manifest)
	}
	if manifest.ViewsDigest == "" || manifest.Digest == "" {
		t.Fatalf("genesis digests: %+v", manifest)
	}
}

func rawSHA256(data []byte) string {
	digest := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(digest[:])
}

func digestManifest(t *testing.T, manifest model.Manifest) string {
	t.Helper()
	manifest.Digest = ""
	digest, err := canonical.Digest(model.NormalizeManifest(manifest))
	if err != nil {
		t.Fatal(err)
	}
	return digest
}

func uint64Pointer(value uint64) *uint64 {
	return &value
}

func mustMkdirAll(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
}

func overwrite(t *testing.T, path string, data []byte) {
	t.Helper()
	if err := os.WriteFile(path, bytes.Clone(data), 0o600); err != nil {
		t.Fatal(err)
	}
}

func mustWrite(t *testing.T, path string, data []byte) {
	t.Helper()
	if err := os.WriteFile(path, bytes.Clone(data), 0o600); err != nil {
		t.Fatal(err)
	}
}
