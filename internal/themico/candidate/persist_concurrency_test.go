package candidate

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"sync/atomic"
	"testing"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestReviseReturnsItsCommittedRevisionWhenCurrentAdvancesBeforeReturn(t *testing.T) {
	fixture := newConcurrencyFixture(t)
	writeConcurrencySource(t, fixture.root, "docs/source.txt", []byte("source"))
	created := mustConcurrencyCreate(t, fixture.service, concurrencyCreateRequest())

	firstCommitted := make(chan struct{})
	releaseFirstReturn := make(chan struct{})
	var commits atomic.Uint64
	service := New(fixture.store)
	service.commit = func(ctx context.Context, plan store.CommitPlan) (model.Manifest, error) {
		manifest, err := fixture.store.Commit(ctx, plan)
		if err != nil {
			return model.Manifest{}, err
		}
		if commits.Add(1) == 1 {
			close(firstCommitted)
			<-releaseFirstReturn
		}
		return manifest, nil
	}

	firstRequest := concurrencyReviseRequest(created)
	firstRequest.ContentMarkdown = []byte("# R1\n")
	firstRequest.L1.Triggers = []string{"r1-trigger"}
	firstRequest.L2.Payload = json.RawMessage(`{"symptoms":["r1-symptom"],"preconditions":["local store"],"observed_facts":["revisions are immutable"],"recommended_action":["commit a new generation"],"evidence_strength":"tested","risks":["stale writers"],"stop_conditions":["conflict"]}`)
	firstRequest.Relations = []model.Relation{{Type: model.RelationRelatedTo, TargetRecordID: "kr_11111111111111111111111111111111", TargetRecordRevision: "rev_11111111111111111111111111111111"}}
	firstResult := make(chan model.CandidateRevision, 1)
	firstErr := make(chan error, 1)
	go func() {
		revision, err := service.Revise(context.Background(), firstRequest)
		firstResult <- revision
		firstErr <- err
	}()

	<-firstCommitted
	committedR1 := mustConcurrencyInspect(t, service, created.CandidateID)
	secondRequest := concurrencyReviseRequest(committedR1)
	secondRequest.ContentMarkdown = []byte("# R2\n")
	r2 := mustConcurrencyRevise(t, service, secondRequest)
	close(releaseFirstReturn)

	r1 := <-firstResult
	if err := <-firstErr; err != nil {
		t.Fatal(err)
	}
	if r1.Revision != committedR1.Revision || !bytes.Equal(r1.ContentMarkdown, []byte("# R1\n")) {
		t.Fatalf("first revise result=%+v committed R1=%+v", r1, committedR1)
	}
	if !reflect.DeepEqual(r1, committedR1) {
		t.Fatalf("first revise result=%+v want exact committed R1=%+v", r1, committedR1)
	}

	firstRequest.ContentMarkdown[0] = 'X'
	firstRequest.L1.Triggers[0] = "caller-mutated"
	firstRequest.L2.Payload[0] = '['
	firstRequest.Relations[0].TargetRecordRevision = "rev_22222222222222222222222222222222"
	if !bytes.Equal(r1.ContentMarkdown, []byte("# R1\n")) || r1.L1.Triggers[0] != "r1-trigger" || r1.L2.Payload[0] != '{' || r1.Relations[0].TargetRecordRevision != "rev_11111111111111111111111111111111" {
		t.Fatalf("first revise result aliases caller input: %+v", r1)
	}

	current := mustConcurrencyInspect(t, service, created.CandidateID)
	if current.Revision != r2.Revision {
		t.Fatalf("current revision=%q want R2 %q", current.Revision, r2.Revision)
	}
	if r1.Revision == r2.Revision {
		t.Fatalf("first revise returned R2 %q instead of its committed R1 %q", r1.Revision, committedR1.Revision)
	}
}

type concurrencyFixture struct {
	root    string
	store   *store.Store
	service *Service
}

func newConcurrencyFixture(t *testing.T) concurrencyFixture {
	t.Helper()
	root := t.TempDir()
	var counter atomic.Uint64
	st, err := store.Init(root, store.Options{
		Clock: func() time.Time { return time.Date(2026, 8, 4, 1, 2, 3, 456789000, time.UTC) },
		NewID: func(prefix string) (string, error) {
			return fmt.Sprintf("%s%032x", prefix, counter.Add(1)), nil
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	return concurrencyFixture{root: root, store: st, service: New(st)}
}

func concurrencyCreateRequest() CreateRequest {
	return CreateRequest{
		Zone:                    model.ZoneProjectExperience,
		Scope:                   model.Scope{Project: "Themis", Domains: []string{"core"}, ArchitectureUnits: []string{"themico"}, Features: []string{"candidates"}},
		ProposedType:            model.TypeDevelopmentExperience,
		ClassificationRationale: "Observed reusable implementation behavior",
		SourcePaths:             []string{"docs/source.txt"},
		Relations:               []model.Relation{{Type: model.RelationRelatedTo, TargetRecordID: "kr_11111111111111111111111111111111"}},
		L1:                      model.L1{Title: "Candidate lifecycle", Summary: "Bind candidate revisions", Triggers: []string{"candidate"}, Tags: []string{"themico"}},
		L2: model.L2{
			CoreConclusion: "Use immutable revisions",
			ApplicableWhen: []string{"creating candidates"}, NotApplicableWhen: []string{}, Impact: []string{"storage"}, EvidenceSummary: []string{"tests"}, UpgradeWhen: []string{"full detail needed"},
			Payload: json.RawMessage(`{"symptoms":["drift"],"preconditions":["local store"],"observed_facts":["revisions are immutable"],"recommended_action":["commit a new generation"],"evidence_strength":"tested","risks":["stale writers"],"stop_conditions":["conflict"]}`),
		},
		ProposedBy:      "agent:proposal-writer",
		ContentMarkdown: []byte("# Candidate lifecycle\n\nbody\n"),
	}
}

func concurrencyReviseRequest(current model.CandidateRevision) ReviseRequest {
	paths := make([]string, len(current.Sources))
	for index, source := range current.Sources {
		paths[index] = source.Path
	}
	return ReviseRequest{
		CandidateID: current.CandidateID, ExpectedRevision: current.Revision, ProposedType: current.ProposedType,
		L1: current.L1, L2: current.L2, SourcePaths: paths, Relations: current.Relations,
		ContentMarkdown: bytes.Clone(current.ContentMarkdown), RevisedBy: "agent:revision-writer",
	}
}

func mustConcurrencyCreate(t *testing.T, service *Service, request CreateRequest) model.CandidateRevision {
	t.Helper()
	created, err := service.Create(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	return created
}

func mustConcurrencyRevise(t *testing.T, service *Service, request ReviseRequest) model.CandidateRevision {
	t.Helper()
	revised, err := service.Revise(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	return revised
}

func mustConcurrencyInspect(t *testing.T, service *Service, candidateID string) model.CandidateRevision {
	t.Helper()
	current, err := service.Inspect(context.Background(), candidateID)
	if err != nil {
		t.Fatal(err)
	}
	return current
}

func writeConcurrencySource(t *testing.T, root, relative string, data []byte) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		t.Fatal(err)
	}
}
