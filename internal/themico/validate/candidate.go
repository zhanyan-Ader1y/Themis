// Package validate proves the machine-decidable contract of one candidate
// revision: type/zone compatibility, typed L2 payload, fixed L3 sections,
// L1/L2/L3 digests, exact candidate currentness, source currentness, and the
// declared relations. It is a deterministic gate ahead of the publish chain
// and never returns an authoritative verdict beyond the closed issue codes
// below.
package validate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/candidate"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

const (
	maxSourceBytes = 16 << 20
	maxRecordBytes = 1 << 20
)

// Report is the deterministic machine verdict for one candidate revision.
type Report struct {
	CandidateID       string         `json:"candidate_id"`
	CandidateRevision string         `json:"candidate_revision"`
	OK                bool           `json:"ok"`
	Issues            []result.Issue `json:"issues"`
}

// Candidate proves the machine-decidable contract of one candidate revision.
// It only returns an error when the store cannot be read or the candidate
// does not exist; every other machine-decidable contract problem becomes an
// Issue with OK=false.
func Candidate(ctx context.Context, st *store.Store, candidateID, candidateRevision string) (Report, error) {
	service := candidate.New(st)
	revision, err := service.Inspect(ctx, candidateID)
	if err != nil {
		return Report{}, err
	}

	if candidateRevision != revision.Revision {
		return Report{
			CandidateID:       candidateID,
			CandidateRevision: candidateRevision,
			OK:                false,
			Issues: []result.Issue{
				issue("candidate.revision_stale", "candidate_revision", "candidate revision is not the current revision"),
			},
		}, nil
	}

	manifest, err := st.Current()
	if err != nil {
		return Report{}, err
	}

	issues := make([]result.Issue, 0)

	if revision.Status != model.CandidateStatusTypeConfirmed {
		issues = append(issues, issue("type.not_confirmed", "status", "candidate type must be confirmed before validation"))
	}

	factory, factoryFound := model.LookupFactory(revision.KnowledgeType)
	if !factoryFound {
		issues = append(issues, issue("type.unregistered", "knowledge_type", "knowledge type is not registered"))
	} else {
		if factory.Zone != revision.Zone {
			issues = append(issues, issue("type.zone_incompatible", "zone", "knowledge type is incompatible with the candidate's zone"))
		}
		if _, err := factory.DecodePayload(revision.L2.Payload); err != nil {
			issues = append(issues, issue("l2.payload_invalid", "l2.payload", "L2 payload does not match the registered type"))
		}
		issues = append(issues, checkMarkdown(revision.ContentMarkdown, factory.L3Headings)...)
	}

	if l1Digest, err := canonical.Digest(revision.L1); err != nil || l1Digest != revision.L1Digest {
		issues = append(issues, issue("digest.l1_mismatch", "l1_digest", "L1 digest does not match the recomputed canonical digest"))
	}
	if l2Digest, err := canonical.Digest(revision.L2); err != nil || l2Digest != revision.L2Digest {
		issues = append(issues, issue("digest.l2_mismatch", "l2_digest", "L2 digest does not match the recomputed canonical digest"))
	}
	if rawDigest(revision.ContentMarkdown) != revision.L3Digest {
		issues = append(issues, issue("digest.l3_mismatch", "l3_digest", "L3 digest does not match the recomputed content digest"))
	}

	issues = append(issues, checkSources(st.RepositoryRoot(), revision.Sources)...)

	targets, zones := currentRecordTargets(st, manifest)
	issues = append(issues, checkRelations(revision.Relations, revision.Zone, targets, zones)...)

	slices.SortFunc(issues, func(left, right result.Issue) int {
		if left.Path != right.Path {
			return strings.Compare(left.Path, right.Path)
		}
		if left.Code != right.Code {
			return strings.Compare(left.Code, right.Code)
		}
		return strings.Compare(left.Message, right.Message)
	})
	return Report{
		CandidateID:       revision.CandidateID,
		CandidateRevision: revision.Revision,
		OK:                len(issues) == 0,
		Issues:            issues,
	}, nil
}

// currentRecordTargets builds the relation lookup tables from the current
// manifest's record pointers. A record whose payload cannot be read, or whose
// bytes no longer match its pointer digest, is deliberately left out of
// targets so any relation referencing it surfaces as relation.target_missing
// instead of silently trusting an unresolved zone.
func currentRecordTargets(st *store.Store, manifest model.Manifest) (map[string]model.RecordPointer, map[string]model.Zone) {
	targets := make(map[string]model.RecordPointer, len(manifest.CurrentRecords))
	zones := make(map[string]model.Zone, len(manifest.CurrentRecords))
	root, err := os.OpenRoot(st.Root())
	if err != nil {
		return targets, zones
	}
	defer root.Close()
	for _, pointer := range manifest.CurrentRecords {
		zone, ok := readRecordZone(root, pointer)
		if !ok {
			continue
		}
		targets[pointer.RecordID] = pointer
		zones[pointer.RecordID] = zone
	}
	return targets, zones
}

// readRecordZone reads and verifies one record revision's persisted payload
// against its manifest pointer digest, returning its declared Zone only when
// the payload is readable, canonical, and binds exactly to the pointer.
func readRecordZone(root *os.Root, pointer model.RecordPointer) (model.Zone, bool) {
	path := strings.Join([]string{"records", pointer.RecordID, "revisions", pointer.Revision, "record.json"}, "/")
	data, err := readLimited(root, filepath.FromSlash(path), maxRecordBytes)
	if err != nil {
		return "", false
	}
	canonicalPayload, err := canonical.Encode(json.RawMessage(data))
	if err != nil {
		return "", false
	}
	if rawDigest(canonicalPayload) != pointer.Digest {
		return "", false
	}
	var record model.RecordRevision
	if err := decodeStrict(canonicalPayload, &record); err != nil {
		return "", false
	}
	if record.RecordID != pointer.RecordID || record.Revision != pointer.Revision {
		return "", false
	}
	return record.Zone, true
}

// checkSources re-reads the actual repository bytes for every declared source
// and compares them against the digest bound at candidate creation time.
func checkSources(repositoryRoot string, sources []model.SourceRef) []result.Issue {
	issues := make([]result.Issue, 0)
	root, err := os.OpenRoot(repositoryRoot)
	if err != nil {
		return append(issues, issue("source.unreadable", "sources", "repository root is unreadable"))
	}
	defer root.Close()
	for index, source := range sources {
		path := fmt.Sprintf("sources[%d]", index)
		data, err := readLimited(root, filepath.FromSlash(source.Path), maxSourceBytes)
		if err != nil {
			issues = append(issues, issue("source.unreadable", path, "source cannot be read"))
			continue
		}
		if rawDigest(data) != source.Digest {
			issues = append(issues, issue("source.stale", path, "source bytes changed after binding"))
		}
	}
	return issues
}

func issue(code, path, message string) result.Issue {
	return result.Issue{Code: code, Path: path, Message: message}
}

func readLimited(root *os.Root, path string, limit int64) ([]byte, error) {
	file, err := root.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return nil, err
	}
	if !info.Mode().IsRegular() {
		return nil, fmt.Errorf("not a regular file")
	}
	data, err := io.ReadAll(io.LimitReader(file, limit+1))
	if err != nil {
		return nil, err
	}
	if int64(len(data)) > limit {
		return nil, fmt.Errorf("file exceeds size limit")
	}
	return data, nil
}

func decodeStrict(data []byte, destination any) error {
	decoder := json.NewDecoder(strings.NewReader(string(data)))
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

func rawDigest(data []byte) string {
	value := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(value[:])
}
