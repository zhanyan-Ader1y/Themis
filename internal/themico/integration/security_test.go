// This file covers path and machine-input safety: absolute-path and ".."
// source escapes, symlink/junction source escapes, oversized/malformed
// machine JSON (unknown field, duplicate key, invalid UTF-8), the L3
// frontmatter prohibition, source digest drift between prepare and publish,
// and the exact byte-budget boundary. Every scenario is driven through
// cli.Run; on this platform symlink creation requires a privilege this
// sandbox does not hold (verified empirically — see
// TestCandidateCreateRejectsSymlinkSourceEscape below), so that one case is
// skipped with an explicit reason rather than faked, per task-11-brief.md's
// ruling 3. Directory junctions do not require that privilege on Windows,
// so the junction-escape case runs for real.
package integration

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/query"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

// ---- source path escapes ----

func TestCandidateCreateRejectsAbsolutePathSource(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	sourceOutsideRepo := filepath.Join(t.TempDir(), "content.md")
	if err := os.WriteFile(sourceOutsideRepo, []byte("outside"), 0o600); err != nil {
		t.Fatal(err)
	}

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.SourcePaths = []string{sourceOutsideRepo}
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

func TestCandidateCreateRejectsDotDotSourceEscape(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.SourcePaths = []string{"../outside.txt"}
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// TestCandidateCreateRejectsSymlinkSourceEscape proves a source path whose
// final component is a symlink is rejected. Symlink creation on this
// Windows sandbox fails with "A required privilege is not held by the
// client" (verified interactively while designing this test — Developer
// Mode / SeCreateSymbolicLinkPrivilege is not granted here), so per
// task-11-brief.md's ruling 3 this test skips with that exact cause instead
// of faking a pass. See TestCandidateCreateRejectsJunctionSourceEscape below
// for the platform-available equivalent (a directory junction), which does
// not require that privilege and does run for real.
func TestCandidateCreateRejectsSymlinkSourceEscape(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	outsideDir := t.TempDir()
	target := filepath.Join(outsideDir, "secret.txt")
	if err := os.WriteFile(target, []byte("topsecret"), 0o600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(repository, "escape.txt")
	if err := os.Symlink(target, link); err != nil {
		t.Skipf("symlink creation unavailable on this platform: %v", err)
	}

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.SourcePaths = []string{"escape.txt"}
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// TestCandidateCreateRejectsJunctionSourceEscape proves a source path
// reached through a Windows directory junction pointing outside the
// repository is rejected. Junction creation (unlike a symlink) does not
// require an elevated privilege on Windows, so this runs for real on this
// platform: verified interactively that `cmd /c mklink /J` succeeds without
// admin/Developer Mode here. If it is ever unavailable, this skips with the
// mklink failure instead of faking a pass, matching the symlink case above.
func TestCandidateCreateRejectsJunctionSourceEscape(t *testing.T) {
	if runtime.GOOS != "windows" {
		t.Skip("directory junctions are a Windows-specific mechanism")
	}
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	outsideDir := t.TempDir()
	if err := os.WriteFile(filepath.Join(outsideDir, "secret.txt"), []byte("topsecret"), 0o600); err != nil {
		t.Fatal(err)
	}
	junction := filepath.Join(repository, "escape_dir")
	if output, err := exec.Command("cmd", "/c", "mklink", "/J", junction, outsideDir).CombinedOutput(); err != nil {
		t.Skipf("directory junction creation unavailable on this platform: %v (%s)", err, output)
	}

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.SourcePaths = []string{"escape_dir/secret.txt"}
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// ---- machine JSON input safety ----

func TestCandidateCreateRejectsOversizedInputFile(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.ClassificationRationale = strings.Repeat("a", (1<<20)+100) // pushes the encoded file past the 1 MiB machine JSON ceiling
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	if info, err := os.Stat(inputPath); err != nil || info.Size() <= 1<<20 {
		t.Fatalf("test fixture did not exceed 1 MiB: size=%v err=%v", info, err)
	}
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusUsageError, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

func TestCandidateCreateRejectsUnknownField(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	data, err := json.Marshal(createCandidateRequest(t, model.TypeDesignDecision))
	if err != nil {
		t.Fatal(err)
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(data, &fields); err != nil {
		t.Fatal(err)
	}
	fields["unexpected_field"] = json.RawMessage(`true`)
	withExtra, err := json.Marshal(fields)
	if err != nil {
		t.Fatal(err)
	}
	inputPath := writeRawFile(t, dir, "candidate.json", withExtra)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusUsageError, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// TestCandidateCreateRejectsDuplicateKey proves a duplicate JSON object key
// is rejected. It targets l2.payload specifically: that sub-object survives
// the CLI's own top-level decode as an untouched json.RawMessage (Go's
// encoding/json does not reject duplicate keys during a normal struct
// decode — it silently keeps the last one), so the only place a duplicate
// key inside it is actually caught is later, when the persisted revision is
// re-encoded through internal/themico/canonical.Encode, which re-parses the
// full byte stream and explicitly rejects duplicate object keys anywhere
// within it.
func TestCandidateCreateRejectsDuplicateKey(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	payloadWithDuplicateKey := `{"affected_units":[],"affected_units":[],"constraints":[],"alternatives":[],"consequences":[],"reevaluate_when":[]}`
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.L2.Payload = json.RawMessage(payloadWithDuplicateKey)
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// TestCandidateCreateRejectsInvalidUTF8 embeds a raw invalid UTF-8 byte
// inside l2.payload's raw JSON (rather than in a typed string field like
// l1.title): a typed Go string field gets re-marshaled through
// encoding/json on its way to disk, which silently replaces invalid bytes
// with U+FFFD before internal/themico/canonical.Encode ever inspects it, so
// invalid bytes there would never surface as a rejection. l2.payload is
// carried as json.RawMessage end to end — its bytes reach
// canonical.Encode's utf8.Valid check completely unmodified.
func TestCandidateCreateRejectsInvalidUTF8(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	invalidPayload := append([]byte(`{"affected_units":["a`), 0xFF)
	invalidPayload = append(invalidPayload, []byte(`b"],"constraints":[],"alternatives":[],"consequences":[],"reevaluate_when":[]}`)...)

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.L2.Payload = json.RawMessage(invalidPayload)
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}

// ---- L3 frontmatter ----

// TestValidateRejectsL3Frontmatter proves the YAML-frontmatter prohibition
// is enforced at `validate` time, not at `candidate create` time: create
// only proves structure, so it must still succeed here, and validate is the
// deterministic gate that turns the forbidden frontmatter into
// validation_failed.
func TestValidateRejectsL3Frontmatter(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	frontmatterContent := append([]byte("---\ntitle: x\n---\n"), typedContent(t, model.TypeDesignDecision, "标题")...)
	contentPath := writeRawFile(t, dir, "content.md", frontmatterContent)

	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
	var created model.CandidateRevision
	decodeOutput(t, envelope, &created)

	confirmedRevision := confirmType(t, repository, created.CandidateID, created.Revision, model.TypeDesignDecision)
	mustRunCLI(t, result.StatusValidationFailed, "validate", "--root", repository,
		"--candidate", created.CandidateID, "--revision", confirmedRevision)
}

// ---- source digest drift between prepare and publish ----

// TestPublishRejectsSourceDigestDrift binds a source at candidate-create
// time, prepares successfully against its original bytes, then mutates the
// source file before calling publish. Publish independently re-reads the
// repository's current bytes and must fail closed instead of trusting the
// digest frozen at prepare time.
func TestPublishRejectsSourceDigestDrift(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	sourceRelativePath := filepath.Join("docs", "source.txt")
	sourceAbsolutePath := filepath.Join(repository, sourceRelativePath)
	if err := os.MkdirAll(filepath.Dir(sourceAbsolutePath), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(sourceAbsolutePath, []byte("v1"), 0o600); err != nil {
		t.Fatal(err)
	}

	dir := t.TempDir()
	request := createCandidateRequest(t, model.TypeDesignDecision)
	request.SourcePaths = []string{filepath.ToSlash(sourceRelativePath)}
	inputPath := writeJSONFile(t, dir, "candidate.json", request)
	contentPath := writeRawFile(t, dir, "content.md", typedContent(t, model.TypeDesignDecision, "标题"))
	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
	var created model.CandidateRevision
	decodeOutput(t, envelope, &created)

	confirmedRevision := confirmType(t, repository, created.CandidateID, created.Revision, model.TypeDesignDecision)
	mustRunCLI(t, result.StatusSucceeded, "validate", "--root", repository,
		"--candidate", created.CandidateID, "--revision", confirmedRevision)
	prepare := preparePublish(t, repository, created.CandidateID, confirmedRevision)

	// Drift the source after prepare, before publish.
	if err := os.WriteFile(sourceAbsolutePath, []byte("v2"), 0o600); err != nil {
		t.Fatal(err)
	}

	approvalDir := t.TempDir()
	approvalPath := writeJSONFile(t, approvalDir, "approval.json", approvalFor(prepare))
	mustRunCLI(t, result.StatusValidationFailed, "publish", "--root", repository,
		"--prepare", prepare.PrepareID, "--approval", approvalPath)
}

// ---- byte budget exact boundary ----

// TestQueryContentBudgetExactBoundary establishes the true encoded size of
// one matching candidate via an effectively unbounded query, then proves
// content_budget_bytes is an inclusive ceiling: exactly that many bytes
// succeeds, one byte less fails closed with budget_exceeded. It also proves
// the request-level bound (content_budget_bytes must be within [1, 16 MiB])
// is itself enforced at both ends.
func TestQueryContentBudgetExactBoundary(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)
	publish(t, repository, prepareReadyCandidate(t, repository, model.TypeDesignDecision))

	const maxBudget = 16 << 20

	unbounded := queryZone(t, repository, model.ZoneProjectKnowledge)
	exact := unbounded.Trace.ContentBytes
	if exact <= 0 {
		t.Fatalf("expected positive content bytes, got %d", exact)
	}

	runBudget := func(budget int64) result.Status {
		dir := t.TempDir()
		path := writeJSONFile(t, dir, "query.json", query.Request{
			Zones: []model.Zone{model.ZoneProjectKnowledge}, ContentBudgetBytes: budget,
		})
		return runCLIStatus(t, "query", "--root", repository, "--request", path)
	}

	if status := runBudget(exact); status != result.StatusSucceeded {
		t.Fatalf("budget=%d (exact) status=%s want succeeded", exact, status)
	}
	if status := runBudget(exact - 1); status != result.StatusBudgetExceeded {
		t.Fatalf("budget=%d (exact-1) status=%s want budget_exceeded", exact-1, status)
	}
	if status := runBudget(0); status != result.StatusValidationFailed {
		t.Fatalf("budget=0 status=%s want validation_failed (below the 1-byte minimum)", status)
	}
	if status := runBudget(maxBudget + 1); status != result.StatusValidationFailed {
		t.Fatalf("budget=%d status=%s want validation_failed (above the 16 MiB maximum)", maxBudget+1, status)
	}
	if status := runBudget(maxBudget); status != result.StatusSucceeded {
		t.Fatalf("budget=%d (exactly 16 MiB) status=%s want succeeded", maxBudget, status)
	}
}

// ---- content.md size ceiling ----

// contentCeilingBytes mirrors candidate.Service's own unexported maxContent
// ceiling (see its derivation comment in internal/themico/candidate/
// service.go) so these tests track the real limit without importing an
// unexported identifier.
const contentCeilingBytes = 128 << 10

// paddedTypedContent returns knowledgeType's minimal valid fixed-heading
// content, padded with inert trailing filler bytes (never starting a line
// with "#", so checkMarkdown's heading structure stays untouched) until it
// is exactly targetLen bytes.
func paddedTypedContent(t *testing.T, knowledgeType model.KnowledgeType, title string, targetLen int) []byte {
	t.Helper()
	base := typedContent(t, knowledgeType, title)
	if len(base) > targetLen {
		t.Fatalf("base content is %d bytes, already over target %d", len(base), targetLen)
	}
	padded := make([]byte, targetLen)
	copy(padded, base)
	for i := len(base); i < targetLen; i++ {
		padded[i] = 'a'
	}
	return padded
}

// TestCandidateContentAtCeilingRoundTripsThroughPublishAndInspectDepth3
// proves the fix for the "published but permanently unreadable" defect:
// content.md at exactly the new ceiling must survive create -> confirm-type
// -> prepare -> publish -> `inspect --depth 3`, coming back byte-identical.
func TestCandidateContentAtCeilingRoundTripsThroughPublishAndInspectDepth3(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	content := paddedTypedContent(t, model.TypeDesignDecision, "标题", contentCeilingBytes)
	if len(content) != contentCeilingBytes {
		t.Fatalf("fixture content is %d bytes, want exactly %d", len(content), contentCeilingBytes)
	}

	dir := t.TempDir()
	inputPath := writeJSONFile(t, dir, "candidate.json", createCandidateRequest(t, model.TypeDesignDecision))
	contentPath := writeRawFile(t, dir, "content.md", content)
	envelope := mustRunCLI(t, result.StatusSucceeded, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
	var created model.CandidateRevision
	decodeOutput(t, envelope, &created)

	confirmedRevision := confirmType(t, repository, created.CandidateID, created.Revision, model.TypeDesignDecision)
	prepare := preparePublish(t, repository, created.CandidateID, confirmedRevision)
	record := publish(t, repository, prepare)

	item := inspectRecord(t, repository, record.RecordID, 3)
	if item.L3 != string(content) {
		t.Fatalf("depth-3 L3 is %d bytes, want %d bytes identical to the published content.md", len(item.L3), len(content))
	}
}

// TestCandidateCreateRejectsContentOverCeiling is the CLI-level companion to
// candidate.Service's own unit tests: one byte over the ceiling must come
// back validation_failed through the real command surface, not merely from
// the service layer in isolation.
func TestCandidateCreateRejectsContentOverCeiling(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	content := paddedTypedContent(t, model.TypeDesignDecision, "标题", contentCeilingBytes+1)

	dir := t.TempDir()
	inputPath := writeJSONFile(t, dir, "candidate.json", createCandidateRequest(t, model.TypeDesignDecision))
	contentPath := writeRawFile(t, dir, "content.md", content)
	mustRunCLI(t, result.StatusValidationFailed, "candidate", "create", "--root", repository,
		"--input", inputPath, "--content", contentPath)
}
