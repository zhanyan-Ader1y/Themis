package result

import (
	"encoding/json"
	"fmt"
	"io"
)

type Status string

const (
	StatusSucceeded          Status = "succeeded"
	StatusUsageError         Status = "usage_error"
	StatusValidationFailed   Status = "validation_failed"
	StatusNotFound           Status = "not_found"
	StatusPreconditionFailed Status = "precondition_failed"
	StatusConflict           Status = "conflict"
	StatusStale              Status = "stale"
	StatusUnauthorized       Status = "unauthorized"
	StatusApprovalRequired   Status = "approval_required"
	StatusBudgetExceeded     Status = "budget_exceeded"
	StatusUnavailable        Status = "unavailable"
	StatusInternalError      Status = "internal_error"
)

const (
	ExitSuccess          = 0
	ExitInternal         = 1
	ExitUsage            = 2
	ExitValidation       = 3
	ExitNotFound         = 4
	ExitPrecondition     = 5
	ExitConflict         = 6
	ExitStale            = 7
	ExitUnauthorized     = 8
	ExitApprovalRequired = 9
	ExitBudgetExceeded   = 10
	ExitUnavailable      = 11
)

type Envelope struct {
	Schema    string          `json:"schema"`
	Command   string          `json:"command"`
	Status    Status          `json:"status"`
	Operation string          `json:"operation_id"`
	Output    json.RawMessage `json:"output,omitempty"`
	Issues    []Issue         `json:"issues"`
	Trace     json.RawMessage `json:"trace,omitempty"`
}

type Issue struct {
	Code    string `json:"code"`
	Path    string `json:"path"`
	Message string `json:"message"`
}

func Write(writer io.Writer, envelope Envelope) error {
	if _, err := ExitCode(envelope.Status); err != nil {
		return err
	}
	if envelope.Issues == nil {
		envelope.Issues = []Issue{}
	}
	return json.NewEncoder(writer).Encode(envelope)
}

func ExitCode(status Status) (int, error) {
	switch status {
	case StatusSucceeded:
		return ExitSuccess, nil
	case StatusInternalError:
		return ExitInternal, nil
	case StatusUsageError:
		return ExitUsage, nil
	case StatusValidationFailed:
		return ExitValidation, nil
	case StatusNotFound:
		return ExitNotFound, nil
	case StatusPreconditionFailed:
		return ExitPrecondition, nil
	case StatusConflict:
		return ExitConflict, nil
	case StatusStale:
		return ExitStale, nil
	case StatusUnauthorized:
		return ExitUnauthorized, nil
	case StatusApprovalRequired:
		return ExitApprovalRequired, nil
	case StatusBudgetExceeded:
		return ExitBudgetExceeded, nil
	case StatusUnavailable:
		return ExitUnavailable, nil
	default:
		return 0, fmt.Errorf("unknown result status %q", status)
	}
}
