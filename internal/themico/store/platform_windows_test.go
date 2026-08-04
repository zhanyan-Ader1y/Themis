//go:build windows

package store

import (
	"os"
	"syscall"
	"testing"
	"unsafe"
)

func TestFileRenameInformationLayoutMatchesNativeArchitecture(t *testing.T) {
	var info fileRenameInformation
	pointerSize := unsafe.Sizeof(uintptr(0))
	architecture := "386"
	wantRootOffset := uintptr(4)
	wantLengthOffset := uintptr(8)
	wantNameOffset := uintptr(12)
	if pointerSize == 8 {
		architecture = "amd64"
		wantRootOffset = 8
		wantLengthOffset = 16
		wantNameOffset = 20
	}
	if got := unsafe.Offsetof(info.RootDirectory); got != wantRootOffset {
		t.Fatalf("RootDirectory offset on windows/%s: got %d want %d", architecture, got, wantRootOffset)
	}
	if got := unsafe.Offsetof(info.FileNameLength); got != wantLengthOffset {
		t.Fatalf("FileNameLength offset on windows/%s: got %d want %d", architecture, got, wantLengthOffset)
	}
	if got := unsafe.Offsetof(info.FileName); got != wantNameOffset {
		t.Fatalf("FileName offset on windows/%s: got %d want %d", architecture, got, wantNameOffset)
	}
	wantSize := alignUp(wantNameOffset+unsafe.Sizeof(info.FileName), pointerSize)
	if got := unsafe.Sizeof(info); got != wantSize {
		t.Fatalf("structure size on windows/%s: got %d want %d", architecture, got, wantSize)
	}
}

func TestOpenDirectoryForSyncRelativeToVerifiedHandle(t *testing.T) {
	root, err := os.OpenRoot(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer root.Close()
	directory, err := root.Open(".")
	if err != nil {
		t.Fatal(err)
	}
	defer directory.Close()

	handle, err := openDirectoryForSync(syscall.Handle(directory.Fd()), ".")
	if err != nil {
		t.Fatal(err)
	}
	defer syscall.CloseHandle(handle)
	if err := syscall.FlushFileBuffers(handle); err != nil {
		t.Fatal(err)
	}
}

func TestSyncRootDirCurrentObjectDoesNotUseRootName(t *testing.T) {
	rootPath := t.TempDir()
	root, err := os.OpenRoot(rootPath)
	if err != nil {
		t.Fatal(err)
	}
	defer root.Close()
	if err := syncRootDir(root, "."); err != nil {
		t.Fatal(err)
	}
}

func alignUp(value, alignment uintptr) uintptr {
	return (value + alignment - 1) &^ (alignment - 1)
}
