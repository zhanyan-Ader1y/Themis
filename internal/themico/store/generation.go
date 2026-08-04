package store

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"unicode/utf8"

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
	metadata, err := loadMetadata(filepath.Join(s.root, "store.json"))
	if err != nil {
		return model.Manifest{}, err
	}
	if metadata.Schema != storeSchema {
		return model.Manifest{}, validationError("store metadata schema is invalid", nil)
	}
	if err := validateID("op_", metadata.StoreID); err != nil {
		return model.Manifest{}, err
	}
	if metadata.CreatedAt == "" {
		return model.Manifest{}, validationError("store creation time is empty", nil)
	}
	generationsRoot := filepath.Join(s.root, "generations")
	entries, err := os.ReadDir(generationsRoot)
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
		numbered[generation] = filepath.Join(generationsRoot, entry.Name())
		if generation > highest {
			highest = generation
		}
	}
	if _, ok := numbered[0]; !ok {
		return model.Manifest{}, validationError("generation zero is missing", nil)
	}

	var current model.Manifest
	for generation := uint64(0); generation <= highest; generation++ {
		root, ok := numbered[generation]
		if !ok {
			return model.Manifest{}, validationError("generation chain has a gap", nil)
		}
		manifest, views, err := loadGeneration(root)
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
		if err := validateManifestAndViews(s.root, manifest, views); err != nil {
			return model.Manifest{}, err
		}
		current = manifest
	}
	return copyManifest(current), nil
}

func loadMetadata(path string) (storeMetadata, error) {
	data, err := readMachineJSON(path)
	if err != nil {
		return storeMetadata{}, err
	}
	var metadata storeMetadata
	if err := decodeExact(data, &metadata); err != nil {
		return storeMetadata{}, validationError("decode store metadata", err)
	}
	return metadata, nil
}

func loadGeneration(root string) (model.Manifest, json.RawMessage, error) {
	manifestBytes, err := readMachineJSON(filepath.Join(root, "manifest.json"))
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
	views, err := readMachineJSON(filepath.Join(root, "views.json"))
	if err != nil {
		return model.Manifest{}, nil, err
	}
	return normalizeManifest(manifest), json.RawMessage(views), nil
}

func readMachineJSON(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, validationError("open machine JSON", err)
	}
	defer file.Close()
	limited := &limitedReader{reader: file, remaining: (1 << 20) + 1}
	data, err := limited.readAll()
	if err != nil {
		return nil, validationError("read machine JSON", err)
	}
	if len(data) > 1<<20 {
		return nil, validationError("machine JSON exceeds size limit", nil)
	}
	if !utf8.Valid(data) {
		return nil, validationError("machine JSON is not valid UTF-8", nil)
	}
	if _, err := canonical.Encode(json.RawMessage(data)); err != nil {
		return nil, validationError("invalid machine JSON", err)
	}
	return data, nil
}

type limitedReader struct {
	reader    *os.File
	remaining int
}

func (reader *limitedReader) readAll() ([]byte, error) {
	buffer := make([]byte, reader.remaining)
	total := 0
	for total < len(buffer) {
		count, err := reader.reader.Read(buffer[total:])
		total += count
		if errors.Is(err, os.ErrClosed) {
			return nil, err
		}
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				return nil, err
			}
			break
		}
		if count == 0 {
			break
		}
	}
	return buffer[:total], nil
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

func validateManifestAndViews(storeRoot string, manifest model.Manifest, views json.RawMessage) error {
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
	return validateManifestReferences(storeRoot, manifest, nil)
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

func validateManifestReferences(storeRoot string, manifest model.Manifest, pending []preparedWrite) error {
	pendingByPath := make(map[string][]byte, len(pending))
	for _, write := range pending {
		pendingByPath[filepath.Clean(write.path)] = write.data
	}
	for _, pointer := range manifest.CurrentCandidates {
		path := filepath.Join(storeRoot, "candidates", pointer.CandidateID, "revisions", pointer.Revision, "candidate.json")
		if err := requireReferencedPath(path, pendingByPath, true); err != nil {
			return validationError("referenced candidate revision is missing or invalid", err)
		}
	}
	for _, pointer := range manifest.CurrentRecords {
		path := filepath.Join(storeRoot, "records", pointer.RecordID, "revisions", pointer.Revision, "record.json")
		if err := requireReferencedPath(path, pendingByPath, true); err != nil {
			return validationError("referenced record revision is missing or invalid", err)
		}
	}
	for _, ref := range manifest.Projections {
		checks := []struct {
			path   string
			digest string
		}{
			{path: filepath.Join(storeRoot, "projections", ref.RecordID, ref.Revision, "l1.json"), digest: ref.L1Digest},
			{path: filepath.Join(storeRoot, "projections", ref.RecordID, ref.Revision, "l2.json"), digest: ref.L2Digest},
		}
		for _, check := range checks {
			if check.digest == "" {
				continue
			}
			data, ok := pendingByPath[filepath.Clean(check.path)]
			if !ok {
				var err error
				data, err = readMachineJSON(check.path)
				if err != nil {
					return validationError("referenced projection is missing or invalid", err)
				}
			}
			digest, err := canonical.Digest(json.RawMessage(data))
			if err != nil {
				return validationError("digest referenced projection", err)
			}
			if digest != check.digest {
				return validationError("referenced projection digest mismatch", nil)
			}
		}
		if ref.L3Digest != "" {
			path := filepath.Join(storeRoot, "records", ref.RecordID, "revisions", ref.Revision, "content.md")
			data, ok := pendingByPath[filepath.Clean(path)]
			if !ok {
				var err error
				data, err = os.ReadFile(path)
				if err != nil {
					return validationError("referenced record content is missing", err)
				}
			}
			digest := rawDigest(data)
			if digest != ref.L3Digest {
				return validationError("referenced record content digest mismatch", nil)
			}
		}
	}
	return nil
}

func requireReferencedPath(path string, pending map[string][]byte, machineJSON bool) error {
	if data, ok := pending[filepath.Clean(path)]; ok {
		if machineJSON {
			_, err := canonical.Encode(json.RawMessage(data))
			return err
		}
		return nil
	}
	if machineJSON {
		_, err := readMachineJSON(path)
		return err
	}
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	if info.IsDir() {
		return fmt.Errorf("referenced path is a directory")
	}
	return nil
}

func rawDigest(data []byte) string {
	digest := sha256.Sum256(data)
	return "sha256:" + hex.EncodeToString(digest[:])
}
