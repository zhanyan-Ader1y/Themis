package themis

import (
	"strings"
	"testing"
)

// A sentence shared by two files must be reported once, at its full length —
// not as the dozens of overlapping fixed-width windows that a naive scan
// produces. Measured on the real control plane, the difference was 153
// fragments before extension versus 26 after; at 153 the output is unreadable,
// which makes this the difference between a usable tool and an ignored one.
func TestMaximalExtension(t *testing.T) {
	shared := "裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字"
	a := "前言部分。\n**三种写法的共同前提**：" + shared + "。这一条是把编号与普通数字分开的依据。\n结尾。"
	b := "另一份文件。\n" + shared + "。写成隔了文字的形式会取不到。\n结尾。"

	got := MaximalCommon(a, b, 20)

	if len(got) != 1 {
		t.Fatalf("MaximalCommon returned %d fragments, want 1:\n%q", len(got), got)
	}
	if !strings.Contains(got[0], shared) {
		t.Errorf("fragment does not span the whole shared sentence.\ngot:  %q\nwant it to contain: %q", got[0], shared)
	}
}

// Fragments shorter than the threshold are not evidence of restatement —
// short phrases recur for ordinary reasons.
func TestMaximalCommonRespectsThreshold(t *testing.T) {
	a := "判定者见 §7。"
	b := "判定者见 §9。"

	if got := MaximalCommon(a, b, 20); len(got) != 0 {
		t.Errorf("MaximalCommon reported %q for texts sharing fewer than 20 runes", got)
	}
}

// Markdown line markers are stripped before comparison: two list items that
// share only their leading "- **" are not restating each other.
func TestMaximalCommonStripsLineMarkers(t *testing.T) {
	a := "- **判据**：这是甲文件独有的一段判定内容，长度足够超过阈值上限。"
	b := "> **判据**：这是乙文件完全不同的另一段文字，长度也足够超过阈值。"

	for _, frag := range MaximalCommon(a, b, 20) {
		if strings.Contains(frag, "判据") && len([]rune(frag)) < 25 {
			t.Errorf("line markers produced a spurious hit: %q", frag)
		}
	}
}

// The control plane is Chinese; slicing by byte would cut characters in half
// and produce fragments that are not valid text.
func TestMaximalCommonSlicesByRune(t *testing.T) {
	shared := "承担的上层分解项与本步骤边界以及与其他步骤的关系三节齐备"
	a := "甲：" + shared + "。"
	b := "乙：" + shared + "。"

	got := MaximalCommon(a, b, 20)
	if len(got) == 0 {
		t.Fatal("MaximalCommon found nothing in identical Chinese text")
	}
	for _, frag := range got {
		if !utf8Valid(frag) {
			t.Errorf("fragment is not valid UTF-8, indicating byte slicing: %q", frag)
		}
	}
}

func utf8Valid(s string) bool {
	for _, r := range s {
		if r == '�' {
			return false
		}
	}
	return true
}

// Section-name lists and node-name enumerations legitimately appear in two
// files: both must name the same nodes. Prose restatement must survive the
// filter, or the tool hides the very thing it exists to find.
func TestLegitimateOverlap(t *testing.T) {
	legit := []string{
		"执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明",
		"verify/basic、verify/detail",
		".themis/workspace/spec/<spec-id>/",
	}
	for _, frag := range legit {
		if !IsLegitimate(frag) {
			t.Errorf("IsLegitimate(%q) = false, want true", frag)
		}
	}

	prose := []string{
		"只判三项：结构存在、可构建、既有测试（若有）无回归",
		"裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字",
	}
	for _, frag := range prose {
		if IsLegitimate(frag) {
			t.Errorf("IsLegitimate(%q) = true, want false — prose restatement must not be filtered", frag)
		}
	}
}

// The filter rules are heuristics, not theorems: a sentence that is both a
// list and a restatement would be wrongly excluded. Reporting which rules ran
// and how much each removed is what makes that case discoverable — a hidden
// filter would replace one blind spot with another.
func TestReportNamesItsFilterRules(t *testing.T) {
	report := Report([]Finding{
		{Fragment: "执行身份 / 断言与实际结果", From: "flow.md", To: "template.md", Filtered: "清单式并列"},
		{Fragment: "只判三项：结构存在、可构建", From: "flow.md", To: "rules.md"},
	})

	if !strings.Contains(report, "只判三项") {
		t.Error("report omits an unfiltered finding")
	}
	for _, want := range []string{"清单式并列", "排除"} {
		if !strings.Contains(report, want) {
			t.Errorf("report does not name its filter rules; missing %q\nreport:\n%s", want, report)
		}
	}
	if !strings.Contains(report, "经验规则") {
		t.Error("report does not warn that the filter rules are heuristics")
	}
}

// A pointer to another file is what the rule requires, not what it forbids:
// "判据与判定者见 `rules.md` §12。" is a location, and it recurs precisely
// because both files correctly point at the same place.
func TestPointersAreLegitimate(t *testing.T) {
	for _, frag := range []string{
		"判据与判定者见 `rules.md` §12。",
		"当前强制水平见 `README.md`；",
	} {
		if !IsLegitimate(frag) {
			t.Errorf("IsLegitimate(%q) = false; a pointer is compliant, not a violation", frag)
		}
	}
}

// The same sentence found from both directions is one finding, not two. The
// two passes extend to slightly different boundaries, so exact-string dedup
// misses it.
func TestNearDuplicateFragmentsCollapse(t *testing.T) {
	a := "**裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字。** 后续说明甲。"
	b := "裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字。** 后续说明乙。"

	forward := MaximalCommon(a, b, 20)
	backward := MaximalCommon(b, a, 20)
	if len(forward) == 0 || len(backward) == 0 {
		t.Fatal("expected a hit in both directions")
	}
	if !SameFinding(forward[0], backward[0]) {
		t.Errorf("SameFinding(%q, %q) = false; these are one overlap seen twice", forward[0], backward[0])
	}
}
