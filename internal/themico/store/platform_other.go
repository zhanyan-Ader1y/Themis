//go:build !windows && !linux

package store

import (
	"fmt"
	"os"
)

func renameNoReplace(source, target string) error {
	return fmt.Errorf("atomic no-replace directory rename is unavailable on this platform")
}

func syncDir(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("open directory for sync %s: %w", path, err)
	}
	defer directory.Close()
	if err := directory.Sync(); err != nil {
		return fmt.Errorf("sync directory %s: %w", path, err)
	}
	return nil
}
