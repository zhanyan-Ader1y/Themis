//go:build linux

package store

import (
	"errors"
	"fmt"
	"os"
	"runtime"
	"syscall"
	"unsafe"
)

const renameNoReplaceFlag = 1

func renameRootNoReplace(parent *os.Root, source, target string) error {
	directory, err := parent.Open(".")
	if err != nil {
		return fmt.Errorf("open publication parent: %w", err)
	}
	defer directory.Close()
	fd := int(directory.Fd())
	oldPath, err := syscall.BytePtrFromString(source)
	if err != nil {
		return err
	}
	newPath, err := syscall.BytePtrFromString(target)
	if err != nil {
		return err
	}
	_, _, errno := syscall.Syscall6(
		renameat2Trap(),
		uintptr(fd),
		uintptr(unsafe.Pointer(oldPath)),
		uintptr(fd),
		uintptr(unsafe.Pointer(newPath)),
		renameNoReplaceFlag,
		0,
	)
	runtime.KeepAlive(directory)
	if errno == 0 {
		return nil
	}
	if errors.Is(errno, syscall.EEXIST) {
		return os.ErrExist
	}
	return errno
}

func renameat2Trap() uintptr {
	switch runtime.GOARCH {
	case "386":
		return 353
	case "amd64":
		return 316
	case "arm":
		return 382
	case "arm64", "riscv64", "loong64":
		return 276
	case "mips":
		return 4351
	case "mipsle":
		return 4351
	case "mips64", "mips64le":
		return 5311
	case "ppc64", "ppc64le":
		return 357
	case "s390x":
		return 347
	default:
		panic("unsupported Linux architecture for renameat2")
	}
}

func syncRootDir(parent *os.Root, path string) error {
	directory, err := parent.Open(path)
	if err != nil {
		return fmt.Errorf("open directory for sync %s: %w", path, err)
	}
	defer directory.Close()
	if err := directory.Sync(); err != nil {
		return fmt.Errorf("sync directory %s: %w", path, err)
	}
	return nil
}
