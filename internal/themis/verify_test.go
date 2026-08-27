// Package themis verifies that numeric and existence assertions written in
// spec artifacts match what their recorded commands actually produce.
//
// The assertion form this package parses is defined in
// .themis/spec/template.md ("断言形态"): a one-line, backtick-delimited
// record of either `command` → `value` (two segments, the common case) or
// `command` → `raw output` → `value` (three segments, used when a value is
// derived from the output rather than being the output itself).
package themis

import (
	"strings"
	"testing"
)

func TestParseTwoSegment(t *testing.T) {
	line := "**命令 D1** — 行数：`wc -l < go.mod` → `3`"

	got, ok := ParseAssertion(line)
	if !ok {
		t.Fatalf("ParseAssertion(%q) reported no assertion; want one", line)
	}
	if got.Command != "wc -l < go.mod" {
		t.Errorf("Command = %q, want %q", got.Command, "wc -l < go.mod")
	}
	if got.Want != "3" {
		t.Errorf("Want = %q, want %q", got.Want, "3")
	}
	if got.RawOutput != "" {
		t.Errorf("RawOutput = %q, want empty for a two-segment assertion", got.RawOutput)
	}
}

func TestParseThreeSegment(t *testing.T) {
	line := "`ls -1 .themis/spec/` → `README.md flow.md` → `2 份文件`"

	got, ok := ParseAssertion(line)
	if !ok {
		t.Fatalf("ParseAssertion(%q) reported no assertion; want one", line)
	}
	if got.Command != "ls -1 .themis/spec/" {
		t.Errorf("Command = %q, want %q", got.Command, "ls -1 .themis/spec/")
	}
	// For a three-segment assertion the machine-checkable half is the raw
	// output; the step from RawOutput to Want is a human judgement that this
	// package deliberately does not make.
	if got.RawOutput != "README.md flow.md" {
		t.Errorf("RawOutput = %q, want %q", got.RawOutput, "README.md flow.md")
	}
	if got.Want != "2 份文件" {
		t.Errorf("Want = %q, want %q", got.Want, "2 份文件")
	}
}

// Prose vastly outnumbers assertions in a spec artifact, so a line that does
// not match the form is skipped rather than reported as an error. R2 ruling
// three chose this deliberately: reporting would make the tool unusable.
func TestParseSkipsNonAssertions(t *testing.T) {
	for _, line := range []string{
		"这是一段普通的散文，不含任何断言。",
		"`只有一个反引号段，没有箭头`",
		"",
	} {
		if _, ok := ParseAssertion(line); ok {
			t.Errorf("ParseAssertion(%q) reported an assertion; want none", line)
		}
	}
}

func TestAllowlistAdmitsReadOnlyCommand(t *testing.T) {
	if err := CheckAllowed("grep -c foo bar.md"); err != nil {
		t.Errorf("CheckAllowed rejected a read-only command: %v", err)
	}
}

func TestAllowlistRejectsUnlistedCommand(t *testing.T) {
	err := CheckAllowed("rm -rf /")
	if err == nil {
		t.Fatal("CheckAllowed admitted `rm`; want rejection")
	}
	if !strings.Contains(err.Error(), "rm") {
		t.Errorf("error %q does not name the rejected command", err)
	}
}

// A pipeline is admitted only when every stage is, because the allowlist is
// the whole point: `grep x | rm -rf y` has an admitted first word.
func TestAllowlistChecksEveryPipelineStage(t *testing.T) {
	if err := CheckAllowed("grep -o x f.md | sort -u | wc -l"); err != nil {
		t.Errorf("CheckAllowed rejected an all-read-only pipeline: %v", err)
	}
	if err := CheckAllowed("grep -o x f.md | rm -rf y"); err == nil {
		t.Fatal("CheckAllowed admitted a pipeline whose second stage is `rm`; want rejection")
	}
}

