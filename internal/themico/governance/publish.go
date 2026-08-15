package governance

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

// PublishRequest asks the Service to commit one previously frozen prepare,
// authorized by exactly one Human Approval bound to it.
type PublishRequest struct {
	PrepareID string
	Approval  model.Approval
}

// Publish authorizes and commits one prepare in a single generation commit.
// Every gate fails closed: an invalid or unbound approval and a structurally
// invalid prepare surface as store.ErrPrecondition, drifted sources surface
// as store.ErrValidation, and a store that advanced past the prepared
// generation surfaces as store.ErrConflict. None of these paths change the
// store's current state.
func (s *Service) Publish(ctx context.Context, request PublishRequest) (model.RecordRevision, error) {
	if err := s.ready(ctx); err != nil {
		return model.RecordRevision{}, err
	}

	prepare, err := s.readPrepare(request.PrepareID)
	if err != nil {
		return model.RecordRevision{}, err
	}

	if err := checkApproval(request.Approval, prepare); err != nil {
		return model.RecordRevision{}, err
	}

	candidateService := candidate.New(s.store)
	currentCandidate, err := candidateService.Inspect(ctx, prepare.CandidateID)
	if err != nil {
		return model.RecordRevision{}, err
	}
	if currentCandidate.Revision != prepare.CandidateRevision {
		return model.RecordRevision{}, preconditionError("candidate advanced since prepare", nil)
	}

	if err := checkSourceCurrency(s.store.RepositoryRoot(), prepare.Sources); err != nil {
		return model.RecordRevision{}, err
	}

	manifest, views, err := s.store.CurrentState()
	if err != nil {
		return model.RecordRevision{}, err
	}
	if manifest.Generation != prepare.ExpectedGeneration {
		return model.RecordRevision{}, conflictError("store advanced past the prepared generation", nil)
	}

	approvalBytes, err := canonical.Encode(request.Approval)
	if err != nil {
		return model.RecordRevision{}, validationError("encode approval", err)
	}
	approvalDigest := rawDigest(approvalBytes)
	approvalPathValue, err := approvalPath(approvalDigest)
	if err != nil {
		return model.RecordRevision{}, err
	}

	record := buildRecordRevision(currentCandidate, prepare.RecordID, prepare.RecordRevision, prepare.CreatedAt, prepare.ExpectedGeneration+1, approvalDigest)
	recordBytes, err := canonical.Encode(record)
	if err != nil {
		return model.RecordRevision{}, validationError("encode record revision", err)
	}
	contentBytes := append([]byte(nil), currentCandidate.ContentMarkdown...)

	// l1.json and l2.json are written as byte-identical copies of the same
	// full model.Projection object; see the matching comment in prepare.go
	// for why store.validateProjectionReference forces this (it decodes both
	// paths as a complete Projection and DeepEqual-checks both L1 and L2
	// against each of them), and task-7-report.md concern 4 for why this is
	// a known store-layer constraint that needs escalation, not a choice
	// made here.
	projection := buildProjection(record)
	projectionBytes, err := canonical.Encode(projection)
	if err != nil {
		return model.RecordRevision{}, validationError("encode projection", err)
	}

	// Explicitly re-verify every byte this commit is about to write against
	// the digest Prepare.Writes froze for it, instead of relying on
	// buildRecordRevision/buildProjection determinism as an unchecked
	// assumption. recordFreezeDigest clears AuthorizationDigest/Generation
	// the same way prepare.go did when it froze this entry, so the two are
	// directly comparable. Any mismatch here means the prepare artifact (or
	// this reconstruction) no longer matches what was approved, and the
	// publish must fail closed before anything is committed.
	recordFreeze, err := recordFreezeDigest(record)
	if err != nil {
		return model.RecordRevision{}, err
	}
	if err := verifyFrozenWrite(prepare.Writes, recordPath(record.RecordID, record.Revision, "record.json"), recordFreeze); err != nil {
		return model.RecordRevision{}, err
	}
	if err := verifyFrozenWrite(prepare.Writes, recordPath(record.RecordID, record.Revision, "content.md"), rawDigest(contentBytes)); err != nil {
		return model.RecordRevision{}, err
	}
	if err := verifyFrozenWrite(prepare.Writes, projectionPath(record.RecordID, record.Revision, "l1.json"), rawDigest(projectionBytes)); err != nil {
		return model.RecordRevision{}, err
	}
	if err := verifyFrozenWrite(prepare.Writes, projectionPath(record.RecordID, record.Revision, "l2.json"), rawDigest(projectionBytes)); err != nil {
		return model.RecordRevision{}, err
	}

	// The candidate pointer's status can only become "published" if the
	// candidate.json it references already carries that status, so a fresh
	// immutable candidate revision is required here; the four-target write
	// set in the design brief covers the record/projection/approval side of
	// this commit, and this is the candidate-side counterpart it implies.
	publishedRevisionID, err := s.store.AllocateID("crev_")
	if err != nil {
		return model.RecordRevision{}, err
	}
	publishedCandidate := currentCandidate
	publishedCandidate.Revision = publishedRevisionID
	publishedCandidate.Status = model.CandidateStatusPublished
	publishedCandidate.PublishedRecordID = prepare.RecordID
	publishedCandidate.CreatedAt = s.store.Now().Format(time.RFC3339Nano)
	publishedCandidate = model.NormalizeCandidateRevision(publishedCandidate)
	candidateBytes, err := canonical.Encode(publishedCandidate)
	if err != nil {
		return model.RecordRevision{}, validationError("encode candidate revision", err)
	}

	newManifest := manifest
	newManifest.CurrentRecords = append(append([]model.RecordPointer(nil), manifest.CurrentRecords...), model.RecordPointer{
		RecordID: record.RecordID, Revision: record.Revision, Status: record.Status, Digest: rawDigest(recordBytes),
	})
	newManifest.Projections = append(append([]model.ProjectionRef(nil), manifest.Projections...), model.ProjectionRef{
		RecordID: record.RecordID, Revision: record.Revision,
		L1Digest: rawDigest(projectionBytes), L2Digest: rawDigest(projectionBytes), L3Digest: record.L3Digest,
	})
	newManifest.CurrentCandidates = replaceCandidatePointer(manifest.CurrentCandidates, model.CandidatePointer{
		CandidateID: publishedCandidate.CandidateID,
		Revision:    publishedCandidate.Revision,
		Status:      model.CandidateStatusPublished,
		Digest:      rawDigest(candidateBytes),
		RecordID:    prepare.RecordID,
	})

	if _, err := s.store.Commit(ctx, store.CommitPlan{
		ExpectedGeneration: prepare.ExpectedGeneration,
		Writes: []store.ImmutableWrite{
			{Path: recordPath(record.RecordID, record.Revision, "record.json"), Data: recordBytes},
			{Path: recordPath(record.RecordID, record.Revision, "content.md"), Data: contentBytes},
			{Path: projectionPath(record.RecordID, record.Revision, "l1.json"), Data: projectionBytes},
			{Path: projectionPath(record.RecordID, record.Revision, "l2.json"), Data: projectionBytes},
			{Path: candidatePath(publishedCandidate.CandidateID, publishedCandidate.Revision, "candidate.json"), Data: candidateBytes},
			{Path: candidatePath(publishedCandidate.CandidateID, publishedCandidate.Revision, "content.md"), Data: publishedCandidate.ContentMarkdown},
			{Path: approvalPathValue, Data: approvalBytes},
		},
		Manifest: newManifest,
		// Publish never touches views: the first usable delivery's views.json
		// is the fixed canonical empty object, and this passes CurrentState's
		// bytes through unchanged rather than re-deriving them.
		Views: views,
	}); err != nil {
		return model.RecordRevision{}, err
	}

	// record was already normalized inside buildRecordRevision; it is
	// returned as-is rather than normalized a second time.
	return record, nil
}

