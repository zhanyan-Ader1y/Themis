// Package cli exposes the assertion checker as the "themis" command line
// surface. One invocation checks one file: every line holding an assertion is
// re-run and compared against the value written beside it.
//
// A passing run prints nothing about the lines it checked. Silence is the pass
// signal because artifacts hold hundreds of lines and a per-line "ok" would
// bury the one line that matters.
package cli

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/zhanyan-Ader1y/Themis/internal/themis"
)

const usage = `themis —— 校验工件里的数字与存在性断言

用法：
  themis verify <文件>   重跑该文件里每条断言的命令，比对其记录的值
  themis overlap <目录>  找出目录内各 .md 之间逐字重合的片段，供人工复核

断言形态见 .themis/spec/template.md「断言形态」一节。不合形态的行会被跳过。
`

// Run executes one invocation and returns the process exit code: 0 when every
// assertion in the file holds, non-zero otherwise.
func Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		fmt.Fprint(stderr, usage)
		return 2
	}

	switch args[0] {
	case "verify":
		if len(args) != 2 {
			fmt.Fprint(stderr, usage)
			return 2
		}
		return runVerify(args[1], stdout, stderr)
	case "overlap":
		if len(args) != 2 {
			fmt.Fprint(stderr, usage)
			return 2
		}
		return runOverlap(args[1], stdout, stderr)
	case "help", "-h", "--help":
		fmt.Fprint(stdout, usage)
		return 0
	default:
		fmt.Fprintf(stderr, "未知命令 %q\n\n", args[0])
		fmt.Fprint(stderr, usage)
		return 2
	}
}

// runVerify checks one file, reporting every failure it finds rather than
// stopping at the first. An author fixing a batch of stale numbers wants the
// whole list, not one item per run.
func runVerify(path string, stdout, stderr io.Writer) int {
	file, err := os.Open(path)
	if err != nil {
		fmt.Fprintf(stderr, "打开文件失败：%v\n", err)
		return 1
	}
	defer file.Close()

	// Commands are written relative to the repository root, since that is where
	// their author ran them.
	root, err := repositoryRoot(path)
	if err != nil {
		fmt.Fprintf(stderr, "定位仓库根失败：%v\n", err)
		return 1
	}

	failures := 0
	scanner := bufio.NewScanner(file)
	// Artifact lines can exceed bufio's default 64KB ceiling; a truncated line
	// would silently drop the assertion on it.
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	inFence := false
	for lineNumber := 1; scanner.Scan(); lineNumber++ {
		line := scanner.Text()

		// Fenced blocks hold examples and quoted output, not live claims. The
		// template that defines the assertion form illustrates it inside a
		// fence; re-running those illustrations reports a failure no edit can
		// fix, since their numbers are frozen by the example.
		if strings.HasPrefix(strings.TrimSpace(line), "```") {
			inFence = !inFence
			continue
		}
		if inFence {
			continue
		}

		if _, ok := themis.ParseAssertion(line); !ok {
			continue
		}

		result, err := themis.VerifyLine(line, root)
		if err != nil {
			failures++
			fmt.Fprintf(stdout, "%s:%d：%v\n", path, lineNumber, err)
			continue
		}
		if !result.OK {
			failures++
			fmt.Fprintf(stdout, "%s:%d：命令 `%s` 实跑得到 %q，文件里写的是 %q\n",
				path, lineNumber, result.Assertion.Command, result.Got, result.Want)
		}
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(stderr, "读取文件失败：%v\n", err)
		return 1
	}

	if failures > 0 {
		fmt.Fprintf(stdout, "\n%d 条断言与实跑结果不一致。\n", failures)
		return 1
	}
	return 0
}

// repositoryRoot walks up from the file until it finds the directory holding
// .git, falling back to the working directory when there is none.
func repositoryRoot(path string) (string, error) {
	dir, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	dir = filepath.Dir(dir)

	for {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return os.Getwd()
		}
		dir = parent
	}
}

// runOverlap compares every ordered pair of Markdown files in dir and reports
// stretches of text that appear verbatim in both.
//
// It always exits 0 when it completes. What it finds is a lead for a human,
// not a determinate error: legitimate overlap can never be filtered to zero
// (both files must name the same nodes), so blocking on it would make the
// check something to route around rather than read.
func runOverlap(dir string, stdout, stderr io.Writer) int {
	entries, err := os.ReadDir(dir)
	if err != nil {
		fmt.Fprintf(stderr, "读取目录失败：%v\n", err)
		return 1
	}

	contents := map[string]string{}
	var names []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") {
			continue
		}
		body, err := os.ReadFile(filepath.Join(dir, e.Name()))
		if err != nil {
			fmt.Fprintf(stderr, "读取 %s 失败：%v\n", e.Name(), err)
			return 1
		}
		contents[e.Name()] = string(body)
		names = append(names, e.Name())
	}
	if len(names) < 2 {
		fmt.Fprintf(stderr, "%s 下不足两份 .md 文件，无从比对\n", dir)
		return 1
	}
	sort.Strings(names)

	// Report each fragment once, against the first pair that produced it: the
	// same sentence shared by two files shows up from both directions.
	var findings []themis.Finding
	for _, from := range names {
		for _, to := range names {
			if from == to {
				continue
			}
			for _, fragment := range themis.MaximalCommon(contents[from], contents[to], overlapThreshold) {
				if alreadyFound(findings, fragment) {
					continue
				}

				findings = append(findings, themis.Finding{
					Fragment: fragment,
					From:     from,
					To:       to,
					Filtered: themis.LegitimateRule(fragment),
				})
			}
		}
	}

	fmt.Fprint(stdout, themis.Report(findings))
	return 0
}

// overlapThreshold is the shortest run of shared runes worth reporting.
// Below it, recurrence is ordinary rather than evidence of restatement.
const overlapThreshold = 20

// alreadyFound reports whether this overlap was already recorded, including
// from the opposite direction where extension may have landed on slightly
// different boundaries.
func alreadyFound(findings []themis.Finding, fragment string) bool {
	for _, f := range findings {
		if themis.SameFinding(f.Fragment, fragment) {
			return true
		}
	}
	return false
}
