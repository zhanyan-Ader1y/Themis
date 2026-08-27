package themis

import (
	"fmt"
	"strings"
)

// Assertion is one numeric or existence claim recovered from a line of a spec
// artifact: the command that produced it, and the value written down as its
// result. RawOutput is set only for the three-segment form, where the author
// recorded the command's output separately from the conclusion drawn from it.
type Assertion struct {
	Command   string
	RawOutput string
	Want      string
}

// arrow separates the segments of an assertion. It is the full-width arrow
// used throughout the Chinese-language artifacts, not "->".
const arrow = "→"

// ParseAssertion recovers an assertion from a single line, reporting whether
// the line holds one at all.
//
// A line qualifies when it contains two or three backtick-delimited segments
// joined by arrows. Anything else — prose, a lone code span, an arrow used in
// a table — is not an assertion, and the caller is told so rather than given
// an error: artifacts are mostly prose, so non-assertions are the common case.
func ParseAssertion(line string) (Assertion, bool) {
	segments := backtickSegments(line)
	if len(segments) < 2 || len(segments) > 3 {
		return Assertion{}, false
	}

	// The segments must be joined by arrows to be one assertion rather than
	// several unrelated code spans that happen to share a line.
	for i := 0; i < len(segments)-1; i++ {
		between := line[segments[i].end:segments[i+1].start]
		if !strings.Contains(between, arrow) {
			return Assertion{}, false
		}
	}

	texts := make([]string, len(segments))
	for i, s := range segments {
		texts[i] = strings.TrimSpace(line[s.start:s.end])
	}

	// The shape alone admits documentation tables, whose rows pair two code
	// spans with an arrow: `task/basic.md` | 基础任务 → `### T-B<n>`. Requiring
	// the first segment to name a runnable command separates the two, and
	// reuses the execution allowlist so there is no second list to drift.
	if !looksLikeCommand(texts[0]) {
		return Assertion{}, false
	}

	if len(texts) == 2 {
		return Assertion{Command: texts[0], Want: texts[1]}, true
	}
	return Assertion{Command: texts[0], RawOutput: texts[1], Want: texts[2]}, true
}

// looksLikeCommand reports whether a segment's first word is plausibly a
// command name rather than a filename or a heading.
//
// It deliberately does NOT consult the allowlist. A conforming assertion that
// names a forbidden command (`rm -rf /` → `0`) must still be reported, because
// the approved ruling skips only lines that do not conform to the shape — and
// that one does. Folding the two cases together would let a refused command
// pass unmentioned, which is the opposite of what the allowlist is for.
func looksLikeCommand(segment string) bool {
	fields := strings.Fields(segment)
	if len(fields) == 0 {
		return false
	}
	first := fields[0]
	// A command name is a bare word: no path separators, no filename extension,
	// none of the markup that shows up in documentation tables. This is what
	// separates `wc` and `rm` from `task/basic.md`, `design.md`, and
	// `### T-B<n>`.
	if strings.ContainsAny(first, "/\\#<>|.") {
		return false
	}
	return len(fields) > 1 || allowed[first]
}

// span marks the content of one backtick-delimited segment, exclusive of the
// backticks themselves.
type span struct{ start, end int }

func backtickSegments(line string) []span {
	var segments []span
	for i := 0; i < len(line); {
		open := strings.IndexByte(line[i:], '`')
		if open < 0 {
			break
		}
		open += i
		close := strings.IndexByte(line[open+1:], '`')
		if close < 0 {
			break // an unpaired backtick ends the scan
		}
		close += open + 1
		segments = append(segments, span{start: open + 1, end: close})
		i = close + 1
	}
	return segments
}

// allowed lists the commands this package will run. It is an allowlist rather
// than a denylist because the strings it guards come from Markdown files: a
// denylist would have to anticipate every way to cause damage, while this list
// only has to enumerate the read-only queries assertions actually use.
//
// `git` is admitted as a whole. That is the widest entry here — `git` has
// subcommands that write — and it was accepted knowingly, because assertions
// about repository history have no narrower form available.
var allowed = map[string]bool{
	"grep": true,
	"wc":   true,
	"find": true,
	"ls":   true,
	"git":  true,
	"awk":  true,
	"sed":  true,
	"test": true,
	"cat":  true,
	"head": true,
	"tail": true,
	"comm": true,
	"sort": true,
	"uniq": true,
	"diff": true,
}

// shellMetacharacters are refused outright. This package never hands a command
// to a shell, so these would not do what their author intended even if they
// were admitted — and each is a way to reach a command the allowlist rejected.
// `<` is absent deliberately: input redirection is interpreted by this package
// itself, since assertions commonly read a file that way.
// `$` alone is absent deliberately: `awk '{print $1}'` is a legitimate
// read-only assertion, and banning the character outright would reject it
// while `$(` — the form that reaches another command — stays covered.
var shellMetacharacters = []string{">", "&", ";", "$(", "`"}

// CheckAllowed reports whether a command string may be run: every stage of a
// pipeline must name an allowed command, and no stage may contain shell
// syntax this package does not itself interpret.
//
// Checking every stage matters because only the first word of the whole string
// looks like the command — in `grep x f.md | rm -rf y` the dangerous half is
// the one a first-word check never sees.
func CheckAllowed(command string) error {
	for _, meta := range shellMetacharacters {
		if strings.Contains(command, meta) {
			return fmt.Errorf("命令含本包不解释的 shell 语法 %q，拒绝执行：%s", meta, command)
		}
	}

	for _, stage := range splitPipeline(command) {
		fields, _, err := splitStage(stage)
		if err != nil {
			return err
		}
		if !allowed[fields[0]] {
			return fmt.Errorf("命令 %q 不在只读白名单内，拒绝执行：%s", fields[0], command)
		}
	}
	return nil
}

// splitPipeline splits on `|` outside quotes. Splitting on every `|` would cut
// `grep -cE 'a|b'` in half, and the fragment left behind then looks like a
// command nobody allowlisted — a false rejection found on a real artifact.
func splitPipeline(command string) []string {
	var (
		stages  []string
		current strings.Builder
		quote   rune
	)
	for _, r := range command {
		switch {
		case quote != 0:
			if r == quote {
				quote = 0
			}
			current.WriteRune(r)
		case r == '\'' || r == '"':
			quote = r
			current.WriteRune(r)
		case r == '|':
			stages = append(stages, current.String())
			current.Reset()
		default:
			current.WriteRune(r)
		}
	}
	return append(stages, current.String())
}