// Shell metacharacters are refused outright rather than passed through,
// because this package never hands a command to a shell — that is what keeps
// the allowlist from being decorative (R2 ruling one).
func TestAllowlistRejectsShellMetacharacters(t *testing.T) {
	for _, command := range []string{
		"grep x f.md > out.txt",
		"grep x f.md && rm -rf y",
		"grep $(whoami) f.md",
		"grep x f.md; rm -rf y",
	} {
		if err := CheckAllowed(command); err == nil {
			t.Errorf("CheckAllowed(%q) admitted shell metacharacters; want rejection", command)
		}
	}
}

func TestVerifyAcceptsMatchingAssertion(t *testing.T) {
	// `echo` is not on the allowlist, so the fixture uses a real read-only
	// command whose output is stable in this repository.
	line := "`wc -l < internal/themis/testdata/three-lines.txt` → `3`"

	result, err := VerifyLine(line, "../..")
	if err != nil {
		t.Fatalf("VerifyLine returned an error: %v", err)
	}
	if !result.OK {
		t.Errorf("VerifyLine reported a mismatch: got %q, want %q", result.Got, result.Want)
	}
}

func TestVerifyRejectsMismatchedAssertion(t *testing.T) {
	line := "`wc -l < internal/themis/testdata/three-lines.txt` → `4`"

	result, err := VerifyLine(line, "../..")
	if err != nil {
		t.Fatalf("VerifyLine returned an error: %v", err)
	}
	if result.OK {
		t.Fatal("VerifyLine accepted an assertion whose value is wrong; want a mismatch")
	}
	if result.Got != "3" || result.Want != "4" {
		t.Errorf("got %q / want %q; expected got=3, want=4", result.Got, result.Want)
	}
}

// For a three-segment assertion the comparison target is the raw output, not
// the derived value — the derivation itself is left to a human reader.
func TestVerifyComparesRawOutputForThreeSegment(t *testing.T) {
	line := "`wc -l < internal/themis/testdata/three-lines.txt` → `3` → `三行`"

	result, err := VerifyLine(line, "../..")
	if err != nil {
		t.Fatalf("VerifyLine returned an error: %v", err)
	}
	if !result.OK {
		t.Errorf("VerifyLine compared against the derived value instead of the raw output: got %q, want %q", result.Got, result.Want)
	}
}

// Assertions in this project routinely quote their patterns — `grep -c '^## §11'`
// — so splitting a command on whitespace alone would hand `grep` two broken
// arguments. Quote handling belongs here rather than to whichever `grep` the
// machine happens to have: a ported Windows binary that re-parses the raw
// command line would mask this, and the same assertion would then behave
// differently on another machine.
func TestSplitStageHonorsQuotedArguments(t *testing.T) {
	fields, redirect, err := splitStage("grep -c 'two words' f.md")
	if err != nil {
		t.Fatalf("splitStage returned an error: %v", err)
	}
	if redirect != "" {
		t.Errorf("redirect = %q, want empty", redirect)
	}
	want := []string{"grep", "-c", "two words", "f.md"}
	if len(fields) != len(want) {
		t.Fatalf("fields = %q, want %q", fields, want)
	}
	for i := range want {
		if fields[i] != want[i] {
			t.Errorf("fields[%d] = %q, want %q", i, fields[i], want[i])
		}
	}
}

func TestVerifyMultiWordQuotedPattern(t *testing.T) {
	// The fixture holds "two words here" on exactly 2 of its 3 lines.
	line := "`grep -c 'two words' internal/themis/testdata/quoted.txt` → `2`"

	result, err := VerifyLine(line, "../..")
	if err != nil {
		t.Fatalf("VerifyLine returned an error: %v", err)
	}
	if !result.OK {
		t.Errorf("VerifyLine reported a mismatch: got %q, want %q", result.Got, result.Want)
	}
}

// `awk '{print $1}'` is a legitimate read-only assertion command. A blanket ban
// on `$` would reject it, so the ban covers only `$(`, which is the form that
// reaches another command.
func TestAllowlistAdmitsAwkFieldReference(t *testing.T) {
	if err := CheckAllowed("awk '{print $1}' f.md"); err != nil {
		t.Errorf("CheckAllowed rejected an awk field reference: %v", err)
	}
}

