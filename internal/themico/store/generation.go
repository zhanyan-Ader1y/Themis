package store

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

func generationName(generation uint64) string {
	return fmt.Sprintf("gen-%020d", generation)
}

func parseGenerationName(name string) (uint64, bool) {
	if len(name) != len("gen-")+20 || !strings.HasPrefix(name, "gen-") {
		return 0, false
	}
	digits := name[len("gen-"):]
	for _, char := range digits {
		if char < '0' || char > '9' {
			return 0, false
		}
	}
	generation, err := strconv.ParseUint(digits, 10, 64)
	return generation, err == nil
}

func (s *Store) loadCurrent() (model.Manifest, error) {
	root, err := os.OpenRoot(s.root)
	if err != nil {
		return model.Manifest{}, validationError("open store root", err)
	}
	defer root.Close()

	metadata, err := loadMetadata(root)
	if err != nil {
		return model.Manifest{}, err
	}
	if metadata.Schema != storeSchema {
		return model.Manifest{}, validationError("store metadata schema is invalid", nil)
	}
	if err := validateID("op_", metadata.StoreID); err != nil {
		return model.Manifest{}, err
	}
	createdAt, err := time.Parse(time.RFC3339Nano, metadata.CreatedAt)
	if err != nil || createdAt.Location() != time.UTC || !strings.HasSuffix(metadata.CreatedAt, "Z") {
		return model.Manifest{}, validationError("store creation time is not UTC RFC3339Nano", err)
	}
	generations, err := root.OpenRoot("generations")
	if err != nil {
		return model.Manifest{}, validationError("open generations root", err)
	}
	defer generations.Close()
	entries, err := readRootDir(generations, ".")
	if err != nil {
		return model.Manifest{}, validationError("read generations", err)
	}
	numbered := make(map[uint64]string)
	var highest uint64
	for _, entry := range entries {
		generation, ok := parseGenerationName(entry.Name())
		if !ok {
			continue
		}
		if !entry.IsDir() {
			return model.Manifest{}, validationError("generation entry is not a directory", nil)
		}
		numbered[generation] = entry.Name()
		if generation > highest {
			highest = generation
		}
	}
	if _, ok := numbered[0]; !ok {
		return model.Manifest{}, validationError("generation zero is missing", nil)
	}

	var current model.Manifest
	for generation := uint64(0); generation <= highest; generation++ {
		name, ok := numbered[generation]
		if !ok {
			return model.Manifest{}, validationError("generation chain has a gap", nil)
		}
		manifest, views, err := loadGeneration(generations, name)
		if err != nil {
			return model.Manifest{}, err
		}
		if manifest.Generation != generation {
			return model.Manifest{}, validationError("manifest generation does not match directory", nil)
		}
		if generation == 0 {
			if manifest.ParentGeneration != nil || manifest.ParentManifestDigest != "" {
				return model.Manifest{}, validationError("genesis has a parent", nil)
			}
			if manifest.Digest != metadata.GenesisManifestDigest {
				return model.Manifest{}, validationError("genesis digest does not match store metadata", nil)
			}
		} else {
			if manifest.ParentGeneration == nil || *manifest.ParentGeneration != generation-1 || manifest.ParentManifestDigest != current.Digest {
				return model.Manifest{}, validationError("manifest parent chain is invalid", nil)
			}
		}
		if err := validateManifestAndViews(root, manifest, views); err != nil {
			return model.Manifest{}, err
		}
		current = manifest
	}
	return copyManifest(current), nil
}

func loadMetadata(root *os.Root) (storeMetadata, error) {
	data, err := readRootMachineJSON(root, "store.json", nil)
	if err != nil {
		return storeMetadata{}, err
	}
	var metadata storeMetadata
	if err := decodeExact(data, &metadata); err != nil {
		return storeMetadata{}, validationError("decode store metadata", err)
	}
	return metadata, nil
}

