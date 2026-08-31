package themis

import "testing"

// TestQuotedMetacharacterNotShellSyntax pins the boundary the quote-aware check
// moved: a metacharacter inside quotes is one character of one argv element and
// must be admitted, while the same character outside quotes still reaches for a
// command the allowlist refused and must not be.
//
// `grep -c 'SPEC\>'` is the case that prompted this. It was refused as a
// redirection, which no shell was ever going to perform, while the matching
// `\<` was admitted — the inconsistency is what made it a defect rather than
// conservatism.
func TestQuotedMetacharacterNotShellSyntax(t *testing.T) {
	admitted := []string{
		`grep -c 'SPEC\>' f.md`,
		`grep -c 'SPEC\<' f.md`,
		`grep -c 'a>b' f.md`,
		`grep -c 'a;b' f.md`,
		`grep -c 'a&b' f.md`,
		`awk '{print $1}' f.md`,
	}
	for _, command := range admitted {
		if err := CheckAllowed(command); err != nil {
			t.Errorf("CheckAllowed(%q) = %v, want nil", command, err)
		}
	}

	// Nothing below is inside quotes, so every one of them is still refused.
	// The relaxation is confined to quoted text and goes no further.
	refused := []string{
		`grep x f.md > out.txt`,
		`grep x f.md ; rm -rf y`,
		`grep x f.md & rm -rf y`,
		"grep x f.md `rm -rf y`",
		`grep -c $(rm -rf y) f.md`,
		`grep -c 'quoted' f.md > out.txt`,
	}
	for _, command := range refused {
		if err := CheckAllowed(command); err == nil {
			t.Errorf("CheckAllowed(%q) = nil, want refusal", command)
		}
	}
}

// TestUnsafeArgRule fixes the measured rule in place. Every case is one of the
// sixteen patterns run through both bash and this package while the rule was
// being characterised, and the want column records which side that comparison
// came down on. The rule may only be widened by adding rows here, which is the
// point: it is the sole guard the precise-refusal approach has.
func TestUnsafeArgRule(t *testing.T) {
	cases := []struct {
		name    string
		command string
		refuse  bool
	}{
		{"plain", `grep -c 'SPEC' f.md`, false},
		{"backslash word start", `grep -c '\<SPEC' f.md`, false},
		{"backslash alternation", `grep -c 'S\|P' f.md`, false},
		{"backslash alone", `grep -c '\|' f.md`, false},
		{"star without backslash", `grep -c 'SPEC*' f.md`, false},
		{"star without backslash again", `grep -c '节.*SPEC' f.md`, false},
		{"backslash parens", `grep -c '\(SPEC\)' f.md`, true},
		{"backslash braces", `grep -c 'S\{1\}PEC' f.md`, true},
		{"backslash parens and alternation", `grep -c '\(S\)\|P' f.md`, true},
		{"backslash alternation with star", `grep -c 'S\|P.*节' f.md`, true},
		{"backslash alternation with bracket", `grep -c 'S\|P[A-Z]' f.md`, true},
		{"backslash alternation with question", `grep -c 'S\|P?' f.md`, true},
		{"backslash question", `grep -c 'x\?y' f.md`, true},
		{"backslash alternation with close paren", `grep -c 'S\|P)' f.md`, true},
		{"backslash alternation with star again", `grep -c 'SPEC\|节.*的' f.md`, true},
		{"backslash word end", `grep -c 'SPEC\>' f.md`, false},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			err := CheckTransportable(c.command)
			if c.refuse && err == nil {
				t.Errorf("CheckTransportable(%q) = nil, want refusal", c.command)
			}
			if !c.refuse && err != nil {
				t.Errorf("CheckTransportable(%q) = %v, want nil", c.command, err)
			}
		})
	}
}

// TestUnsafeArgRuleMessage checks the refusal says which argument and which
// character tripped it. A refusal that only says "no" sends the author back to
// guessing, and not guessing is what this package is for.
func TestUnsafeArgRuleMessage(t *testing.T) {
	err := CheckTransportable(`grep -c '\(SPEC\)' f.md`)
	if err == nil {
		t.Fatal("CheckTransportable = nil, want refusal")
	}
	for _, want := range []string{"无法可靠执行", `\(SPEC\)`, "手工实跑"} {
		if !contains(err.Error(), want) {
			t.Errorf("refusal %q does not mention %q", err.Error(), want)
		}
	}
}

// TestTableEscape covers the Markdown rule that a literal `|` inside a table
// cell is written `\|`. Read literally, the escaped pipe left `wc -l` unstarted
// and `grep -r` waiting on stdin, so the run failed and then hung.
func TestTableEscape(t *testing.T) {
	row := "| 输出行数 | `grep -c 'SPEC' f.md \\| wc -l` → `1` |"
	assertion, ok := ParseAssertion(row)
	if !ok {
		t.Fatalf("ParseAssertion(%q) reported no assertion", row)
	}
	want := `grep -c 'SPEC' f.md | wc -l`
	if assertion.Command != want {
		t.Errorf("command = %q, want %q", assertion.Command, want)
	}

	// Outside a table the same two characters are the author's own, and
	// rewriting them would run a command nobody wrote.
	plain := "`grep -c 'S\\|P' f.md` → `6`"
	assertion, ok = ParseAssertion(plain)
	if !ok {
		t.Fatalf("ParseAssertion(%q) reported no assertion", plain)
	}
	if assertion.Command != `grep -c 'S\|P' f.md` {
		t.Errorf("command = %q, want the line unchanged", assertion.Command)
	}
}

func contains(haystack, needle string) bool {
	return len(needle) == 0 || indexOf(haystack, needle) >= 0
}

func indexOf(haystack, needle string) int {
	for i := 0; i+len(needle) <= len(haystack); i++ {
		if haystack[i:i+len(needle)] == needle {
			return i
		}
	}
	return -1
}
