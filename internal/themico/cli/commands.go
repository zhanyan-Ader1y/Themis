package cli

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/governance"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/query"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/validate"
)

// maxMachineJSONBytes bounds every --input/--confirmation/--assessment/
// --approval/--request file this CLI reads, matching the project-wide 1 MiB
// machine JSON ceiling.
const maxMachineJSONBytes = 1 << 20

// maxCandidateContentReadBytes caps how many bytes commandCandidate{Create,
// Revise} ever hold in memory for a --content file. It intentionally reads
// one byte past candidate.Service's own 128 KiB content ceiling (see that
// constant's derivation comment in service.go: it is sized so a published
// L3 record can always survive query.Inspect's depth-3 canonical
// re-encoding, not picked independently of it) — a content file at or under
// the limit is read in full, and an oversized file is still classified
// downstream as validation_failed by the service (which rejects on length)
// instead of the CLI silently loading an unbounded amount of
// attacker-controlled data into memory first.
const maxCandidateContentReadBytes = (128 << 10) + 1

// ---- command handlers ----

func commandInit(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "init"
	values, err := parseFlags(args, []string{"root"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	st, err := store.Init(values["root"], store.Options{})
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	manifest, err := st.Current()
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, manifest)
}

func commandCandidateCreate(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "candidate create"
	values, err := parseFlags(args, []string{"root", "input", "content"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var request candidate.CreateRequest
	if err := decodeJSONFile(values["input"], &request); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}
	content, err := readContentFile(values["content"])
	if err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_content_file", message: err.Error()})
	}
	request.ContentMarkdown = content

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	revision, err := candidate.New(st).Create(ctx, request)
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, revision)
}

// reviseInput is the CLI's own decode shape for --input on `candidate
// revise`. candidate.ReviseRequest carries no json tags (it is only ever
// constructed in-process elsewhere), so this DTO gives the revision.json
// file a stable, strict, snake_case contract without adding tags to a
// package this task must not modify; its fields are copied verbatim into a
// candidate.ReviseRequest below.
type reviseInput struct {
	CandidateID      string              `json:"candidate_id"`
	ExpectedRevision string              `json:"expected_revision"`
	ProposedType     model.KnowledgeType `json:"proposed_type"`
	L1               model.L1            `json:"l1"`
	L2               model.L2            `json:"l2"`
	SourcePaths      []string            `json:"source_paths"`
	Relations        []model.Relation    `json:"relations"`
	RevisedBy        string              `json:"revised_by"`
}

func commandCandidateRevise(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "candidate revise"
	values, err := parseFlags(args, []string{"root", "input", "content"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var input reviseInput
	if err := decodeJSONFile(values["input"], &input); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}
	content, err := readContentFile(values["content"])
	if err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_content_file", message: err.Error()})
	}
	request := candidate.ReviseRequest{
		CandidateID:      input.CandidateID,
		ExpectedRevision: input.ExpectedRevision,
		ProposedType:     input.ProposedType,
		L1:               input.L1,
		L2:               input.L2,
		SourcePaths:      input.SourcePaths,
		Relations:        input.Relations,
		ContentMarkdown:  content,
		RevisedBy:        input.RevisedBy,
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	revised, err := candidate.New(st).Revise(ctx, request)
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, revised)
}