func loadGeneration(generations *os.Root, name string) (model.Manifest, json.RawMessage, error) {
	generation, err := generations.OpenRoot(name)
	if err != nil {
		return model.Manifest{}, nil, validationError("open generation", err)
	}
	defer generation.Close()
	manifestBytes, err := readRootMachineJSON(generation, "manifest.json", nil)
	if err != nil {
		return model.Manifest{}, nil, err
	}
	var rawManifest struct {
		Schema               string                   `json:"schema"`
		Generation           uint64                   `json:"generation"`
		ParentGeneration     *uint64                  `json:"parent_generation,omitempty"`
		ParentManifestDigest string                   `json:"parent_manifest_digest,omitempty"`
		CurrentCandidates    []model.CandidatePointer `json:"current_candidates"`
		CurrentRecords       []model.RecordPointer    `json:"current_records"`
		Projections          []model.ProjectionRef    `json:"projections"`
		ViewsDigest          string                   `json:"views_digest"`
		Digest               string                   `json:"digest"`
	}
	if err := decodeExact(manifestBytes, &rawManifest); err != nil {
		return model.Manifest{}, nil, validationError("decode manifest", err)
	}
	if rawManifest.CurrentCandidates == nil || rawManifest.CurrentRecords == nil || rawManifest.Projections == nil {
		return model.Manifest{}, nil, validationError("manifest pointer collections must be arrays", nil)
	}
	manifest := model.Manifest{
		Schema:               rawManifest.Schema,
		Generation:           rawManifest.Generation,
		ParentGeneration:     rawManifest.ParentGeneration,
		ParentManifestDigest: rawManifest.ParentManifestDigest,
		CurrentCandidates:    rawManifest.CurrentCandidates,
		CurrentRecords:       rawManifest.CurrentRecords,
		Projections:          rawManifest.Projections,
		ViewsDigest:          rawManifest.ViewsDigest,
		Digest:               rawManifest.Digest,
	}
	views, err := readRootMachineJSON(generation, "views.json", nil)
	if err != nil {
		return model.Manifest{}, nil, err
	}
	return normalizeManifest(manifest), json.RawMessage(views), nil
}

func readRootDir(root *os.Root, path string) ([]os.DirEntry, error) {
	directory, err := root.Open(path)
	if err != nil {
		return nil, err
	}
	defer directory.Close()
	return directory.ReadDir(-1)
}

func decodeExact(data []byte, destination any) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	decoder.UseNumber()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if decoder.More() {
		return fmt.Errorf("trailing JSON")
	}
	if token, err := decoder.Token(); err == nil {
		return fmt.Errorf("trailing JSON token %v", token)
	}
	return nil
}

func validateManifestAndViews(root *os.Root, manifest model.Manifest, views json.RawMessage) error {
	if manifest.Schema != manifestSchema {
		return validationError("manifest schema is invalid", nil)
	}
	viewsDigest, err := canonical.Digest(views)
	if err != nil {
		return validationError("digest views", err)
	}
	if manifest.ViewsDigest != viewsDigest {
		return validationError("views digest mismatch", nil)
	}
	wantDigest, err := manifestDigest(manifest)
	if err != nil {
		return err
	}
	if manifest.Digest != wantDigest {
		return validationError("manifest self digest mismatch", nil)
	}
	return validateManifestReferences(root, manifest, nil)
}

func manifestDigest(manifest model.Manifest) (string, error) {
	manifest = normalizeManifest(manifest)
	manifest.Digest = ""
	digest, err := canonical.Digest(manifest)
	if err != nil {
		return "", validationError("digest manifest", err)
	}
	return digest, nil
}

func validateManifestReferences(root *os.Root, manifest model.Manifest, pending []preparedWrite) error {
	pendingByPath := make(map[string][]byte, len(pending))
	for _, write := range pending {
		pendingByPath[filepath.Clean(write.path)] = write.data
	}
	for _, pointer := range manifest.CurrentCandidates {
		if err := validateCandidatePointer(root, pointer, pendingByPath); err != nil {
			return validationError("referenced candidate revision is missing or invalid", err)
		}
	}
	for _, pointer := range manifest.CurrentRecords {
		if err := validateRecordPointer(root, pointer, pendingByPath); err != nil {
			return validationError("referenced record revision is missing or invalid", err)
		}
	}
	for _, ref := range manifest.Projections {
		if err := validateProjectionReference(root, ref, pendingByPath); err != nil {
			return validationError("referenced projection is missing or invalid", err)
		}
	}
	return nil
}

