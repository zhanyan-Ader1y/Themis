package validate

import (
	"strings"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

// checkMarkdown verifies the fixed Chinese section contract for one knowledge type.
func checkMarkdown(content []byte, headings []string) []result.Issue {
	issues := make([]result.Issue, 0)
	text := string(content)
	if strings.HasPrefix(strings.TrimLeft(text, "\uFEFF"), "---") {
		issues = append(issues, issue("markdown.frontmatter_forbidden", "content.md", "L3 must not start with YAML frontmatter"))
		return issues
	}

	var h1 int
	seen := make(map[string]int, len(headings))
	order := make([]string, 0, len(headings))
	for index, line := range strings.Split(text, "\n") {
		trimmed := strings.TrimRight(line, "\r")
		switch {
		case strings.HasPrefix(trimmed, "# "):
			h1++
		case strings.HasPrefix(trimmed, "## "):
			title := strings.TrimSpace(strings.TrimPrefix(trimmed, "## "))
			seen[title] = index
			order = append(order, title)
		}
	}
	if h1 != 1 {
		issues = append(issues, issue("markdown.missing_h1", "content.md", "L3 must contain exactly one H1"))
	}

	expected := make(map[string]struct{}, len(headings))
	for _, heading := range headings {
		expected[heading] = struct{}{}
		if _, ok := seen[heading]; !ok {
			issues = append(issues, issue("markdown.missing_heading", "content.md#"+heading, "required H2 is missing"))
		}
	}
	for _, title := range order {
		if _, ok := expected[title]; !ok {
			issues = append(issues, issue("markdown.unknown_heading", "content.md#"+title, "H2 is not part of this knowledge type"))
		}
	}

	previous := -1
	for _, heading := range headings {
		line, ok := seen[heading]
		if !ok {
			continue
		}
		if line < previous {
			issues = append(issues, issue("markdown.heading_order", "content.md#"+heading, "required H2 appears out of order"))
		}
		previous = line
	}
	return issues
}
