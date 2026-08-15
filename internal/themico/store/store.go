package store

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

var (
	ErrValidation   = errors.New("themico store validation failed")
	ErrPrecondition = errors.New("themico store precondition failed")
	ErrConflict     = errors.New("themico store conflict")
	ErrNotFound     = errors.New("themico store object not found")
)

const (
	storeSchema    = "themico/store"
	manifestSchema = "themico/manifest"

	// packageName is the Themico package directory installed at the repository root.
	packageName = ".themico"
	// coreName holds the control plane: the Skill references and type factories.
	coreName = "core"
	// workspaceName holds the governed store this package writes.
	workspaceName = "workspace"
)

// WorkspaceRoot returns the governed store root inside the Themico package.
func WorkspaceRoot(root string) string {
	return filepath.Join(root, packageName, workspaceName)
}

// CoreRoot returns the control-plane root inside the Themico package.
func CoreRoot(root string) string {
	return filepath.Join(root, packageName, coreName)
}

type Options struct {
	Clock                  func() time.Time
	NewID                  func(prefix string) (string, error)
	BeforeGenerationRename func() error
}

type ImmutableWrite struct {
	Path string
	Data []byte
}

type CommitPlan struct {
	ExpectedGeneration uint64
	Writes             []ImmutableWrite
	Manifest           model.Manifest
	Views              json.RawMessage
}

type preparedWrite struct {
	path string
	data []byte
}

type Store struct {
	root string
	opts Options
}

type storeMetadata struct {
	Schema                string `json:"schema"`
	StoreID               string `json:"store_id"`
	CreatedAt             string `json:"created_at"`
	GenesisManifestDigest string `json:"genesis_manifest_digest"`
}