func commandCandidateConfirmType(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "candidate confirm-type"
	values, err := parseFlags(args, []string{"root", "confirmation"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var confirmation candidate.TypeConfirmation
	if err := decodeJSONFile(values["confirmation"], &confirmation); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	confirmed, err := candidate.New(st).ConfirmType(ctx, confirmation)
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, confirmed)
}

func commandCandidateInspect(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "candidate inspect"
	values, err := parseFlags(args, []string{"root", "id"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	revision, err := candidate.New(st).Inspect(ctx, values["id"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, revision)
}

func commandValidate(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "validate"
	values, err := parseFlags(args, []string{"root", "candidate", "revision"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	report, err := validate.Candidate(ctx, st, values["candidate"], values["revision"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return reportEnvelope(command, operationID, report)
}

func commandPreparePublish(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "prepare publish"
	values, err := parseFlags(args, []string{"root", "candidate", "assessment"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var assessment model.SemanticAssessment
	if err := decodeJSONFile(values["assessment"], &assessment); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	prepare, err := governance.New(st).PreparePublish(ctx, governance.PrepareRequest{
		CandidateID: values["candidate"],
		Assessment:  assessment,
	})
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, prepare)
}

func commandPublish(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "publish"
	values, err := parseFlags(args, []string{"root", "prepare", "approval"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var approval model.Approval
	if err := decodeJSONFile(values["approval"], &approval); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	record, err := governance.New(st).Publish(ctx, governance.PublishRequest{
		PrepareID: values["prepare"],
		Approval:  approval,
	})
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	return succeededEnvelope(command, operationID, record)
}

func commandQuery(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "query"
	values, err := parseFlags(args, []string{"root", "request"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var request query.Request
	if err := decodeJSONFile(values["request"], &request); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	res, err := query.Search(ctx, st, request)
	return traceEnvelope(command, operationID, res, res.Trace, err)
}

func commandInspectRecords(ctx context.Context, operationID string, args []string) result.Envelope {
	const command = "inspect"
	values, err := parseFlags(args, []string{"root", "request"}, nil)
	if err != nil {
		return usageEnvelope(command, operationID, err)
	}
	var request query.InspectRequest
	if err := decodeJSONFile(values["request"], &request); err != nil {
		return usageEnvelope(command, operationID, &usageError{code: "invalid_input_file", message: err.Error()})
	}

	st, err := openStore(values["root"])
	if err != nil {
		return domainEnvelope(command, operationID, err)
	}
	res, err := query.Inspect(ctx, st, request)
	return traceEnvelope(command, operationID, res, res.Trace, err)
}

// ---- store access ----

// openStore turns "no workspace exists under root yet" into store.ErrNotFound
// instead of letting it surface as store.Open's own store.ErrValidation: the
// workspace directory being absent means the object this command asked about
// (a candidate, a record, ...) cannot exist either, which is a not_found
// condition for every reader command, not a structural problem with an
// existing store.
func openStore(root string) (*store.Store, error) {
	if _, err := os.Stat(store.WorkspaceRoot(root)); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, fmt.Errorf("%w: store does not exist under %s", store.ErrNotFound, root)
		}
		return nil, err
	}
	return store.Open(root, store.Options{})
}

func readContentFile(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, maxCandidateContentReadBytes))
	if err != nil {
		return nil, err
	}
	return data, nil
}

// decodeJSONFile reads one strict machine JSON document. Unknown fields,
// trailing values and oversized inputs are refused.
func decodeJSONFile(path string, destination any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if len(data) > maxMachineJSONBytes {
		return fmt.Errorf("machine JSON exceeds %d bytes", maxMachineJSONBytes)
	}
	if bytes.Equal(bytes.TrimSpace(data), []byte("null")) {
		return fmt.Errorf("payload must be an object")
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	decoder.UseNumber()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		if err == nil {
			return fmt.Errorf("trailing JSON value")
		}
		return err
	}
	return nil
}

// ---- flag parsing ----

// usageError carries a specific issue code for one usage_error envelope.
// unknown/deferred commands always use code "unknown_command"; parseFlags
// uses a code per failure shape so an operator can tell "you misspelled a
// flag" from "you forgot a required one" without parsing Message text.
type usageError struct {
	code    string
	message string
}

func (e *usageError) Error() string { return e.message }

// parseFlags accepts only "--name value" pairs drawn from required/optional;
// every required name must appear exactly once. There are no boolean flags
// in this command surface, so an argument that is not a recognized "--name"
// is always a usage error, never a silently ignored positional argument.
func parseFlags(args []string, required, optional []string) (map[string]string, error) {
	allowed := make(map[string]bool, len(required)+len(optional))
	for _, name := range required {
		allowed[name] = true
	}
	for _, name := range optional {
		allowed[name] = true
	}
	values := make(map[string]string, len(allowed))
	for index := 0; index < len(args); {
		arg := args[index]
		if len(arg) <= 2 || arg[:2] != "--" {
			return nil, &usageError{code: "unexpected_argument", message: fmt.Sprintf("unexpected argument %q", arg)}
		}
		name := arg[2:]
		if !allowed[name] {
			return nil, &usageError{code: "unknown_flag", message: fmt.Sprintf("unknown flag --%s", name)}
		}
		if _, exists := values[name]; exists {
			return nil, &usageError{code: "duplicate_flag", message: fmt.Sprintf("duplicate flag --%s", name)}
		}
		if index+1 >= len(args) {
			return nil, &usageError{code: "flag_missing_value", message: fmt.Sprintf("flag --%s requires a value", name)}
		}
		values[name] = args[index+1]
		index += 2
	}
	for _, name := range required {
		if _, ok := values[name]; !ok {
			return nil, &usageError{code: "missing_flag", message: fmt.Sprintf("missing required flag --%s", name)}
		}
	}
	return values, nil
}

// ---- operation IDs ----

// newOperationID mints one op_<32 lowercase hex> identifier for a single
// invocation, matching the store's own ID format.
func newOperationID() (string, error) {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "", fmt.Errorf("read random operation ID bytes: %w", err)
	}
	return "op_" + hex.EncodeToString(raw[:]), nil
}

// ---- envelope construction ----

func canonicalOutput(value any) (json.RawMessage, error) {
	data, err := canonical.Encode(value)
	if err != nil {
		return nil, err
	}
	return json.RawMessage(data), nil
}

func usageEnvelope(command, operationID string, err error) result.Envelope {
	code := "usage_error"
	var usageErr *usageError
	if errors.As(err, &usageErr) {
		code = usageErr.code
	}
	return result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Status:    result.StatusUsageError,
		Operation: operationID,
		Issues:    []result.Issue{{Code: code, Path: "", Message: err.Error()}},
	}
}

func internalErrorEnvelope(command, operationID string, err error) result.Envelope {
	return result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Status:    result.StatusInternalError,
		Operation: operationID,
		Issues:    []result.Issue{{Code: "internal_error", Path: "", Message: err.Error()}},
	}
}

// domainEnvelope maps a service-layer error to its result.Status via
// statusFor and reports it as a single synthesized Issue; the service
// packages return plain errors here, not structured issues, so there is no
// richer Issue to relay.
func domainEnvelope(command, operationID string, err error) result.Envelope {
	status := statusFor(err)
	return result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Status:    status,
		Operation: operationID,
		Issues:    []result.Issue{{Code: string(status), Path: "", Message: err.Error()}},
	}
}

func succeededEnvelope(command, operationID string, output any) result.Envelope {
	data, err := canonicalOutput(output)
	if err != nil {
		return internalErrorEnvelope(command, operationID, err)
	}
	return result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Status:    result.StatusSucceeded,
		Operation: operationID,
		Output:    data,
		Issues:    []result.Issue{},
	}
}

// reportEnvelope reflects validate.Candidate's own OK verdict: OK is a
// normal, successful conclusion (status succeeded), and !OK is the
// deterministic validation_failed conclusion carrying Report.Issues — never
// a Go error, since validate.Candidate only errors when the store or
// candidate itself cannot be read.
func reportEnvelope(command, operationID string, report validate.Report) result.Envelope {
	output, err := canonicalOutput(report)
	if err != nil {
		return internalErrorEnvelope(command, operationID, err)
	}
	status := result.StatusSucceeded
	issues := []result.Issue{}
	if !report.OK {
		status = result.StatusValidationFailed
		issues = report.Issues
	}
	return result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Status:    status,
		Operation: operationID,
		Output:    output,
		Issues:    issues,
	}
}

// traceEnvelope backs the query and inspect commands: output carries the
// full service return value (query.Result or query.InspectResult, itself
// including a Trace field), and trace is additionally placed in the
// envelope's own Trace slot per this task's Output/Trace split. This runs
// the same whether err is nil, query.ErrBudgetExceeded (whose Result/
// InspectResult are still meaningful — empty Candidates/Items plus a full
// accounting trace), or any other domain error.
func traceEnvelope(command, operationID string, output any, trace query.Trace, err error) result.Envelope {
	outputBytes, encodeErr := canonicalOutput(output)
	if encodeErr != nil {
		return internalErrorEnvelope(command, operationID, encodeErr)
	}
	traceBytes, encodeErr := canonicalOutput(trace)
	if encodeErr != nil {
		return internalErrorEnvelope(command, operationID, encodeErr)
	}
	envelope := result.Envelope{
		Schema:    resultSchema,
		Command:   command,
		Operation: operationID,
		Output:    outputBytes,
		Trace:     traceBytes,
		Issues:    []result.Issue{},
	}
	if err != nil {
		envelope.Status = statusFor(err)
		envelope.Issues = []result.Issue{{Code: string(envelope.Status), Path: "", Message: err.Error()}}
		return envelope
	}
	envelope.Status = result.StatusSucceeded
	return envelope
}

// statusFor maps one domain error to its result.Status. The check order is
// significant: query.ErrBudgetExceeded, store.ErrConflict, and
// store.ErrPrecondition are each tested before the broader not_found/
// validation_failed groups so a wrapped error that happens to satisfy more
// than one sentinel still resolves to its most specific status.
func statusFor(err error) result.Status {
	switch {
	case err == nil:
		return result.StatusSucceeded
	case errors.Is(err, query.ErrBudgetExceeded):
		return result.StatusBudgetExceeded
	case errors.Is(err, store.ErrConflict):
		return result.StatusConflict
	case errors.Is(err, store.ErrPrecondition):
		return result.StatusPreconditionFailed
	case errors.Is(err, store.ErrNotFound), errors.Is(err, candidate.ErrNotFound):
		return result.StatusNotFound
	case errors.Is(err, store.ErrValidation), errors.Is(err, candidate.ErrTypeImmutable):
		return result.StatusValidationFailed
	default:
		return result.StatusInternalError
	}
}
