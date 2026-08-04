package store

import (
	"fmt"
	"path/filepath"
	"strings"
)

func validateImmutablePath(slashPath string) (string, error) {
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

	return filepath.FromSlash(slashPath), nil
}

func hasWindowsVolume(path string) bool {
	return len(path) >= 2 && ((path[0] >= 'a' && path[0] <= 'z') || (path[0] >= 'A' && path[0] <= 'Z')) && path[1] == ':'
}

func validationError(message string, cause error) error {
	if cause == nil {
		return fmt.Errorf("%w: %s", ErrValidation, message)
	}
	return fmt.Errorf("%w: %s: %v", ErrValidation, message, cause)
}