func Init(root string, opts Options) (*Store, error) {
	opts = optionsWithDefaults(opts)
	repository, err := os.OpenRoot(root)
	if err != nil {
		return nil, fmt.Errorf("open initialization parent: %w", err)
	}
	defer repository.Close()

	// The package directory may already carry an installed control plane, so
	// initialization owns the workspace only. Directories created here are removed
	// again if initialization fails, leaving the repository exactly as it was.
	published := false
	switch err := repository.Mkdir(packageName, 0o700); {
	case err == nil:
		// Durably record the new package entry before anything is published inside it.
		if err := syncRootDir(repository, "."); err != nil {
			return nil, err
		}
		defer func() {
			// Remove only a package this call created and left empty; a concurrent
			// writer's contents must never be discarded.
			if !published {
				_ = repository.Remove(packageName)
			}
		}()
	case !errors.Is(err, os.ErrExist):
		return nil, fmt.Errorf("create package directory: %w", err)
	}
	parent, err := repository.OpenRoot(packageName)
	if err != nil {
		return nil, fmt.Errorf("open package directory: %w", err)
	}
	defer parent.Close()
	if _, err := parent.Lstat(workspaceName); err == nil {
		return nil, fmt.Errorf("%w: store already exists", ErrPrecondition)
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("%w: inspect store root: %v", ErrPrecondition, err)
	}
	switch err := parent.Mkdir(coreName, 0o700); {
	case err == nil:
		if err := syncRootDir(parent, "."); err != nil {
			return nil, err
		}
		defer func() {
			// Removing the empty control plane this call added runs before the
			// package cleanup above, so a package created here can then be removed.
			if !published {
				_ = parent.Remove(coreName)
			}
		}()
	case !errors.Is(err, os.ErrExist):
		return nil, fmt.Errorf("create control plane directory: %w", err)
	}

	operationID, err := opts.NewID("op_")
	if err != nil {
		return nil, fmt.Errorf("create store identity: %w", err)
	}
	if err := validateID("op_", operationID); err != nil {
		return nil, err
	}
	stagingName := workspaceName + ".init-" + operationID
	if err := parent.Mkdir(stagingName, 0o700); err != nil {
		if errors.Is(err, os.ErrExist) {
			return nil, fmt.Errorf("%w: initialization staging exists", ErrPrecondition)
		}
		return nil, fmt.Errorf("create initialization staging: %w", err)
	}
	defer func() {
		if !published {
			_ = parent.RemoveAll(stagingName)
		}
	}()
	staging, err := parent.OpenRoot(stagingName)
	if err != nil {
		return nil, fmt.Errorf("open initialization staging: %w", err)
	}
	defer staging.Close()

	for _, directory := range []string{"candidates", "records", "projections", "preparations", "assessments", "approvals", "generations"} {
		if err := staging.Mkdir(directory, 0o700); err != nil {
			return nil, fmt.Errorf("create store directory %s: %w", directory, err)
		}
	}
	views := json.RawMessage(`{}`)
	viewsBytes, err := canonical.Encode(views)
	if err != nil {
		return nil, fmt.Errorf("canonicalize genesis views: %w", err)
	}
	viewsDigest, err := canonical.Digest(views)
	if err != nil {
		return nil, fmt.Errorf("digest genesis views: %w", err)
	}
	manifest := normalizeManifest(model.Manifest{
		Schema:            manifestSchema,
		Generation:        0,
		CurrentCandidates: []model.CandidatePointer{},
		CurrentRecords:    []model.RecordPointer{},
		Projections:       []model.ProjectionRef{},
		ViewsDigest:       viewsDigest,
	})
	manifest.Digest, err = manifestDigest(manifest)
	if err != nil {
		return nil, err
	}
	manifestBytes, err := canonical.Encode(manifest)
	if err != nil {
		return nil, fmt.Errorf("canonicalize genesis manifest: %w", err)
	}
	metadata := storeMetadata{
		Schema:                storeSchema,
		StoreID:               operationID,
		CreatedAt:             opts.Clock().UTC().Format(time.RFC3339Nano),
		GenesisManifestDigest: manifest.Digest,
	}
	metadataBytes, err := canonical.Encode(metadata)
	if err != nil {
		return nil, fmt.Errorf("canonicalize store metadata: %w", err)
	}

	genesis := filepath.Join("generations", generationName(0))
	if err := staging.Mkdir(genesis, 0o700); err != nil {
		return nil, fmt.Errorf("create genesis generation: %w", err)
	}
	if err := writeNewSyncedRoot(staging, "store.json", metadataBytes); err != nil {
		return nil, err
	}
	if err := writeNewSyncedRoot(staging, filepath.Join(genesis, "manifest.json"), manifestBytes); err != nil {
		return nil, err
	}
	if err := writeNewSyncedRoot(staging, filepath.Join(genesis, "views.json"), viewsBytes); err != nil {
		return nil, err
	}
	if err := syncRootDir(staging, genesis); err != nil {
		return nil, err
	}
	if err := syncRootDir(staging, "generations"); err != nil {
		return nil, err
	}
	if err := syncRootDir(parent, stagingName); err != nil {
		return nil, err
	}
	if err := renameRootNoReplace(parent, stagingName, workspaceName); err != nil {
		if errors.Is(err, os.ErrExist) {
			return nil, fmt.Errorf("%w: store appeared during initialization", ErrPrecondition)
		}
		return nil, fmt.Errorf("publish store: %w", err)
	}
	published = true
	if err := syncRootDir(parent, "."); err != nil {
		return nil, err
	}
	return &Store{root: WorkspaceRoot(root), opts: opts}, nil
}

func Open(root string, opts Options) (*Store, error) {
	store := &Store{root: WorkspaceRoot(root), opts: optionsWithDefaults(opts)}
	if _, err := store.loadCurrent(); err != nil {
		return nil, err
	}
	return store, nil
}

func (s *Store) Root() string {
	return s.root
}

// RepositoryRoot returns the repository directory containing the Themico package.
func (s *Store) RepositoryRoot() string {
	return filepath.Dir(filepath.Dir(s.root))
}

// AllocateID creates an ID using the Store's configured source.
func (s *Store) AllocateID(prefix string) (string, error) {
	value, err := s.opts.NewID(prefix)
	if err != nil {
		return "", err
	}
	if err := validateID(prefix, value); err != nil {
		return "", err
	}
	return value, nil
}

// Now returns the Store's configured clock in UTC.
func (s *Store) Now() time.Time {
	return s.opts.Clock().UTC()
}

// CurrentState returns the current manifest and its exact views payload.
func (s *Store) CurrentState() (model.Manifest, json.RawMessage, error) {
	manifest, views, err := s.loadCurrentState()
	if err != nil {
		return model.Manifest{}, nil, err
	}
	return copyManifest(manifest), bytes.Clone(views), nil
}

func (s *Store) Current() (model.Manifest, error) {
	manifest, err := s.loadCurrent()
	if err != nil {
		return model.Manifest{}, err
	}
	return copyManifest(manifest), nil
}

