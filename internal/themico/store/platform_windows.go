//go:build windows

package store

import (
	"errors"
	"fmt"
	"os"
	"syscall"
	"unsafe"
)

var moveFileEx = syscall.NewLazyDLL("kernel32.dll").NewProc("MoveFileExW")

const moveFileWriteThrough = 0x8

func renameNoReplace(source, target string) error {
	sourceName, err := syscall.UTF16PtrFromString(source)
	if err != nil {
		return err
	}
	targetName, err := syscall.UTF16PtrFromString(target)
	if err != nil {
		return err
	}
	success, _, callErr := moveFileEx.Call(
		uintptr(unsafe.Pointer(sourceName)),
		uintptr(unsafe.Pointer(targetName)),
		moveFileWriteThrough,
	)
	if success == 0 {
		if errors.Is(callErr, syscall.ERROR_ALREADY_EXISTS) || errors.Is(callErr, syscall.ERROR_FILE_EXISTS) || errors.Is(callErr, syscall.ERROR_ACCESS_DENIED) {
			if _, statErr := os.Lstat(target); statErr == nil {
				return os.ErrExist
			}
		}
		return callErr
	}
	return nil
}

func syncDir(path string) error {
	name, err := syscall.UTF16PtrFromString(path)
	if err != nil {
		return fmt.Errorf("encode directory path %s: %w", path, err)
	}
	handle, err := syscall.CreateFile(
		name,
		syscall.GENERIC_WRITE,
		syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE|syscall.FILE_SHARE_DELETE,
		nil,
		syscall.OPEN_EXISTING,
		syscall.FILE_FLAG_BACKUP_SEMANTICS,
		0,
	)
	if err != nil {
		return fmt.Errorf("open directory for sync %s: %w", path, err)
	}
	defer syscall.CloseHandle(handle)
	if err := syscall.FlushFileBuffers(handle); err != nil {
		return fmt.Errorf("sync directory %s: %w", path, err)
	}
	return nil
}
