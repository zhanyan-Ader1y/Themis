package candidate

import (
	"bytes"
	"context"
	"encoding/json"
	"reflect"
	"sync/atomic"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

func TestReviseReturnsItsCommittedRevisionWhenCurrentAdvancesBeforeReturn(t *testing.T) {
	fixture := newFixture(t)
	writeSource(t, fixture.root, "docs/source.txt", []byte("source"))
	created := mustCreate(t, fixture.service, validCreateRequest())

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

	firstRequest := validReviseRequest(created)
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
	currentR1 := mustInspect(t, service, created.CandidateID)
	secondRequest := validReviseRequest(currentR1)
	secondRequest.ContentMarkdown = []byte("# R2\n")
	r2 := mustRevise(t, service, secondRequest)
	close(releaseFirstReturn)

	r1 := <-firstResult
	if err := <-firstErr; err != nil {
		t.Fatal(err)
	}
	if r1.Revision != currentR1.Revision || !bytes.Equal(r1.ContentMarkdown, []byte("# R1\n")) {
		t.Fatalf("first revise result=%+v committed R1=%+v", r1, currentR1)
	}
	if !reflect.DeepEqual(r1, currentR1) {
		t.Fatalf("first revise result=%+v want exact committed R1=%+v", r1, currentR1)
	}

	firstRequest.ContentMarkdown[0] = 'X'
	firstRequest.L1.Triggers[0] = "caller-mutated"
	firstRequest.L2.Payload[0] = '['
	firstRequest.Relations[0].TargetRecordRevision = "rev_22222222222222222222222222222222"
	if !bytes.Equal(r1.ContentMarkdown, []byte("# R1\n")) || r1.L1.Triggers[0] != "r1-trigger" || r1.L2.Payload[0] != '{' || r1.Relations[0].TargetRecordRevision != "rev_11111111111111111111111111111111" {
		t.Fatalf("first revise result aliases caller input: %+v", r1)
	}

	current := mustInspect(t, service, created.CandidateID)
	if current.Revision != r2.Revision {
		t.Fatalf("current revision=%q want R2 %q", current.Revision, r2.Revision)
	}
	if r1.Revision == r2.Revision {
		t.Fatalf("first revise returned R2 %q instead of its committed R1 %q", r1.Revision, currentR1.Revision)
	}
}
