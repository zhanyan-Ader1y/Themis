package model_test

import (
	"reflect"
	"testing"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

func TestRegistryHasExactlyThreeFactories(t *testing.T) {
	factories := model.Factories()
	if len(factories) != 3 {
		t.Fatalf("got %d factories", len(factories))
	}

	wantTypes := []model.KnowledgeType{
		model.TypeDesignDecision,
		model.TypeDevelopmentStandard,
		model.TypeDevelopmentExperience,
	}
	for i, wantType := range wantTypes {
		if factories[i].Type != wantType {
			t.Fatalf("factory[%d].Type = %q, want %q", i, factories[i].Type, wantType)
		}
	}

	cases := map[model.KnowledgeType]model.Zone{
		model.TypeDesignDecision:        model.ZoneProjectKnowledge,
		model.TypeDevelopmentStandard:   model.ZoneProjectKnowledge,
		model.TypeDevelopmentExperience: model.ZoneProjectExperience,
	}
	for typ, wantZone := range cases {
		factory, ok := model.LookupFactory(typ)
		if !ok || factory.Zone != wantZone {
			t.Fatalf("type=%s factory=%+v", typ, factory)
		}
	}
	if _, ok := model.LookupFactory("architecture"); ok {
		t.Fatal("unregistered type accepted")
	}

	factories[0].Type = "changed"
	fresh := model.Factories()
	if fresh[0].Type != model.TypeDesignDecision {
		t.Fatal("Factories exposed mutable registry storage")
	}
}

func TestFactoriesExposeExactL3Headings(t *testing.T) {
	cases := map[model.KnowledgeType][]string{
		model.TypeDesignDecision: {
			"背景与问题",
			"决策",
			"约束",
			"备选方案",
			"后果",
			"证据与来源",
			"重新评估条件",
		},
		model.TypeDevelopmentStandard: {
			"目的与适用范围",
			"触发条件",
			"必须执行",
			"禁止行为",
			"验证方法",
			"例外策略",
			"证据与来源",
		},
		model.TypeDevelopmentExperience: {
			"背景与前置条件",
			"观察到的现象",
			"已确认事实",
			"建议行动",
			"风险与停止条件",
			"证据与强度",
			"适用与不适用条件",
		},
	}

	for typ, want := range cases {
		factory, ok := model.LookupFactory(typ)
		if !ok {
			t.Fatalf("missing factory for %q", typ)
		}
		if !reflect.DeepEqual(factory.L3Headings, want) {
			t.Fatalf("type=%s headings=%q, want %q", typ, factory.L3Headings, want)
		}
	}
}

func TestStrictPayloadDecodeRejectsWrongTypeAndTrailingJSON(t *testing.T) {
	factory, ok := model.LookupFactory(model.TypeDesignDecision)
	if !ok {
		t.Fatal("missing design_decision factory")
	}

	if _, err := factory.DecodePayload([]byte(`{"affected_units":[],"constraints":[],"alternatives":[],"consequences":[],"reevaluate_when":[],"symptoms":[]}`)); err == nil {
		t.Fatal("design_decision payload accepted symptoms")
	}
	if _, err := factory.DecodePayload([]byte(`{"affected_units":[]} {"constraints":[]}`)); err == nil {
		t.Fatal("payload accepted trailing JSON")
	}
	if _, err := factory.DecodePayload([]byte(`{"affected_units":"api"}`)); err == nil {
		t.Fatal("payload accepted wrong field type")
	}
}

func TestStrictPayloadDecodeReturnsNormalizedTypedValue(t *testing.T) {
	factory, ok := model.LookupFactory(model.TypeDesignDecision)
	if !ok {
		t.Fatal("missing design_decision factory")
	}

	decoded, err := factory.DecodePayload([]byte(`{
		"affected_units":["worker","api","worker"],
		"constraints":["offline","deterministic","offline"],
		"alternatives":["sqlite","files","sqlite"],
		"consequences":["traceable","local","traceable"],
		"reevaluate_when":["scale","remote","scale"]
	}`))
	if err != nil {
		t.Fatal(err)
	}
	payload, ok := decoded.(model.DesignDecisionL2)
	if !ok {
		t.Fatalf("decoded type = %T", decoded)
	}
	want := model.DesignDecisionL2{
		AffectedUnits:  []string{"api", "worker"},
		Constraints:    []string{"deterministic", "offline"},
		Alternatives:   []string{"files", "sqlite"},
		Consequences:   []string{"local", "traceable"},
		ReevaluateWhen: []string{"remote", "scale"},
	}
	if !reflect.DeepEqual(payload, want) {
		t.Fatalf("payload = %#v, want %#v", payload, want)
	}
}

func TestLookupRoutesOnlyByPersistedKnowledgeType(t *testing.T) {
	record := model.RecordRevision{
		KnowledgeType: model.TypeDesignDecision,
		L1: model.L1{
			Title: "一次失败经验",
		},
	}
	factory, ok := model.LookupFactory(record.KnowledgeType)
	if !ok || factory.Type != model.TypeDesignDecision {
		t.Fatalf("factory = %+v, ok = %v", factory, ok)
	}
}

func TestNormalizationSortsAndDeduplicatesSetSemanticSlices(t *testing.T) {
	scope := model.NormalizeScope(model.Scope{
		Project:           "Themis",
		Domains:           []string{"store", "model", "store"},
		ArchitectureUnits: []string{"cli", "core", "cli"},
		Features:          []string{"query", "publish", "query"},
	})
	if !reflect.DeepEqual(scope.Domains, []string{"model", "store"}) {
		t.Fatalf("domains = %q", scope.Domains)
	}
	if !reflect.DeepEqual(scope.ArchitectureUnits, []string{"cli", "core"}) {
		t.Fatalf("architecture units = %q", scope.ArchitectureUnits)
	}
	if !reflect.DeepEqual(scope.Features, []string{"publish", "query"}) {
		t.Fatalf("features = %q", scope.Features)
	}

	l1 := model.NormalizeL1(model.L1{
		Title:    "Title",
		Summary:  "Summary",
		Triggers: []string{"z", "a", "z"},
		Tags:     []string{"go", "model", "go"},
	})
	if !reflect.DeepEqual(l1.Triggers, []string{"a", "z"}) || !reflect.DeepEqual(l1.Tags, []string{"go", "model"}) {
		t.Fatalf("l1 = %+v", l1)
	}

	l2 := model.NormalizeL2(model.L2{
		ApplicableWhen:    []string{"b", "a", "b"},
		NotApplicableWhen: []string{"z", "x", "z"},
		Impact:            []string{"runtime", "design", "runtime"},
		EvidenceSummary:   []string{"test", "spec", "test"},
		UpgradeWhen:       []string{"conflict", "detail", "conflict"},
	})
	if !reflect.DeepEqual(l2.ApplicableWhen, []string{"a", "b"}) ||
		!reflect.DeepEqual(l2.NotApplicableWhen, []string{"x", "z"}) ||
		!reflect.DeepEqual(l2.Impact, []string{"design", "runtime"}) ||
		!reflect.DeepEqual(l2.EvidenceSummary, []string{"spec", "test"}) ||
		!reflect.DeepEqual(l2.UpgradeWhen, []string{"conflict", "detail"}) {
		t.Fatalf("l2 = %+v", l2)
	}
}

func TestAllFactoryPayloadNormalizersAreStrictlyTyped(t *testing.T) {
	standardFactory, _ := model.LookupFactory(model.TypeDevelopmentStandard)
	standard, err := standardFactory.NormalizePayload(model.DevelopmentStandardL2{
		LifecycleStages:   []string{"review", "plan", "review"},
		Trigger:           []string{"change", "change"},
		RequiredActions:   []string{"test", "review", "test"},
		ProhibitedActions: []string{"guess", "guess"},
		Verification:      []string{"go test", "gofmt", "go test"},
		ExceptionPolicy:   []string{"approve", "approve"},
	})
	if err != nil {
		t.Fatal(err)
	}
	wantStandard := model.DevelopmentStandardL2{
		LifecycleStages:   []string{"plan", "review"},
		Trigger:           []string{"change"},
		RequiredActions:   []string{"review", "test"},
		ProhibitedActions: []string{"guess"},
		Verification:      []string{"go test", "gofmt"},
		ExceptionPolicy:   []string{"approve"},
	}
	if !reflect.DeepEqual(standard, wantStandard) {
		t.Fatalf("standard = %#v, want %#v", standard, wantStandard)
	}

	experienceFactory, _ := model.LookupFactory(model.TypeDevelopmentExperience)
	experience, err := experienceFactory.NormalizePayload(model.DevelopmentExperienceL2{
		Symptoms:          []string{"timeout", "timeout"},
		Preconditions:     []string{"windows", "local", "windows"},
		ObservedFacts:     []string{"exit 1", "exit 1"},
		RecommendedAction: []string{"inspect", "retry", "inspect"},
		EvidenceStrength:  "reproduced",
		Risks:             []string{"stale", "stale"},
		StopConditions:    []string{"third failure", "third failure"},
	})
	if err != nil {
		t.Fatal(err)
	}
	wantExperience := model.DevelopmentExperienceL2{
		Symptoms:          []string{"timeout"},
		Preconditions:     []string{"local", "windows"},
		ObservedFacts:     []string{"exit 1"},
		RecommendedAction: []string{"inspect", "retry"},
		EvidenceStrength:  "reproduced",
		Risks:             []string{"stale"},
		StopConditions:    []string{"third failure"},
	}
	if !reflect.DeepEqual(experience, wantExperience) {
		t.Fatalf("experience = %#v, want %#v", experience, wantExperience)
	}

	if _, err := standardFactory.NormalizePayload(model.DesignDecisionL2{}); err == nil {
		t.Fatal("standard factory accepted design decision payload")
	}
}

func TestEnumClosedSets(t *testing.T) {
	knowledgeTypes := []model.KnowledgeType{
		model.TypeDesignDecision,
		model.TypeDevelopmentStandard,
		model.TypeDevelopmentExperience,
	}
	for _, value := range knowledgeTypes {
		if !value.Valid() {
			t.Fatalf("knowledge type %q invalid", value)
		}
	}
	if model.KnowledgeType("architecture").Valid() {
		t.Fatal("unknown knowledge type valid")
	}

	zones := []model.Zone{model.ZoneProjectKnowledge, model.ZoneProjectExperience}
	for _, value := range zones {
		if !value.Valid() {
			t.Fatalf("zone %q invalid", value)
		}
	}
	if model.Zone("global").Valid() {
		t.Fatal("unknown zone valid")
	}

	candidateStatuses := []model.CandidateStatus{
		model.CandidateStatusProposed,
		model.CandidateStatusTypeConfirmed,
		model.CandidateStatusPublished,
		model.CandidateStatusAbandoned,
	}
	for _, value := range candidateStatuses {
		if !value.Valid() {
			t.Fatalf("candidate status %q invalid", value)
		}
	}

	recordStatuses := []model.RecordStatus{
		model.RecordStatusActive,
		model.RecordStatusSuperseded,
		model.RecordStatusDeprecated,
		model.RecordStatusArchived,
	}
	for _, value := range recordStatuses {
		if !value.Valid() {
			t.Fatalf("record status %q invalid", value)
		}
	}

	relations := []model.RelationType{
		model.RelationDependsOn,
		model.RelationConstrains,
		model.RelationDerivedFrom,
		model.RelationAppliesTo,
		model.RelationChallenges,
		model.RelationCorrects,
		model.RelationRecoversFrom,
		model.RelationFollows,
		model.RelationRelatedTo,
		model.RelationSupersedes,
	}
	for _, value := range relations {
		if !value.Valid() {
			t.Fatalf("relation type %q invalid", value)
		}
	}
	if model.RelationType("duplicates").Valid() {
		t.Fatal("unknown relation type valid")
	}
}

func TestFactoryHeadingsCannotMutateRegistry(t *testing.T) {
	factory, _ := model.LookupFactory(model.TypeDesignDecision)
	factory.L3Headings[0] = "changed"

	fresh, _ := model.LookupFactory(model.TypeDesignDecision)
	if fresh.L3Headings[0] != "背景与问题" {
		t.Fatal("LookupFactory exposed mutable heading storage")
	}
}
