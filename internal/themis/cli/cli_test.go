package cli

import (
	"bytes"
	"context"
	"strings"
	"testing"
)

// A run over a file whose assertions all hold reports success and says nothing
// about the lines it checked — silence is the pass signal, so a passing run
// stays readable when it covers a whole artifact.
func TestRunAcceptsMatchingAssertions(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/passing.md"}, &stdout, &stderr)

	if code != 0 {
		t.Errorf("exit code = %d, want 0; stderr: %s", code, stderr.String())
	}
	if strings.Contains(stdout.String(), "不一致") {
		t.Errorf("a passing run reported a mismatch: %s", stdout.String())
	}
}

// A mismatch must fail the process, not merely mention itself in passing: the
// whole point is that a wrong number cannot slip through unnoticed.
func TestRunRejectsMismatchedAssertion(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/failing.md"}, &stdout, &stderr)

	if code == 0 {
		t.Fatalf("exit code = 0 for a file with a wrong value; want non-zero. stdout: %s", stdout.String())
	}
	// The report must name the file and both values, so the reader can find and
	// fix the assertion without re-running anything by hand.
	out := stdout.String() + stderr.String()
	for _, want := range []string{"failing.md", "3", "99"} {
		if !strings.Contains(out, want) {
			t.Errorf("report does not mention %q; got: %s", want, out)
		}
	}
}

func TestRunRejectsCommandOutsideAllowlist(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/forbidden.md"}, &stdout, &stderr)

	if code == 0 {
		t.Fatal("exit code = 0 for a file invoking a command outside the allowlist; want non-zero")
	}
	if out := stdout.String() + stderr.String(); !strings.Contains(out, "rm") {
		t.Errorf("report does not name the rejected command; got: %s", out)
	}
}

func TestRunReportsUsageWithoutArguments(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{}, &stdout, &stderr)

	if code == 0 {
		t.Error("exit code = 0 with no arguments; want non-zero")
	}
	if out := stdout.String() + stderr.String(); !strings.Contains(out, "verify") {
		t.Errorf("usage text does not name the verify command; got: %s", out)
	}
}

func TestRunReportsMissingFile(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/no-such-file.md"}, &stdout, &stderr)

	if code == 0 {
		t.Error("exit code = 0 for a missing file; want non-zero")
	}
}

// Fenced code blocks hold examples and quoted output, not live claims. The
// template that defines the assertion form illustrates it inside a fence, and
// those illustrations must not be re-run: their numbers are frozen by the
// example, so checking them reports a failure that no edit can fix.
func TestRunSkipsFencedCodeBlocks(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/fenced.md"}, &stdout, &stderr)

	if code != 0 {
		t.Errorf("exit code = %d for a file whose only assertions are inside a fence; want 0.\nstdout: %s\nstderr: %s",
			code, stdout.String(), stderr.String())
	}
}

// The fence must close again: an assertion after the block is live.
func TestRunChecksAssertionsAfterAFence(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"verify", "testdata/fenced-then-live.md"}, &stdout, &stderr)

	if code == 0 {
		t.Errorf("exit code = 0; the wrong assertion after the fence was not checked. stdout: %s", stdout.String())
	}
}

// The overlap subcommand reports restatement between control-plane files.
func TestOverlapCommand(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"overlap", "testdata/spec"}, &stdout, &stderr)

	if code != 0 {
		t.Fatalf("exit code = %d, want 0; stderr: %s", code, stderr.String())
	}
	out := stdout.String()
	// The fixture pair restates a criterion; the report must surface it.
	if !strings.Contains(out, "只判三项") {
		t.Errorf("report omits the restated sentence:\n%s", out)
	}
	// And it must name the filter rules, so a wrong exclusion stays visible.
	if !strings.Contains(out, "经验规则") {
		t.Errorf("report does not warn its filter rules are heuristics:\n%s", out)
	}
}

// Finding overlaps is a lead for a human, not a determinate error: the exit
// code stays 0 so this check can never become a hard block. That differs
// deliberately from verify, where a mismatched number is a definite defect.
func TestOverlapExitCode(t *testing.T) {
	var stdout, stderr bytes.Buffer

	code := Run(context.Background(), []string{"overlap", "testdata/spec"}, &stdout, &stderr)

	if code != 0 {
		t.Errorf("exit code = %d after finding overlaps; want 0 — overlap must not block", code)
	}
	if stdout.Len() == 0 {
		t.Error("no report written despite fixtures containing an overlap")
	}
}

func TestOverlapReportsMissingDirectory(t *testing.T) {
	var stdout, stderr bytes.Buffer

	if code := Run(context.Background(), []string{"overlap", "testdata/no-such-dir"}, &stdout, &stderr); code == 0 {
		t.Error("exit code = 0 for a missing directory; want non-zero")
	}
}
