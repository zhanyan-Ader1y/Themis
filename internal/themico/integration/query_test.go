// This file covers query/inspect behavior beyond the step-1 happy path in
// lifecycle_test.go: zone/type/status scoping, not_found for an unknown
// record, and budget_exceeded failing the whole request closed instead of
// truncating. Byte-budget exact-boundary arithmetic is covered in
// security_test.go alongside the other input-safety scenarios, since the
// brief groups it there.
package integration

import (
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/query"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/result"
)

// TestQueryScopesByZoneAndType publishes one design_decision record (zone
// project_knowledge) and one development_experience record (zone
// project_experience), then proves query only returns matches for the
// requested zone, and that an explicit Types filter further narrows within
// that zone.
func TestQueryScopesByZoneAndType(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	knowledgeRecord := publish(t, repository, prepareReadyCandidate(t, repository, model.TypeDesignDecision))
	standardRecord := publish(t, repository, prepareReadyCandidate(t, repository, model.TypeDevelopmentStandard))
	experienceRecord := publish(t, repository, prepareReadyCandidate(t, repository, model.TypeDevelopmentExperience))

	knowledgeZone := queryZone(t, repository, model.ZoneProjectKnowledge)
	if !containsRecord(knowledgeZone.Candidates, knowledgeRecord.RecordID) || !containsRecord(knowledgeZone.Candidates, standardRecord.RecordID) {
		t.Fatalf("project_knowledge query missing expected records: %+v", knowledgeZone.Candidates)
	}
	if containsRecord(knowledgeZone.Candidates, experienceRecord.RecordID) {
		t.Fatalf("project_knowledge query leaked a project_experience record: %+v", knowledgeZone.Candidates)
	}

	experienceZone := queryZone(t, repository, model.ZoneProjectExperience)
	if !containsRecord(experienceZone.Candidates, experienceRecord.RecordID) {
		t.Fatalf("project_experience query missing expected record: %+v", experienceZone.Candidates)
	}
	if containsRecord(experienceZone.Candidates, knowledgeRecord.RecordID) || containsRecord(experienceZone.Candidates, standardRecord.RecordID) {
		t.Fatalf("project_experience query leaked a project_knowledge record: %+v", experienceZone.Candidates)
	}

	dir := t.TempDir()
	typedRequest := query.Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		Types:              []model.KnowledgeType{model.TypeDevelopmentStandard},
		ContentBudgetBytes: 1 << 20,
	}
	path := writeJSONFile(t, dir, "query.json", typedRequest)
	envelope := mustRunCLI(t, result.StatusSucceeded, "query", "--root", repository, "--request", path)
	var typedResult query.Result
	decodeOutput(t, envelope, &typedResult)
	if len(typedResult.Candidates) != 1 || typedResult.Candidates[0].RecordID != standardRecord.RecordID {
		t.Fatalf("type-scoped query=%+v want exactly %s", typedResult.Candidates, standardRecord.RecordID)
	}
}

// TestInspectUnknownRecordIsNotFound proves inspect fails closed with
// not_found for a well-formed but nonexistent record ID, rather than
// returning an empty/zero item.
func TestInspectUnknownRecordIsNotFound(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

	dir := t.TempDir()
	request := query.InspectRequest{
		RecordIDs:          []string{"kr_00000000000000000000000000000000"},
		Depth:              1,
		ContentBudgetBytes: 4096,
	}
	path := writeJSONFile(t, dir, "inspect.json", request)
	mustRunCLI(t, result.StatusNotFound, "inspect", "--root", repository, "--request", path)
}

// TestQueryBudgetExceededFailsClosedWithoutTruncating proves that when the
// matching candidates would exceed content_budget_bytes, Search returns the
// whole request closed (budget_exceeded, empty candidates) instead of
// silently truncating to whatever fits.
func TestQueryBudgetExceededFailsClosedWithoutTruncating(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)
	publish(t, repository, prepareReadyCandidate(t, repository, model.TypeDesignDecision))

	dir := t.TempDir()
	request := query.Request{Zones: []model.Zone{model.ZoneProjectKnowledge}, ContentBudgetBytes: 1}
	path := writeJSONFile(t, dir, "query.json", request)
	envelope := mustRunCLI(t, result.StatusBudgetExceeded, "query", "--root", repository, "--request", path)
	var res query.Result
	decodeOutput(t, envelope, &res)
	if len(res.Candidates) != 0 {
		t.Fatalf("budget_exceeded query returned %d candidates, want a fully closed empty result", len(res.Candidates))
	}
	if len(res.Trace.SelectedIDs) != 0 || len(res.Trace.ExcludedIDs) == 0 {
		t.Fatalf("budget_exceeded trace=%+v want every candidate excluded, none selected", res.Trace)
	}
}