func validateCandidatePointer(root *os.Root, pointer model.CandidatePointer, pending map[string][]byte) error {
	if err := validateID("cand_", pointer.CandidateID); err != nil {
		return err
	}
	if err := validateID("crev_", pointer.Revision); err != nil {
		return err
	}
	if pointer.RecordID != "" {
		if err := validateID("kr_", pointer.RecordID); err != nil {
			return err
		}
	}
	if !pointer.Status.Valid() || !validDigest(pointer.Digest) {
		return validationError("candidate pointer status or digest is invalid", nil)
	}
	payloadPath := filepath.Join("candidates", pointer.CandidateID, "revisions", pointer.Revision, "candidate.json")
	payload, err := readRootMachineJSON(root, payloadPath, pending)
	if err != nil {
		return err
	}
	var revision model.CandidateRevision
	if err := decodeExact(payload, &revision); err != nil {
		return validationError("decode candidate revision", err)
	}
	if revision.CandidateID != pointer.CandidateID || revision.Revision != pointer.Revision || revision.Status != pointer.Status {
		return validationError("candidate pointer identity does not match payload", nil)
	}
	if revision.PublishedRecordID != "" {
		if err := validateID("kr_", revision.PublishedRecordID); err != nil {
			return validationError("candidate published record ID is invalid", err)
		}
	}
	if revision.PublishedRecordID != pointer.RecordID {
		return validationError("candidate published record binding does not match pointer", nil)
	}
	digest, err := canonical.Digest(json.RawMessage(payload))
	if err != nil || digest != pointer.Digest {
		return validationError("candidate pointer digest does not match payload", err)
	}
	if !validDigest(revision.L3Digest) {
		return validationError("candidate content digest is invalid", nil)
	}
	contentPath := filepath.Join("candidates", pointer.CandidateID, "revisions", pointer.Revision, "content.md")
	content, err := readRootBytes(root, contentPath, pending)
	if err != nil || rawDigest(content) != revision.L3Digest {
		return validationError("candidate content digest mismatch", err)
	}
	return nil
}

func validateRecordPointer(root *os.Root, pointer model.RecordPointer, pending map[string][]byte) error {
	if err := validateID("kr_", pointer.RecordID); err != nil {
		return err
	}
	if err := validateID("rev_", pointer.Revision); err != nil {
		return err
	}
	if !pointer.Status.Valid() || !validDigest(pointer.Digest) {
		return validationError("record pointer status or digest is invalid", nil)
	}
	payloadPath := filepath.Join("records", pointer.RecordID, "revisions", pointer.Revision, "record.json")
	payload, err := readRootMachineJSON(root, payloadPath, pending)
	if err != nil {
		return err
	}
	var revision model.RecordRevision
	if err := decodeExact(payload, &revision); err != nil {
		return validationError("decode record revision", err)
	}
	if revision.RecordID != pointer.RecordID || revision.Revision != pointer.Revision || revision.Status != pointer.Status {
		return validationError("record pointer identity does not match payload", nil)
	}
	digest, err := canonical.Digest(json.RawMessage(payload))
	if err != nil || digest != pointer.Digest {
		return validationError("record pointer digest does not match payload", err)
	}
	if !validDigest(revision.L3Digest) {
		return validationError("record content digest is invalid", nil)
	}
	contentPath := filepath.Join("records", pointer.RecordID, "revisions", pointer.Revision, "content.md")
	content, err := readRootBytes(root, contentPath, pending)
	if err != nil || rawDigest(content) != revision.L3Digest {
		return validationError("record content digest mismatch", err)
	}
	return nil
}

