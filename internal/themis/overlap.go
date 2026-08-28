package themis

import (
	"fmt"
	"sort"
	"strings"
)

// Finding is one stretch of text that appears verbatim in two control-plane
// files. Filtered names the rule that classified it as a legitimate overlap,
// and is empty for findings that survived filtering.
type Finding struct {
	Fragment string
	From     string
	To       string
	Filtered string
}

// lineMarkers are the Markdown prefixes stripped before comparison. Two list
// items that share only their bullet are not restating each other.
const lineMarkers = "#>*|` -\t"

// MaximalCommon returns every stretch of at least threshold runes that appears
// in both texts, each extended as far right as it will go.
//
// Extension is what makes the output readable rather than merely correct. A
// scan that reports fixed-width windows reports the same sentence dozens of
// times at one-rune offsets: on the real control plane that was 153 fragments
// against 26 after extension. Merging afterwards does not help — every window
// is the same length, so none contains another.
func MaximalCommon(source, target string, threshold int) []string {
	var found []string
	seen := map[string]bool{}

	for _, line := range strings.Split(source, "\n") {
		runes := []rune(strings.TrimLeft(line, lineMarkers))
		for i := 0; i+threshold <= len(runes); {
			if !strings.Contains(target, string(runes[i:i+threshold])) {
				i++
				continue
			}
			// Extend right while the longer fragment still appears in target.
			end := i + threshold
			for end < len(runes) && strings.Contains(target, string(runes[i:end+1])) {
				end++
			}
			fragment := string(runes[i:end])
			if !seen[fragment] {
				seen[fragment] = true
				found = append(found, fragment)
			}
			// Resume past this maximal run rather than one rune along, so the
			// same sentence is not re-reported from every interior offset.
			i = end - threshold + 1
			if i <= 0 {
				i = 1
			}
		}
	}

	sort.Slice(found, func(a, b int) bool {
		return len([]rune(found[a])) > len([]rune(found[b]))
	})
	return found
}

// legitimateRules classify overlaps that two files are entitled to share.
// They are heuristics drawn from measuring the real control plane, not
// theorems — see Report, which prints them so a wrong exclusion stays visible.
var legitimateRules = []struct {
	name  string
	match func(string) bool
}{
	{"清单式并列", func(s string) bool { return strings.Contains(s, " / ") && !hasSentencePunct(s) }},
	{"节点名并列", func(s string) bool { return strings.Contains(s, "、") && !hasSentencePunct(s) }},
	{"路径与编号", func(s string) bool {
		t := strings.TrimSpace(s)
		return strings.HasPrefix(t, ".themis") || strings.HasPrefix(t, "SPEC-") ||
			strings.HasPrefix(t, "`") || strings.Contains(t, ".themis/")
	}},
	{"指向另一文件", isPointer},
}

// isPointer recognises a fragment whose whole content is a pointer to another
// file — "判据与判定者见 `rules.md` §12。" is exactly what the citation rule
// requires, and it recurs across files precisely because both correctly point
// at the same place. Flagging it would penalise compliance.
//
// The qualifier is that the fragment must name a file and say "see": prose
// that merely mentions a filename is not a pointer.
func isPointer(s string) bool {
	if !strings.Contains(s, "见 ") && !strings.Contains(s, "见`") {
		return false
	}
	return strings.Contains(s, ".md`") || strings.Contains(s, ".md ")
}

// SameFinding reports whether two fragments are the same overlap seen from
// both directions. The two passes extend to slightly different boundaries —
// one may keep a leading "**" the other trimmed — so equality is too strict.
func SameFinding(a, b string) bool {
	x, y := normalizeFragment(a), normalizeFragment(b)
	if x == y {
		return true
	}
	return strings.Contains(x, y) || strings.Contains(y, x)
}

func normalizeFragment(s string) string {
	return strings.TrimSpace(strings.Trim(strings.TrimSpace(s), "*` 、，。；:："))
}

// sentencePunct marks a fragment as prose rather than a bare enumeration.
// Both files may list the same node names; neither may restate the other's
// criterion. The separator alone cannot tell them apart — the violation this
// requirement was opened to find, "只判三项：结构存在、可构建、既有测试（若有）
// 无回归", is a sentence that happens to contain enumeration marks.
var sentencePunct = []string{"：", "（", "）", "。", "，", "；", ":"}

func hasSentencePunct(s string) bool {
	for _, p := range sentencePunct {
		if strings.Contains(s, p) {
			return true
		}
	}
	return false
}

// IsLegitimate reports whether a fragment is an overlap two files may share.
func IsLegitimate(fragment string) bool {
	return LegitimateRule(fragment) != ""
}

// LegitimateRule names the rule that classifies a fragment as legitimate, or
// returns "" when none does.
func LegitimateRule(fragment string) string {
	for _, rule := range legitimateRules {
		if rule.match(fragment) {
			return rule.name
		}
	}
	return ""
}

// Report renders findings for a human reader: the unfiltered ones first,
// then which rules ran and how much each removed.
//
// Printing the rules is not decoration. They are heuristics, so a fragment
// that is both a list and a restatement gets wrongly excluded; naming them
// with counts is what lets a reader notice that. A silent filter would answer
// one blind spot with another.
func Report(findings []Finding) string {
	var out strings.Builder
	excluded := map[string]int{}
	kept := 0

	for _, f := range findings {
		if f.Filtered != "" {
			excluded[f.Filtered]++
			continue
		}
		kept++
		fmt.Fprintf(&out, "%s → %s：%d 字\n  %s\n\n", f.From, f.To, len([]rune(f.Fragment)), f.Fragment)
	}

	if kept == 0 {
		out.WriteString("未发现需人工复核的重合片段。\n\n")
	} else {
		fmt.Fprintf(&out, "共 %d 处待人工复核。\n\n", kept)
	}

	out.WriteString("已应用的排除规则（**经验规则，非完备判据**）：\n")
	for _, rule := range legitimateRules {
		fmt.Fprintf(&out, "  %-12s 排除 %d 处\n", rule.name, excluded[rule.name])
	}
	out.WriteString("\n若某处重合既符合上列形态、又确实是复述，它会被误排除——**规则与计数印在此处，正是为使这种情况可被察觉**。\n")

	return out.String()
}