func (s *Store) Commit(ctx context.Context, plan CommitPlan) (model.Manifest, error) {
	if err := ctx.Err(); err != nil {
		return model.Manifest{}, err
	}
	current, err := s.loadCurrent()
	if err != nil {
		return model.Manifest{}, err
	}
	if plan.ExpectedGeneration != current.Generation {
		return model.Manifest{}, fmt.Errorf("%w: expected generation %d, current %d", ErrConflict, plan.ExpectedGeneration, current.Generation)
	}
	if err := ctx.Err(); err != nil {
		return model.Manifest{}, err
	}

	viewsBytes, err := canonical.Encode(plan.Views)
	if err != nil {
		return model.Manifest{}, validationError("invalid views", err)
	}
	viewsDigest, err := canonical.Digest(plan.Views)
	if err != nil {
		return model.Manifest{}, validationError("digest views", err)
	}
	parentGeneration := current.Generation
	manifest := normalizeManifest(plan.Manifest)
	manifest.Schema = manifestSchema
	manifest.Generation = current.Generation + 1
	manifest.ParentGeneration = &parentGeneration
	manifest.ParentManifestDigest = current.Digest
	manifest.ViewsDigest = viewsDigest
	manifest.Digest = ""
	manifest.Digest, err = manifestDigest(manifest)
	if err != nil {
		return model.Manifest{}, err
	}
	manifestBytes, err := canonical.Encode(manifest)
	if err != nil {
		return model.Manifest{}, validationError("canonicalize manifest", err)
	}

	prepared := make([]preparedWrite, 0, len(plan.Writes))
	seen := make(map[string]struct{}, len(plan.Writes))
	for _, write := range plan.Writes {
		path, err := validateImmutablePath(write.Path)
		if err != nil {
			return model.Manifest{}, err
		}
		key := filepath.Clean(path)
		if _, duplicate := seen[key]; duplicate {
			return model.Manifest{}, validationError("duplicate immutable target", nil)
		}
		seen[key] = struct{}{}
		data := bytes.Clone(write.Data)
		if filepath.Ext(path) == ".json" {
			data, err = canonical.Encode(json.RawMessage(data))
			if err != nil {
				return model.Manifest{}, validationError("invalid immutable machine JSON", err)
			}
		}
		prepared = append(prepared, preparedWrite{path: path, data: data})
	}
	root, err := os.OpenRoot(s.root)
	if err != nil {
		return model.Manifest{}, validationError("open store root", err)
	}
	defer root.Close()
	if err := validateManifestReferences(root, manifest, prepared); err != nil {
		return model.Manifest{}, err
	}
	if err := ctx.Err(); err != nil {
		return model.Manifest{}, err
	}

	for _, write := range prepared {
		if err := ctx.Err(); err != nil {
			return model.Manifest{}, err
		}
		if err := writeImmutable(root, write.path, write.data); err != nil {
			return model.Manifest{}, err
		}
	}

	generations, err := root.OpenRoot("generations")
	if err != nil {
		return model.Manifest{}, validationError("open generations root", err)
	}
	defer generations.Close()
	operationID, err := s.opts.NewID("op_")
	if err != nil {
		return model.Manifest{}, fmt.Errorf("create generation operation ID: %w", err)
	}
	if err := validateID("op_", operationID); err != nil {
		return model.Manifest{}, err
	}
	stagingName := ".staging-" + operationID
	if err := generations.Mkdir(stagingName, 0o700); err != nil {
		return model.Manifest{}, fmt.Errorf("create generation staging: %w", err)
	}
	defer generations.RemoveAll(stagingName)
	staging, err := generations.OpenRoot(stagingName)
	if err != nil {
		return model.Manifest{}, validationError("open generation staging", err)
	}
	defer staging.Close()
	if err := writeNewSyncedRoot(staging, "manifest.json", manifestBytes); err != nil {
		return model.Manifest{}, err
	}
	if err := writeNewSyncedRoot(staging, "views.json", viewsBytes); err != nil {
		return model.Manifest{}, err
	}
	if err := syncRootDir(generations, stagingName); err != nil {
		return model.Manifest{}, err
	}
	if err := syncRootDir(root, "generations"); err != nil {
		return model.Manifest{}, err
	}
	if err := ctx.Err(); err != nil {
		return model.Manifest{}, err
	}
	if s.opts.BeforeGenerationRename != nil {
		if err := s.opts.BeforeGenerationRename(); err != nil {
			return model.Manifest{}, fmt.Errorf("before generation rename: %w", err)
		}
	}
	if err := ctx.Err(); err != nil {
		return model.Manifest{}, err
	}
	finalName := generationName(manifest.Generation)
	if err := renameRootNoReplace(generations, stagingName, finalName); err != nil {
		if errors.Is(err, os.ErrExist) {
			return model.Manifest{}, fmt.Errorf("%w: generation %d already exists", ErrConflict, manifest.Generation)
		}
		return model.Manifest{}, fmt.Errorf("publish generation: %w", err)
	}
	if err := syncRootDir(root, "generations"); err != nil {
		return model.Manifest{}, err
	}
	return copyManifest(manifest), nil
}