// readPrepare reads and verifies one immutable prepare artifact by ID. A
// missing prepare is a precondition failure: store.ErrNotFound does not yet
// exist in this package's dependency surface, so "the prepare does not
// exist" is expressed as store.ErrPrecondition here.
func (s *Service) readPrepare(prepareID string) (model.Prepare, error) {
	root, err := os.OpenRoot(s.store.Root())
	if err != nil {
		return model.Prepare{}, validationError("open store root", err)
	}
	defer root.Close()

	data, err := readLimited(root, filepath.FromSlash(preparePath(prepareID)), maxMachineJSON)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return model.Prepare{}, preconditionError("prepare does not exist", nil)
		}
		return model.Prepare{}, validationError("read prepare", err)
	}
	canonicalPayload, err := canonical.Encode(json.RawMessage(data))
	if err != nil {
		return model.Prepare{}, validationError("prepare payload is not canonical JSON", err)
	}
	var prepare model.Prepare
	if err := decodeExact(canonicalPayload, &prepare); err != nil {
		return model.Prepare{}, validationError("decode prepare", err)
	}
	if prepare.PrepareID != prepareID {
		return model.Prepare{}, validationError("prepare identity mismatch", nil)
	}
	wantDigest, err := computePrepareDigest(prepare)
	if err != nil {
		return model.Prepare{}, err
	}
	if prepare.Digest != wantDigest {
		return model.Prepare{}, validationError("prepare digest mismatch", nil)
	}
	return prepare, nil
}
