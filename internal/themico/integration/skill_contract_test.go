// Package integration proves the public themico Skill/reference tree matches
// the first-usable-delivery contract: the Skill directory holds only
// SKILL.md, the reference tree holds exactly the operation/common/type files
// this plan defines, only SKILL.md carries YAML frontmatter, no deferred
// operation reference exists, and every type factory's l3.md contains the
// exact fixed headings the model registry declares.
package integration

import (
	"bytes"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"sort"
	"strings"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

func TestSkillTreeMatchesFirstUsableDeliveryContract(t *testing.T) {
	repository := repositoryRoot(t)
	skill := filepath.Join(repository, "templates", ".themis", "skills", "themico", "SKILL.md")
	references := filepath.Join(repository, "templates", ".themico", "core", "references")

	if entries, err := os.ReadDir(filepath.Dir(skill)); err != nil || len(entries) != 1 {
		t.Fatalf("skill directory must hold only SKILL.md: %v %v", entries, err)
	}

	operations := []string{
		"create-candidate", "revise-candidate", "confirm-type", "validate",
		"prepare", "publish", "query", "inspect",
	}
	got := markdownNames(t, filepath.Join(references, "operations"))
	if !reflect.DeepEqual(got, sorted(operations)) {
		t.Fatalf("operations=%v want %v", got, sorted(operations))
	}

	commons := []string{
		"operation-contract", "result-contract", "governance",
		"knowledge-record", "l1-discovery", "type-registry",
	}
	if got := markdownNames(t, filepath.Join(references, "common")); !reflect.DeepEqual(got, sorted(commons)) {
		t.Fatalf("common=%v want %v", got, sorted(commons))
	}

	for _, factory := range []string{"design-decision", "development-standard", "development-experience"} {
		directory := filepath.Join(references, "types", factory)
		want := sorted([]string{"factory", "l2", "l3", "semantic-check"})
		if got := markdownNames(t, directory); !reflect.DeepEqual(got, want) {
			t.Fatalf("%s=%v want %v", factory, got, want)
		}
	}

	assertOnlySkillHasFrontmatter(t, skill, references)
	assertNoDeferredOperationReference(t, references)
}

func TestFactoryL3ReferencesMatchRegistryHeadings(t *testing.T) {
	references := filepath.Join(repositoryRoot(t), "templates", ".themico", "core", "references", "types")
	for _, factory := range model.Factories() {
		directory := map[model.KnowledgeType]string{
			model.TypeDesignDecision:        "design-decision",
			model.TypeDevelopmentStandard:   "development-standard",
			model.TypeDevelopmentExperience: "development-experience",
		}[factory.Type]

		content, err := os.ReadFile(filepath.Join(references, directory, "l3.md"))
		if err != nil {
			t.Fatal(err)
		}
		for _, heading := range factory.L3Headings {
			if !bytes.Contains(content, []byte("## "+heading)) {
				t.Fatalf("%s l3.md is missing heading %q", directory, heading)
			}
		}
	}
}

// ---- shared helpers ----

// repositoryRoot locates the module root by walking up from this test
// file's own location until a go.mod is found, so the test does not depend
// on the process working directory.
func repositoryRoot(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("cannot determine test file location")
	}
	dir := filepath.Dir(file)
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatalf("go.mod not found above %s", file)
		}
		dir = parent
	}
}

// markdownNames returns the sorted, extension-stripped names of every entry
// directly inside dir. It fails the test if dir holds anything other than
// plain ".md" files, so an accidental subdirectory or non-Markdown file is
// caught the same way a missing or extra reference would be.
func markdownNames(t *testing.T, dir string) []string {
	t.Helper()
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatalf("read %s: %v", dir, err)
	}
	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			t.Fatalf("unexpected directory %s in %s", entry.Name(), dir)
		}
		if !strings.HasSuffix(entry.Name(), ".md") {
			t.Fatalf("unexpected non-markdown entry %s in %s", entry.Name(), dir)
		}
		names = append(names, strings.TrimSuffix(entry.Name(), ".md"))
	}
	return sorted(names)
}

func sorted(values []string) []string {
	out := append([]string(nil), values...)
	sort.Strings(out)
	return out
}

// assertOnlySkillHasFrontmatter walks skill and every Markdown file under
// references and fails if any file other than skill starts with a YAML
// frontmatter fence ("---" as its first line).
func assertOnlySkillHasFrontmatter(t *testing.T, skill, references string) {
	t.Helper()
	if !hasFrontmatter(t, skill) {
		t.Fatalf("%s must carry the host-discovery frontmatter", skill)
	}
	err := filepath.WalkDir(references, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() || !strings.HasSuffix(path, ".md") {
			return nil
		}
		if hasFrontmatter(t, path) {
			t.Fatalf("%s must not carry YAML frontmatter", path)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walk %s: %v", references, err)
	}
}

func hasFrontmatter(t *testing.T, path string) bool {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	return bytes.HasPrefix(data, []byte("---\n")) || bytes.HasPrefix(data, []byte("---\r\n"))
}

// assertNoDeferredOperationReference fails if operations/ contains any file
// naming a capability this plan explicitly defers to a later, independently
// approved plan.
func assertNoDeferredOperationReference(t *testing.T, references string) {
	t.Helper()
	deferred := []string{
		"supersede", "deprecate", "archive", "rebuild",
		"verify-projection", "create-derived-candidate",
	}
	for _, name := range deferred {
		path := filepath.Join(references, "operations", name+".md")
		if _, err := os.Stat(path); err == nil {
			t.Fatalf("deferred operation reference must not exist: %s", path)
		} else if !os.IsNotExist(err) {
			t.Fatalf("stat %s: %v", path, err)
		}
	}
}
