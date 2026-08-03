package result_test

import (
	"bytes"
	"encoding/json"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

func TestExitCodeCoversEveryStatus(t *testing.T) {
	tests := []struct {
		name   string
		status result.Status
		want   int
	}{
		{name: "succeeded", status: result.StatusSucceeded, want: 0},
		{name: "internal error", status: result.StatusInternalError, want: 1},
		{name: "usage error", status: result.StatusUsageError, want: 2},
		{name: "validation failed", status: result.StatusValidationFailed, want: 3},
		{name: "not found", status: result.StatusNotFound, want: 4},
		{name: "precondition failed", status: result.StatusPreconditionFailed, want: 5},
		{name: "conflict", status: result.StatusConflict, want: 6},
		{name: "stale", status: result.StatusStale, want: 7},
		{name: "unauthorized", status: result.StatusUnauthorized, want: 8},
		{name: "approval required", status: result.StatusApprovalRequired, want: 9},
		{name: "budget exceeded", status: result.StatusBudgetExceeded, want: 10},
		{name: "unavailable", status: result.StatusUnavailable, want: 11},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := result.ExitCode(test.status)
			if err != nil {
				t.Fatalf("ExitCode(%q) error = %v", test.status, err)
			}
			if got != test.want {
				t.Errorf("ExitCode(%q) = %d, want %d", test.status, got, test.want)
			}
		})
	}
}

func TestExitCodeRejectsUnknownStatus(t *testing.T) {
	if _, err := result.ExitCode(result.Status("future_status")); err == nil {
		t.Fatal("ExitCode() error = nil, want unknown status error")
	}
}

func TestWriteRejectsUnknownStatusWithoutOutput(t *testing.T) {
	var stdout bytes.Buffer
	err := result.Write(&stdout, result.Envelope{Status: result.Status("future_status")})
	if err == nil {
		t.Fatal("Write() error = nil, want unknown status error")
	}
	if stdout.Len() != 0 {
		t.Errorf("Write() output = %q, want no output", stdout.Bytes())
	}
}

func TestWriteSucceededEnvelopeAsSingleJSONLine(t *testing.T) {
	envelope := result.Envelope{
		Schema:    "themico-command-result",
		Command:   "help",
		Status:    result.StatusSucceeded,
		Operation: "op-test",
		Issues:    []result.Issue{},
	}

	var stdout bytes.Buffer
	if err := result.Write(&stdout, envelope); err != nil {
		t.Fatalf("Write() error = %v", err)
	}

	got := stdout.Bytes()
	if bytes.Count(got, []byte("\n")) != 1 || len(got) == 0 || got[len(got)-1] != '\n' {
		t.Fatalf("Write() output = %q, want one JSON object followed by exactly one newline", got)
	}

	var decoded result.Envelope
	if err := json.Unmarshal(got, &decoded); err != nil {
		t.Fatalf("json.Unmarshal() error = %v, output = %q", err, got)
	}
	if decoded.Status != result.StatusSucceeded {
		t.Errorf("decoded status = %q, want %q", decoded.Status, result.StatusSucceeded)
	}
	if decoded.Issues == nil {
		t.Error("decoded issues = nil, want an empty JSON array")
	}
}