// Documentation tables pair two code spans with an arrow — `task/basic.md` |
// 基础任务 → `### T-B<n>` — which matches the assertion shape by accident. The
// first run of this tool against a real control-plane file produced four
// reports, of which two were table rows. A checker that cries wolf on prose
// gets switched off, so the shape alone is not enough: the first segment must
// look like a command.
func TestParseSkipsDocumentationTableRows(t *testing.T) {
	for _, line := range []string{
		"| `task/basic.md` | 基础任务 → `### T-B<n>` |",
		"| `design.md` | 架构与边界 → `结构决策` |",
	} {
		if got, ok := ParseAssertion(line); ok {
			t.Errorf("ParseAssertion(%q) reported an assertion (command=%q); want none", line, got.Command)
		}
	}
}

// The guard above must not reject real assertions, including the pipelines and
// redirections that real artifacts are full of.
func TestParseStillAcceptsRealCommands(t *testing.T) {
	for _, line := range []string{
		"`wc -l < .themis/spec/rules.md` → `133`",
		"`awk '/断言形态/,0' .themis/spec/template.md | grep -c '一行'` → `1`",
		"`git log --oneline -1` → `abc1234 某次提交`",
	} {
		if _, ok := ParseAssertion(line); !ok {
			t.Errorf("ParseAssertion(%q) reported no assertion; want one", line)
		}
	}
}

// A `|` inside quotes belongs to the argument, not to the pipeline. Splitting
// on `|` before parsing quotes cuts `grep -cE 'a|b'` in half and then reports
// the fragment as a forbidden command — which is how this was found, on a real
// artifact.
func TestPipelineSplitIgnoresQuotedPipe(t *testing.T) {
	if err := CheckAllowed("grep -cE '独立成条|批准本身' f.md"); err != nil {
		t.Errorf("CheckAllowed rejected a quoted alternation: %v", err)
	}
	// The unquoted case must still split, and still check both stages.
	if err := CheckAllowed("grep -o x f.md | rm -rf y"); err == nil {
		t.Error("CheckAllowed admitted a real pipeline into `rm`; want rejection")
	}
}

// Criteria are routinely written as thresholds — `≥2` means "at least two",
// and an actual 3 satisfies it. Comparing strings exactly would report every
// such criterion as a failure, which on a first real scan was 4 of 22 reports.
func TestVerifyHonorsThresholdNotation(t *testing.T) {
	fixture := "internal/themis/testdata/three-lines.txt"

	satisfied := []string{"≥3", "≥2", "≤3", "≤9", ">2", "<4"}
	for _, want := range satisfied {
		line := "`wc -l < " + fixture + "` → `" + want + "`"
		result, err := VerifyLine(line, "../..")
		if err != nil {
			t.Fatalf("VerifyLine(%q) returned an error: %v", want, err)
		}
		if !result.OK {
			t.Errorf("threshold %q rejected an actual of 3; want satisfied", want)
		}
	}

	violated := []string{"≥4", "≤2", ">3", "<3"}
	for _, want := range violated {
		line := "`wc -l < " + fixture + "` → `" + want + "`"
		result, err := VerifyLine(line, "../..")
		if err != nil {
			t.Fatalf("VerifyLine(%q) returned an error: %v", want, err)
		}
		if result.OK {
			t.Errorf("threshold %q accepted an actual of 3; want violated", want)
		}
	}
}

// A threshold is only meaningful against a number. `≥abc` is not a threshold,
// and a non-numeric output cannot satisfy one.
func TestVerifyThresholdRequiresNumericOutput(t *testing.T) {
	line := "`ls -1 internal/themis/testdata/three-lines.txt` → `≥1`"
	result, err := VerifyLine(line, "../..")
	if err != nil {
		t.Fatalf("VerifyLine returned an error: %v", err)
	}
	if result.OK {
		t.Error("a non-numeric output satisfied a threshold; want a mismatch")
	}
}
