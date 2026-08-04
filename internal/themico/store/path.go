package store

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func validateImmutablePath(storeRoot, slashPath string) (string, error) {
	if slashPath == "" {
		return "", validationError("immutable path is empty", nil)
	}
	if strings.Contains(slashPath, `\`) {
		return "", validationError("immutable path contains a backslash", nil)
	}
	if strings.HasPrefix(slashPath, "/") || filepath.IsAbs(slashPath) || hasWindowsVolume(slashPath) {
		return "", validationError("immutable path must be relative", nil)
	}
	segments := strings.Split(slashPath, "/")
	for _, segment := range segments {
		if segment == "" || segment == "." || segment == ".." {
			return "", validationError("immutable path contains an unsafe segment", nil)
		}
	}
	allowedRoots := map[string]struct{}{
		"candidates": {}, "records": {}, "projections": {}, "preparations": {}, "assessments": {}, "approvals": {},
	}
	if _, ok := allowedRoots[segments[0]]; !ok || len(segments) == 1 {
		return "", validationError("immutable path targets an unsupported or directory path", nil)
	}

	if segments[0] == "projections" {
		if len(segments) != 4 || (segments[3] != "l1.json" && segments[3] != "l2.json") {
			return "", validationError("projection path does not match the fixed layout", nil)
		}
	}
	if segments[0] == "records" {
		if len(segments) != 5 || segments[2] != "revisions" || (segments[4] != "record.json" && segments[4] != "content.md") {
			return "", validationError("record path does not match the fixed layout", nil)
		}
	}
	if segments[0] == "candidates" {
		if len(segments) != 5 || segments[2] != "revisions" || (segments[4] != "candidate.json" && segments[4] != "content.md") {
			return "", validationError("candidate path does not match the fixed layout", nil)
		}
	}
	if segments[0] == "preparations" && (len(segments) != 3 || segments[2] != "prepare.json") {
		return "", validationError("preparation path does not match the fixed layout", nil)
	}
	if (segments[0] == "assessments" || segments[0] == "approvals") && len(segments) != 2 {
		return "", validationError("artifact path does not match the fixed layout", nil)
	}

	storeRoot = filepath.Clean(storeRoot)
	candidate := filepath.Join(storeRoot, filepath.FromSlash(slashPath))
	if !pathWithin(storeRoot, candidate) {
		return "", validationError("immutable path escapes store root", nil)
	}
	if err := rejectExistingLinkEscape(storeRoot, candidate); err != nil {
		return "", err
	}
	if info, err := os.Lstat(candidate); err == nil {
		if info.IsDir() {
			return "", validationError("immutable target is a directory", nil)
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", validationError("inspect immutable target", err)
	}
	return candidate, nil
}

func hasWindowsVolume(path string) bool {
	return len(path) >= 2 && ((path[0] >= 'a' && path[0] <= 'z') || (path[0] >= 'A' && path[0] <= 'Z')) && path[1] == ':'
}

func rejectExistingLinkEscape(storeRoot, target string) error {
	relative, err := filepath.Rel(storeRoot, target)
	if err != nil {
		return validationError("resolve immutable target", err)
	}
	current := storeRoot
	for _, segment := range strings.Split(relative, string(filepath.Separator)) {
		current = filepath.Join(current, segment)
		info, err := os.Lstat(current)
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		if err != nil {
			return validationError("inspect immutable path", err)
		}
		if info.Mode()&os.ModeSymlink == 0 {
			continue
		}
		resolved, err := filepath.EvalSymlinks(current)
		if err != nil {
			return validationError("resolve immutable symlink", err)
		}
		if !pathWithin(storeRoot, resolved) {
			return validationError("immutable path escapes through symlink", nil)
		}
	}
	return nil
}

func pathWithin(root, candidate string) bool {
	relative, err := filepath.Rel(root, candidate)
	return err == nil && relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)) && !filepath.IsAbs(relative)
}

func ensureNoLinkComponents(storeRoot, parent string) error {
	if err := rejectExistingLinkEscape(storeRoot, parent); err != nil {
		return err
	}
	resolvedRoot, err := filepath.EvalSymlinks(storeRoot)
	if err != nil {
		return validationError("resolve store root", err)
	}
	resolvedParent, err := filepath.EvalSymlinks(parent)
	if err != nil {
		return validationError("resolve immutable parent", err)
	}
	if !pathWithin(resolvedRoot, resolvedParent) && filepath.Clean(resolvedRoot) != filepath.Clean(resolvedParent) {
		return validationError("immutable parent escapes store root", nil)
	}
	return nil
}

func validationError(message string, cause error) error {
	if cause == nil {
		return fmt.Errorf("%w: %s", ErrValidation, message)
	}
	return fmt.Errorf("%w: %s: %v", ErrValidation, message, cause)
}
