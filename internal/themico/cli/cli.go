// Package cli exposes the Themico service layer (candidate, validate,
// governance, query) as the "themico" command line surface. Every
// invocation writes exactly one JSON result.Envelope to stdout; stderr is
// reserved for process-level failures that cannot be encoded as an
// envelope (see writeProcessError). This file owns argument dispatch only;
// internal/themico/cli/commands.go owns each command's flag parsing,
// input decoding, service call, and error mapping.
package cli

import (
	"context"
	"encoding/json"
	"fmt"
	"io"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

const resultSchema = "themico-command-result"

func Run(ctx context.Context, args []string, stdout, stderr io.Writer) int {
	envelope := dispatch(ctx, args)
	exitCode, err := result.ExitCode(envelope.Status)
	if err != nil {
		return writeProcessError(stderr, err)
	}
	if err := result.Write(stdout, envelope); err != nil {
		return writeProcessError(stderr, err)
	}
	return exitCode
}

// dispatch routes one invocation to its command handler. help is resolved
// before any operation ID is minted so its envelope stays byte-identical
// across runs; every other path (including unknown commands) carries a
// fresh operation ID, matching every other command's envelope shape.
func dispatch(ctx context.Context, args []string) result.Envelope {
	command := ""
	if len(args) > 0 {
		command = args[0]
	}
	if command == "help" {
		return helpEnvelope()
	}

	operationID, err := newOperationID()
	if err != nil {
		return internalErrorEnvelope(command, "", err)
	}
	if command == "" {
		return usageEnvelope(command, operationID, &usageError{code: "unknown_command", message: "command is required"})
	}

	rest := args[1:]
	switch command {
	case "init":
		return commandInit(ctx, operationID, rest)
	case "candidate":
		return dispatchCandidate(ctx, operationID, rest)
	case "validate":
		return commandValidate(ctx, operationID, rest)
	case "prepare":
		return dispatchPrepare(ctx, operationID, rest)
	case "publish":
		return commandPublish(ctx, operationID, rest)
	case "query":
		return commandQuery(ctx, operationID, rest)
	case "inspect":
		return commandInspectRecords(ctx, operationID, rest)
	default:
		return usageEnvelope(command, operationID, &usageError{
			code:    "unknown_command",
			message: fmt.Sprintf("command %q is not recognized", command),
		})
	}
}

func dispatchCandidate(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "candidate"
	if len(args) == 0 {
		return usageEnvelope(command, operationID, &usageError{code: "unknown_command", message: "candidate subcommand is required"})
	}
	sub := args[0]
	rest := args[1:]
	switch sub {
	case "create":
		return commandCandidateCreate(ctx, operationID, rest)
	case "revise":
		return commandCandidateRevise(ctx, operationID, rest)
	case "confirm-type":
		return commandCandidateConfirmType(ctx, operationID, rest)
	case "inspect":
		return commandCandidateInspect(ctx, operationID, rest)
	default:
		return usageEnvelope(command, operationID, &usageError{
			code:    "unknown_command",
			message: fmt.Sprintf("candidate subcommand %q is not recognized", sub),
		})
	}
}

func dispatchPrepare(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "prepare"
	if len(args) == 0 {
		return usageEnvelope(command, operationID, &usageError{code: "unknown_command", message: "prepare subcommand is required"})
	}
	sub := args[0]
	rest := args[1:]
	switch sub {
	case "publish":
		return commandPreparePublish(ctx, operationID, rest)
	default:
		return usageEnvelope(command, operationID, &usageError{
			code:    "unknown_command",
			message: fmt.Sprintf("prepare subcommand %q is not recognized", sub),
		})
	}
}

// helpEnvelope is intentionally built without calling newOperationID: its
// Operation field is always the empty string so two "help" invocations
// produce byte-identical stdout, and its commands array lists exactly the
// first-delivery command surface below — no deferred command ever appears
// here.
func helpEnvelope() result.Envelope {
	return result.Envelope{
		Schema:  resultSchema,
		Command: "help",
		Status:  result.StatusSucceeded,
		Output: json.RawMessage(
			`{"binary":"themico","commands":["help","init","candidate create","candidate revise","candidate confirm-type","candidate inspect","validate","prepare publish","publish","query","inspect"]}`,
		),
		Issues: []result.Issue{},
	}
}

func writeProcessError(stderr io.Writer, err error) int {
	if stderr != nil {
		_, _ = fmt.Fprintln(stderr, err)
	}
	return result.ExitInternal
}
