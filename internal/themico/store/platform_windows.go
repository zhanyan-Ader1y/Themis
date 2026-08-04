//go:build windows

package store

import (
	"fmt"
	"os"
	"runtime"
	"syscall"
	"unsafe"
)

var (
	ntOpenFile            = syscall.NewLazyDLL("ntdll.dll").NewProc("NtOpenFile")
	ntSetInformationFile  = syscall.NewLazyDLL("ntdll.dll").NewProc("NtSetInformationFile")
	reopenFile            = syscall.NewLazyDLL("kernel32.dll").NewProc("ReOpenFile")
	reopenDirectoryHandle = reopenDirectory
	flushDirectoryHandle  = syscall.FlushFileBuffers
)

const (
	deleteAccess               = 0x00010000
	genericWriteAccess         = 0x40000000
	synchronizeAccess          = 0x00100000
	fileOpenReparsePoint       = 0x00200000
	fileOpenForBackupIntent    = 0x00004000
	fileSynchronousIONonalert  = 0x00000020
	fileRenameInformationClass = 10
	objectCaseInsensitive      = 0x00000040
	statusSuccess              = 0x00000000
	statusObjectNameCollision  = 0xC0000035
	statusObjectNameNotFound   = 0xC0000034
	statusObjectPathNotFound   = 0xC000003A
	statusAccessDenied         = 0xC0000022
)

type ntUnicodeString struct {
	Length        uint16
	MaximumLength uint16
	Buffer        *uint16
}

type objectAttributes struct {
	Length             uint32
	RootDirectory      syscall.Handle
	ObjectName         *ntUnicodeString
	Attributes         uint32
	SecurityDescriptor unsafe.Pointer
	SecurityQoS        unsafe.Pointer
}

type ioStatusBlock struct {
	Status      uintptr
	Information uintptr
}

type fileRenameInformation struct {
	ReplaceIfExists bool
	RootDirectory   syscall.Handle
	FileNameLength  uint32
	FileName        [syscall.MAX_PATH]uint16
}

func renameRootNoReplace(parent *os.Root, source, target string) error {
	directory, err := parent.Open(".")
	if err != nil {
		return fmt.Errorf("open publication parent: %w", err)
	}
	defer directory.Close()
	parentHandle := syscall.Handle(directory.Fd())

	sourceName, sourceKeepAlive, err := newNTUnicodeString(source)
	if err != nil {
		return err
	}
	attributes := objectAttributes{
		Length:        uint32(unsafe.Sizeof(objectAttributes{})),
		RootDirectory: parentHandle,
		ObjectName:    sourceName,
		Attributes:    objectCaseInsensitive,
	}
	var sourceHandle syscall.Handle
	status, _, _ := ntOpenFile.Call(
		uintptr(unsafe.Pointer(&sourceHandle)),
		deleteAccess|synchronizeAccess,
		uintptr(unsafe.Pointer(&attributes)),
		uintptr(unsafe.Pointer(&ioStatusBlock{})),
		syscall.FILE_SHARE_DELETE|syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE,
		fileOpenReparsePoint|fileOpenForBackupIntent|fileSynchronousIONonalert,
	)
	runtime.KeepAlive(sourceKeepAlive)
	if uint32(status) != statusSuccess {
		return ntStatusError(uint32(status))
	}
	defer syscall.CloseHandle(sourceHandle)

	targetName, err := syscall.UTF16FromString(target)
	if err != nil {
		return err
	}
	if len(targetName) > syscall.MAX_PATH {
		return syscall.EINVAL
	}
	info := fileRenameInformation{RootDirectory: parentHandle}
	copy(info.FileName[:], targetName)
	info.FileNameLength = uint32((len(targetName) - 1) * 2)
	infoSize := unsafe.Offsetof(info.FileName) + uintptr(info.FileNameLength)
	status, _, _ = ntSetInformationFile.Call(
		uintptr(sourceHandle),
		uintptr(unsafe.Pointer(&ioStatusBlock{})),
		uintptr(unsafe.Pointer(&info)),
		infoSize,
		fileRenameInformationClass,
	)
	runtime.KeepAlive(directory)
	if uint32(status) == statusSuccess {
		return nil
	}
	if uint32(status) == statusObjectNameCollision {
		return os.ErrExist
	}
	return ntStatusError(uint32(status))
}

func newNTUnicodeString(value string) (*ntUnicodeString, []uint16, error) {
	encoded, err := syscall.UTF16FromString(value)
	if err != nil {
		return nil, nil, err
	}
	length := uint16(len(encoded) * 2)
	return &ntUnicodeString{
		Length:        length - 2,
		MaximumLength: length,
		Buffer:        &encoded[0],
	}, encoded, nil
}

func ntStatusError(status uint32) error {
	switch status {
	case statusObjectNameCollision:
		return os.ErrExist
	case statusObjectNameNotFound, statusObjectPathNotFound:
		return os.ErrNotExist
	case statusAccessDenied:
		return syscall.ERROR_ACCESS_DENIED
	default:
		return syscall.Errno(status)
	}
}

func syncRootDir(parent *os.Root, path string) error {
	directory, err := parent.Open(path)
	if err != nil {
		return fmt.Errorf("open directory for sync %s: %w", path, err)
	}
	defer directory.Close()

	handle, err := reopenDirectoryHandle(syscall.Handle(directory.Fd()))
	if err != nil {
		return fmt.Errorf("reopen directory for sync %s: %w", path, err)
	}
	defer syscall.CloseHandle(handle)
	if err := flushDirectoryHandle(handle); err != nil {
		return fmt.Errorf("sync directory %s: %w", path, err)
	}
	runtime.KeepAlive(directory)
	return nil
}

func reopenDirectory(handle syscall.Handle) (syscall.Handle, error) {
	const (
		fileFlagBackupSemantics  = 0x02000000
		fileFlagOpenReparsePoint = 0x00200000
	)
	result, _, callErr := reopenFile.Call(
		uintptr(handle),
		genericWriteAccess,
		syscall.FILE_SHARE_DELETE|syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE,
		fileFlagBackupSemantics|fileFlagOpenReparsePoint,
	)
	if syscall.Handle(result) == syscall.InvalidHandle {
		return syscall.InvalidHandle, callErr
	}
	return syscall.Handle(result), nil
}
