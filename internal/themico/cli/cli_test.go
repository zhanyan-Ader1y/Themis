package cli_test

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"strings"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/cli"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

func TestRunRejectsEmptyArguments(t *testing.T) {
	exitCode, envelope, stdout, stderr := run(t)

	if exitCode != result.ExitUsage {
		t.Errorf("Run() exit code = %d, want %d", exitCode, result.ExitUsage)
	}
	if envelope.Status != result.StatusUsageError {
		t.Errorf("Run() status = %q, want %q", envelope.Status, result.StatusUsageError)
	}
	if envelope.Command != "" {
		t.Errorf("Run() command = %q, want empty command", envelope.Command)
	}
	assertSingleJSONLine(t, stdout)
	if stderr != "" {
		t.Errorf("Run() stderr = %q, want empty", stderr)
	}
}

func TestRunRejectsUnknownCommand(t *testing.T) {
	exitCode, envelope, stdout, stderr := run(t, "future-command")

	if exitCode != result.ExitUsage {
		t.Errorf("Run() exit code = %d, want %d", exitCode, result.ExitUsage)
	}
	if envelope.Status != result.StatusUsageError {
		t.Errorf("Run() status = %q, want %q", envelope.Status, result.StatusUsageError)
	}
	if envelope.Command != "future-command" {
		t.Errorf("Run() command = %q, want %q", envelope.Command, "future-command")
	}
	assertSingleJSONLine(t, stdout)
	if stderr != "" {
		t.Errorf("Run() stderr = %q, want empty", stderr)
	}
}

func TestRunHelpUsesStableEnvelope(t *testing.T) {
	exitCode, envelope, stdout, stderr := run(t, "help")

	if exitCode != result.ExitSuccess {
		t.Errorf("Run() exit code = %d, want %d", exitCode, result.ExitSuccess)
	}
	if envelope.Status != result.StatusSucceeded {
		t.Errorf("Run() status = %q, want %q", envelope.Status, result.StatusSucceeded)
	}
	if envelope.Schema != "themico-command-result" {
		t.Errorf("Run() schema = %q, want %q", envelope.Schema, "themico-command-result")
	}
	if envelope.Command != "help" {
		t.Errorf("Run() command = %q, want %q", envelope.Command, "help")
	}
	if envelope.Issues == nil || len(envelope.Issues) != 0 {
		t.Errorf("Run() issues = %#v, want empty array", envelope.Issues)
	}
	if len(envelope.Output) == 0 {
		t.Error("Run() help output is empty")
	}
	assertSingleJSONLine(t, stdout)
	if stderr != "" {
		t.Errorf("Run() stderr = %q, want empty", stderr)
	}
}

func TestRunHelpIsByteStable(t *testing.T) {
	firstExit, _, firstStdout, firstStderr := run(t, "help")
	secondExit, _, secondStdout, secondStderr := run(t, "help")

	if firstExit != result.ExitSuccess || secondExit != result.ExitSuccess {
		t.Fatalf("Run() exit codes = %d, %d, want %d", firstExit, secondExit, result.ExitSuccess)
	}
	if firstStdout != secondStdout {
		t.Errorf("Run() help outputs differ:\nfirst:  %q\nsecond: %q", firstStdout, secondStdout)
	}
	if firstStderr != "" || secondStderr != "" {
		t.Errorf("Run() stderr = %q, %q, want empty", firstStderr, secondStderr)
	}
}

func TestRunEmitsExactlyOneEnvelopePerInvocation(t *testing.T) {
	for _, test := range []struct {
		name string
		args []string
		want result.Status
	}{
		{name: "unknown command", args: []string{"supersede"}, want: result.StatusUsageError},
		{name: "missing root", args: []string{"init"}, want: result.StatusUsageError},
		{name: "unknown flag", args: []string{"init", "--root", ".", "--force"}, want: result.StatusUsageError},
		{name: "absent store", args: []string{"candidate", "inspect", "--root", t.TempDir(), "--id", "cand_" + strings.Repeat("0", 32)}, want: result.StatusNotFound},
	} {
		t.Run(test.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			code := cli.Run(context.Background(), test.args, &stdout, &stderr)

			var envelope result.Envelope
			decoder := json.NewDecoder(bytes.NewReader(stdout.Bytes()))
			if err := decoder.Decode(&envelope); err != nil {
				t.Fatalf("stdout is not one envelope: %v (%q)", err, stdout.String())
			}
			if err := decoder.Decode(&struct{}{}); err != io.EOF {
				t.Fatalf("stdout carries trailing output: %q", stdout.String())
			}
			if envelope.Status != test.want {
				t.Fatalf("status=%s want %s", envelope.Status, test.want)
			}
			wantCode, err := result.ExitCode(test.want)
			if err != nil {
				t.Fatal(err)
			}
			if code != wantCode {
				t.Fatalf("exit=%d want %d", code, wantCode)
			}
			if envelope.Issues == nil {
				t.Fatal("issues must be an empty array, never null")
			}
		})
	}
}

func TestHelpOutputIsByteIdenticalAcrossRuns(t *testing.T) {
	var first, second bytes.Buffer
	if code := cli.Run(context.Background(), []string{"help"}, &first, io.Discard); code != result.ExitSuccess {
		t.Fatalf("exit=%d", code)
	}
	if code := cli.Run(context.Background(), []string{"help"}, &second, io.Discard); code != result.ExitSuccess {
		t.Fatalf("exit=%d", code)
	}
	if !bytes.Equal(first.Bytes(), second.Bytes()) {
		t.Fatalf("help is not deterministic:\n%s\n%s", first.String(), second.String())
	}
	for _, deferred := range []string{"supersede", "deprecate", "archive", "rebuild", "create-derived"} {
		if bytes.Contains(first.Bytes(), []byte(deferred)) {
			t.Fatalf("help advertises deferred command %q", deferred)
		}
	}
}

func run(t *testing.T, args ...string) (int, result.Envelope, string, string) {
	t.Helper()

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	exitCode := cli.Run(context.Background(), args, &stdout, &stderr)

	var envelope result.Envelope
	if err := json.Unmarshal(stdout.Bytes(), &envelope); err != nil {
		t.Fatalf("json.Unmarshal(stdout) error = %v, stdout = %q", err, stdout.Bytes())
	}
	return exitCode, envelope, stdout.String(), stderr.String()
}

func assertSingleJSONLine(t *testing.T, output string) {
	t.Helper()
	if bytes.Count([]byte(output), []byte("\n")) != 1 || len(output) == 0 || output[len(output)-1] != '\n' {
		t.Errorf("stdout = %q, want one JSON object followed by exactly one newline", output)
	}
}
