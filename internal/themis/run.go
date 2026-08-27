package themis

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// Result records what re-running an assertion's command produced against what
// the artifact claimed it produced.
type Result struct {
	Assertion Assertion
	Got       string
	Want      string
	OK        bool
}

// VerifyLine re-runs the command recorded on one line and compares its output
// against the value written beside it. dir is the directory the command runs
// in — assertions in this project are written against the repository root.
//
// The comparison target for a three-segment assertion is the recorded raw
// output, not the derived conclusion: the derivation from output to conclusion
// is a human judgement (「4 份文件」 from a listing of four names), and a
// machine that tried to check it would reject every correct assertion.
//
// A line holding no assertion is not an error; it comes back as a zero Result.
func VerifyLine(line, dir string) (Result, error) {
	assertion, ok := ParseAssertion(line)
	if !ok {
		return Result{}, nil
	}

	if err := CheckAllowed(assertion.Command); err != nil {
		return Result{}, err
	}

	output, err := runPipeline(assertion.Command, dir)
	if err != nil {
		return Result{}, err
	}

	want := assertion.Want
	if assertion.RawOutput != "" {
		want = assertion.RawOutput
	}

	got := strings.TrimSpace(output)
	return Result{
		Assertion: assertion,
		Got:       got,
		Want:      want,
		OK:        matches(got, strings.TrimSpace(want)),
	}, nil
}

// matches compares an actual output against a recorded value, honouring the
// threshold notation criteria are written in: `≥2` is satisfied by 3, not by 1.
// Everything else compares as an exact string.
func matches(got, want string) bool {
	if operator, threshold, ok := parseThreshold(want); ok {
		actual, err := strconv.Atoi(got)
		if err != nil {
			return false // a threshold means nothing against non-numeric output
		}
		switch operator {
		case "≥", ">=":
			return actual >= threshold
		case "≤", "<=":
			return actual <= threshold
		case ">":
			return actual > threshold
		case "<":
			return actual < threshold
		}
	}
	return got == want
}

// parseThreshold splits a recorded value into its comparison operator and
// number, reporting whether it is a threshold at all.
func parseThreshold(want string) (operator string, threshold int, ok bool) {
	// Two-character operators first: `>=` would otherwise match `>`.
	for _, candidate := range []string{"≥", "≤", ">=", "<=", ">", "<"} {
		if !strings.HasPrefix(want, candidate) {
			continue
		}
		number, err := strconv.Atoi(strings.TrimSpace(strings.TrimPrefix(want, candidate)))
		if err != nil {
			return "", 0, false
		}
		return candidate, number, true
	}
	return "", 0, false
}

// runPipeline executes a `|`-separated command without a shell: each stage
// becomes its own process, and the stages are joined by pipes here. Going
// through a shell would make the allowlist decorative, since a shell would
// re-interpret the very syntax CheckAllowed refused.
func runPipeline(command, dir string) (string, error) {
	stages := splitPipeline(command)
	commands := make([]*exec.Cmd, 0, len(stages))

	for _, stage := range stages {
		fields, redirect, err := splitStage(stage)
		if err != nil {
			return "", err
		}

		cmd := exec.Command(fields[0], fields[1:]...)
		cmd.Dir = dir
		if redirect != "" {
			file, err := os.Open(filepath.Join(dir, redirect))
			if err != nil {
				return "", fmt.Errorf("打开重定向输入 %q 失败：%w", redirect, err)
			}
			defer file.Close()
			cmd.Stdin = file
		}
		commands = append(commands, cmd)
	}

	// Wire each stage's output to the next stage's input.
	for i := 0; i < len(commands)-1; i++ {
		pipe, err := commands[i].StdoutPipe()
		if err != nil {
			return "", err
		}
		commands[i+1].Stdin = pipe
	}

	var out, errOut bytes.Buffer
	last := commands[len(commands)-1]
	last.Stdout = &out
	for _, cmd := range commands {
		cmd.Stderr = &errOut
	}

	for _, cmd := range commands {
		if err := cmd.Start(); err != nil {
			return "", fmt.Errorf("启动 %q 失败：%w", cmd.Path, err)
		}
	}
	// Wait in order: an earlier stage must be reaped before the pipe it feeds
	// is considered done, and a non-zero exit from a middle stage is normal
	// (`grep` finding nothing) so only the last stage's failure is reported.
	var lastErr error
	for i, cmd := range commands {
		err := cmd.Wait()
		if i == len(commands)-1 {
			lastErr = err
		}
	}
	if lastErr != nil {
		// A command that produced output and exited non-zero is still usable —
		// `grep -c` exits 1 when the count is zero, and that zero is the answer.
		if out.Len() == 0 {
			return "", fmt.Errorf("命令执行失败：%s：%w：%s", command, lastErr, strings.TrimSpace(errOut.String()))
		}
	}
	return out.String(), nil
}

// splitStage separates a pipeline stage into the words that become argv,
// honouring single and double quotes, and pulls out an input redirection.
//
// Quotes are interpreted here rather than left to the command, because argv is
// what a command actually receives: `grep -c 'two words' f.md` must arrive as
// three arguments, not four. Some ported Windows builds of grep re-parse the
// raw command line and appear to work without this, which makes the bug
// invisible on one machine and real on the next.
//
// `<` is likewise interpreted here, because assertions routinely read a file
// that way (`wc -l < file`) and the alternative spellings are less readable.
func splitStage(stage string) (fields []string, redirect string, err error) {
	words, err := splitWords(stage)
	if err != nil {
		return nil, "", err
	}
	for i := 0; i < len(words); i++ {
		switch {
		case words[i].text == "<" && !words[i].quoted:
			if i+1 >= len(words) {
				return nil, "", fmt.Errorf("重定向 `<` 后没有文件名：%s", stage)
			}
			redirect = words[i+1].text
			i++
		case strings.HasPrefix(words[i].text, "<") && !words[i].quoted:
			redirect = strings.TrimPrefix(words[i].text, "<")
		default:
			fields = append(fields, words[i].text)
		}
	}
	if len(fields) == 0 {
		return nil, "", fmt.Errorf("管道中有空的一段：%s", stage)
	}
	return fields, redirect, nil
}

// word is one argv entry plus whether any of it was quoted, which decides
// whether a leading `<` means redirection or is part of the text.
type word struct {
	text   string
	quoted bool
}

// splitWords splits on whitespace outside quotes and strips the quotes it
// consumes. An unterminated quote is an error rather than a silent guess: the
// assertion's author meant something specific, and running a different command
// than they wrote is exactly the failure this package exists to catch.
func splitWords(stage string) ([]word, error) {
	var (
		words   []word
		current strings.Builder
		quote   rune
		started bool
		quoted  bool
	)
	flush := func() {
		if started {
			words = append(words, word{text: current.String(), quoted: quoted})
			current.Reset()
			started, quoted = false, false
		}
	}

	for _, r := range stage {
		switch {
		case quote != 0:
			if r == quote {
				quote = 0
			} else {
				current.WriteRune(r)
			}
		case r == '\'' || r == '"':
			quote = r
			started, quoted = true, true
		case r == ' ' || r == '\t':
			flush()
		default:
			current.WriteRune(r)
			started = true
		}
	}
	if quote != 0 {
		return nil, fmt.Errorf("引号未闭合：%s", stage)
	}
	flush()
	return words, nil
}