func validateProjectionReference(root *os.Root, ref model.ProjectionRef, pending map[string][]byte) error {
	if err := validateID("kr_", ref.RecordID); err != nil {
		return err
	}
	if err := validateID("rev_", ref.Revision); err != nil {
		return err
	}
	if !validDigest(ref.L1Digest) || !validDigest(ref.L2Digest) || !validDigest(ref.L3Digest) {
		return validationError("projection reference digests are invalid", nil)
	}
	record, err := readRecordRevision(root, ref.RecordID, ref.Revision, pending)
	if err != nil {
		return err
	}
	if !validDigest(record.L1Digest) || !validDigest(record.L2Digest) || !validDigest(record.L3Digest) || record.L3Digest != ref.L3Digest {
		return validationError("projection reference does not match record revision digests", nil)
	}
	for _, check := range []struct {
		name   string
		digest string
	}{
		{name: "l1.json", digest: ref.L1Digest},
		{name: "l2.json", digest: ref.L2Digest},
	} {
		path := filepath.Join("projections", ref.RecordID, ref.Revision, check.name)
		data, err := readRootMachineJSON(root, path, pending)
		if err != nil {
			return err
		}
		var projection model.Projection
		if err := decodeExact(data, &projection); err != nil {
			return validationError("decode projection", err)
		}
		if projection.RecordID != ref.RecordID || projection.Revision != ref.Revision ||
			projection.Status != record.Status || projection.KnowledgeType != record.KnowledgeType || projection.Zone != record.Zone || !reflect.DeepEqual(projection.Scope, record.Scope) ||
			!reflect.DeepEqual(projection.L1, record.L1) || !reflect.DeepEqual(projection.L2, record.L2) ||
			projection.L1Digest != record.L1Digest || projection.L2Digest != record.L2Digest || projection.L3Digest != ref.L3Digest {
			return validationError("projection binding mismatch", nil)
		}
		if l1Digest, err := canonical.Digest(projection.L1); err != nil || l1Digest != projection.L1Digest {
			return validationError("projection L1 digest mismatch", err)
		}
		if l2Digest, err := canonical.Digest(projection.L2); err != nil || l2Digest != projection.L2Digest {
			return validationError("projection L2 digest mismatch", err)
		}
		digest, err := canonical.Digest(json.RawMessage(data))
		if err != nil || digest != check.digest {
			return validationError("projection digest mismatch", err)
		}
	}
	contentPath := filepath.Join("records", ref.RecordID, "revisions", ref.Revision, "content.md")
	content, err := readRootBytes(root, contentPath, pending)
	if err != nil || rawDigest(content) != ref.L3Digest {
		return validationError("projection content digest mismatch", err)
	}
	return nil
}

func readRecordRevision(root *os.Root, recordID, revisionID string, pending map[string][]byte) (model.RecordRevision, error) {
	path := filepath.Join("records", recordID, "revisions", revisionID, "record.json")
	payload, err := readRootMachineJSON(root, path, pending)
	if err != nil {
		return model.RecordRevision{}, err
	}
	var revision model.RecordRevision
	if err := decodeExact(payload, &revision); err != nil {
		return model.RecordRevision{}, validationError("decode record revision", err)
	}
	if revision.RecordID != recordID || revision.Revision != revisionID {
		return model.RecordRevision{}, validationError("record revision identity mismatch", nil)
	}
	return revision, nil
}

func readRootMachineJSON(root *os.Root, path string, pending map[string][]byte) ([]byte, error) {
	data, err := readRootBytesLimited(root, path, pending, (1<<20)+1)
	if err != nil {
		return nil, err
	}
	if len(data) > 1<<20 {
		return nil, validationError("machine JSON exceeds size limit", nil)
	}
	canonicalBytes, err := canonical.Encode(json.RawMessage(data))
	if err != nil {
		return nil, validationError("invalid referenced machine JSON", err)
	}
	return canonicalBytes, nil
}

func readRootBytesLimited(root *os.Root, path string, pending map[string][]byte, limit int64) ([]byte, error) {
	if data, ok := pending[filepath.Clean(path)]; ok {
		if int64(len(data)) > limit {
			return bytes.Clone(data[:limit]), nil
		}
		return bytes.Clone(data), nil
	}
	file, err := root.Open(path)
	if err != nil {
		return nil, validationError("open referenced payload", err)
	}
	defer file.Close()
	data, err := io.ReadAll(io.LimitReader(file, limit))
	if err != nil {
		return nil, validationError("read referenced payload", err)
	}
	return data, nil
}

func readRootBytes(root *os.Root, path string, pending map[string][]byte) ([]byte, error) {
	if data, ok := pending[filepath.Clean(path)]; ok {
		return bytes.Clone(data), nil
	}
	data, err := root.ReadFile(path)
	if err != nil {
		return nil, validationError("read referenced payload", err)
	}
	return data, nil
}

func validDigest(value string) bool {
	if len(value) != len("sha256:")+64 || !strings.HasPrefix(value, "sha256:") {
		return false
	}
	for _, char := range value[len("sha256:"):] {
		if (char < '0' || char > '9') && (char < 'a' || char > 'f') {
			return false
		}
	}
	return true
}

func rawDigest(data []byte) string {
	digest := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(digest[:])
}