func optionsWithDefaults(opts Options) Options {
	if opts.Clock == nil {
		opts.Clock = func() time.Time { return time.Now().UTC() }
	}
	if opts.NewID == nil {
		opts.NewID = randomID
	}
	return opts
}

func randomID(prefix string) (string, error) {
	allowed := map[string]struct{}{
		"op_": {}, "cand_": {}, "crev_": {}, "kr_": {}, "rev_": {}, "prep_": {}, "assess_": {},
	}
	if _, ok := allowed[prefix]; !ok {
		return "", fmt.Errorf("unsupported ID prefix %q", prefix)
	}
	var bytes [16]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return "", fmt.Errorf("read random ID bytes: %w", err)
	}
	return prefix + hex.EncodeToString(bytes[:]), nil
}

func validateID(prefix, value string) error {
	if len(value) != len(prefix)+32 || value[:len(prefix)] != prefix {
		return validationError("ID has invalid format", nil)
	}
	for _, char := range value[len(prefix):] {
		if (char < '0' || char > '9') && (char < 'a' || char > 'f') {
			return validationError("ID has invalid lowercase hexadecimal suffix", nil)
		}
	}
	return nil
}

func normalizeManifest(value model.Manifest) model.Manifest {
	value = model.NormalizeManifest(value)
	if value.CurrentCandidates == nil {
		value.CurrentCandidates = []model.CandidatePointer{}
	}
	if value.CurrentRecords == nil {
		value.CurrentRecords = []model.RecordPointer{}
	}
	if value.Projections == nil {
		value.Projections = []model.ProjectionRef{}
	}
	return value
}

func copyManifest(value model.Manifest) model.Manifest {
	value = normalizeManifest(value)
	if value.ParentGeneration != nil {
		parent := *value.ParentGeneration
		value.ParentGeneration = &parent
	}
	if value.CurrentCandidates == nil {
		value.CurrentCandidates = []model.CandidatePointer{}
	}
	if value.CurrentRecords == nil {
		value.CurrentRecords = []model.RecordPointer{}
	}
	if value.Projections == nil {
		value.Projections = []model.ProjectionRef{}
	}
	return value
}

func writeImmutable(root *os.Root, relativePath string, data []byte) error {
	parent := filepath.Dir(relativePath)
	if err := root.MkdirAll(parent, 0o700); err != nil {
		return validationError("create immutable parent", err)
	}
	if info, err := root.Lstat(relativePath); err == nil {
		if info.IsDir() {
			return validationError("immutable target is a directory", nil)
		}
		return fmt.Errorf("%w: immutable target exists", ErrPrecondition)
	} else if !errors.Is(err, os.ErrNotExist) {
		return validationError("inspect immutable target", err)
	}
	if err := writeNewSyncedRoot(root, relativePath, data); err != nil {
		if errors.Is(err, os.ErrExist) {
			return fmt.Errorf("%w: immutable target exists", ErrPrecondition)
		}
		return validationError("write immutable payload", err)
	}
	if err := syncRootDir(root, parent); err != nil {
		return err
	}
	return nil
}

func writeNewSyncedRoot(root *os.Root, path string, data []byte) error {
	file, err := root.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		return err
	}
	return writeAndSyncFile(file, path, data)
}

func writeAndSyncFile(file *os.File, path string, data []byte) error {
	closed := false
	defer func() {
		if !closed {
			_ = file.Close()
		}
	}()
	if _, err := file.Write(data); err != nil {
		return fmt.Errorf("write %s: %w", path, err)
	}
	if err := file.Sync(); err != nil {
		return fmt.Errorf("sync %s: %w", path, err)
	}
	if err := file.Close(); err != nil {
		return fmt.Errorf("close %s: %w", path, err)
	}
	closed = true
	return nil
}
