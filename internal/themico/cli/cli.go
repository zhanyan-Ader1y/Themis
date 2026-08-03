package cli

import (
	"context"
	"encoding/json"
	"fmt"
	"io"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

const resultSchema = "themico-command-result"

func Run(_ context.Context, args []string, stdout, stderr io.Writer) int {
	command := ""
	if len(args) > 0 {
		command = args[0]
	}

	envelope := dispatch(command)
	exitCode, err := result.ExitCode(envelope.Status)
	if err != nil {
		return writeProcessError(stderr, err)
	}
	if err := result.Write(stdout, envelope); err != nil {
		return writeProcessError(stderr, err)
	}
	return exitCode
}

func dispatch(command string) result.Envelope {
	if command == "help" {
		return helpEnvelope()
	}
	return usageEnvelope(command)
}

func usageEnvelope(command string) result.Envelope {
	return result.Envelope{
		Schema:  resultSchema,
		Command: command,
		Status:  result.StatusUsageError,
		Issues: []result.Issue{
			{
				Code:    "unknown_command",
				Path:    "args[0]",
				Message: "command must be help",
			},
		},
	}
}

func helpEnvelope() result.Envelope {
	return result.Envelope{
		Schema:  resultSchema,
		Command: "help",
		Status:  result.StatusSucceeded,
		Output: json.RawMessage(
			`{"binary":"themico","commands":["help"]}`,
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
