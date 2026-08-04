package model

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
)

// Factory is the explicit, closed registry entry for one persisted knowledge type.
type Factory struct {
	Type             KnowledgeType
	Zone             Zone
	L3Headings       []string
	DecodePayload    func([]byte) (any, error)
	NormalizePayload func(any) (any, error)
}

var factoryRegistry = []Factory{
	{
		Type: TypeDesignDecision,
		Zone: ZoneProjectKnowledge,
		L3Headings: []string{
			"背景与问题",
			"决策",
			"约束",
			"备选方案",
			"后果",
			"证据与来源",
			"重新评估条件",
		},
		DecodePayload:    decodeDesignDecision,
		NormalizePayload: normalizeDesignDecision,
	},
	{
		Type: TypeDevelopmentStandard,
		Zone: ZoneProjectKnowledge,
		L3Headings: []string{
			"目的与适用范围",
			"触发条件",
			"必须执行",
			"禁止行为",
			"验证方法",
			"例外策略",
			"证据与来源",
		},
		DecodePayload:    decodeDevelopmentStandard,
		NormalizePayload: normalizeDevelopmentStandard,
	},
	{
		Type: TypeDevelopmentExperience,
		Zone: ZoneProjectExperience,
		L3Headings: []string{
			"背景与前置条件",
			"观察到的现象",
			"已确认事实",
			"建议行动",
			"风险与停止条件",
			"证据与强度",
			"适用与不适用条件",
		},
		DecodePayload:    decodeDevelopmentExperience,
		NormalizePayload: normalizeDevelopmentExperience,
	},
}

// LookupFactory selects a factory from persisted knowledge_type only.
func LookupFactory(knowledgeType KnowledgeType) (Factory, bool) {
	for _, factory := range factoryRegistry {
		if factory.Type == knowledgeType {
			return copyFactory(factory), true
		}
	}
	return Factory{}, false
}

// Factories returns a stable-order copy of the closed registry.
func Factories() []Factory {
	factories := make([]Factory, len(factoryRegistry))
	for i, factory := range factoryRegistry {
		factories[i] = copyFactory(factory)
	}
	return factories
}

func copyFactory(factory Factory) Factory {
	factory.L3Headings = append([]string(nil), factory.L3Headings...)
	return factory
}

func decodeDesignDecision(data []byte) (any, error) {
	var value DesignDecisionL2
	if err := decodeStrict(data, &value); err != nil {
		return nil, err
	}
	return normalizeDesignDecision(value)
}

func normalizeDesignDecision(payload any) (any, error) {
	value, ok := payload.(DesignDecisionL2)
	if !ok {
		return nil, fmt.Errorf("payload type %T does not match %s", payload, TypeDesignDecision)
	}
	value.AffectedUnits = NormalizeStrings(value.AffectedUnits)
	value.Constraints = NormalizeStrings(value.Constraints)
	value.Alternatives = NormalizeStrings(value.Alternatives)
	value.Consequences = NormalizeStrings(value.Consequences)
	value.ReevaluateWhen = NormalizeStrings(value.ReevaluateWhen)
	return value, nil
}

func decodeDevelopmentStandard(data []byte) (any, error) {
	var value DevelopmentStandardL2
	if err := decodeStrict(data, &value); err != nil {
		return nil, err
	}
	return normalizeDevelopmentStandard(value)
}

func normalizeDevelopmentStandard(payload any) (any, error) {
	value, ok := payload.(DevelopmentStandardL2)
	if !ok {
		return nil, fmt.Errorf("payload type %T does not match %s", payload, TypeDevelopmentStandard)
	}
	value.LifecycleStages = NormalizeStrings(value.LifecycleStages)
	value.Trigger = NormalizeStrings(value.Trigger)
	value.RequiredActions = NormalizeStrings(value.RequiredActions)
	value.ProhibitedActions = NormalizeStrings(value.ProhibitedActions)
	value.Verification = NormalizeStrings(value.Verification)
	value.ExceptionPolicy = NormalizeStrings(value.ExceptionPolicy)
	return value, nil
}

func decodeDevelopmentExperience(data []byte) (any, error) {
	var value DevelopmentExperienceL2
	if err := decodeStrict(data, &value); err != nil {
		return nil, err
	}
	return normalizeDevelopmentExperience(value)
}

func normalizeDevelopmentExperience(payload any) (any, error) {
	value, ok := payload.(DevelopmentExperienceL2)
	if !ok {
		return nil, fmt.Errorf("payload type %T does not match %s", payload, TypeDevelopmentExperience)
	}
	value.Symptoms = NormalizeStrings(value.Symptoms)
	value.Preconditions = NormalizeStrings(value.Preconditions)
	value.ObservedFacts = NormalizeStrings(value.ObservedFacts)
	value.RecommendedAction = NormalizeStrings(value.RecommendedAction)
	value.Risks = NormalizeStrings(value.Risks)
	value.StopConditions = NormalizeStrings(value.StopConditions)
	return value, nil
}

func decodeStrict(data []byte, destination any) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
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
