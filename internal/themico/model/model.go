package model

import (
	"encoding/json"
	"slices"
)

// KnowledgeType is the closed set of knowledge identities routed by the factory registry.
type KnowledgeType string

const (
	TypeDesignDecision        KnowledgeType = "design_decision"
	TypeDevelopmentStandard   KnowledgeType = "development_standard"
	TypeDevelopmentExperience KnowledgeType = "development_experience"
)

func (value KnowledgeType) Valid() bool {
	switch value {
	case TypeDesignDecision, TypeDevelopmentStandard, TypeDevelopmentExperience:
		return true
	default:
		return false
	}
}

// Zone is the closed set of Themico knowledge storage zones.
type Zone string

const (
	ZoneProjectKnowledge  Zone = "project_knowledge"
	ZoneProjectExperience Zone = "project_experience"
)

func (value Zone) Valid() bool {
	switch value {
	case ZoneProjectKnowledge, ZoneProjectExperience:
		return true
	default:
		return false
	}
}

// CandidateStatus is the closed candidate lifecycle.
type CandidateStatus string

const (
	CandidateStatusProposed      CandidateStatus = "proposed"
	CandidateStatusTypeConfirmed CandidateStatus = "type_confirmed"
	CandidateStatusPublished     CandidateStatus = "published"
	CandidateStatusAbandoned     CandidateStatus = "abandoned"
)

func (value CandidateStatus) Valid() bool {
	switch value {
	case CandidateStatusProposed, CandidateStatusTypeConfirmed, CandidateStatusPublished, CandidateStatusAbandoned:
		return true
	default:
		return false
	}
}

// RecordStatus is the closed formal-record lifecycle.
type RecordStatus string

const (
	RecordStatusActive     RecordStatus = "active"
	RecordStatusSuperseded RecordStatus = "superseded"
	RecordStatusDeprecated RecordStatus = "deprecated"
	RecordStatusArchived   RecordStatus = "archived"
)

func (value RecordStatus) Valid() bool {
	switch value {
	case RecordStatusActive, RecordStatusSuperseded, RecordStatusDeprecated, RecordStatusArchived:
		return true
	default:
		return false
	}
}

// RelationType is the closed set of typed record relations.
type RelationType string

const (
	RelationDependsOn    RelationType = "depends_on"
	RelationConstrains   RelationType = "constrains"
	RelationDerivedFrom  RelationType = "derived_from"
	RelationAppliesTo    RelationType = "applies_to"
	RelationChallenges   RelationType = "challenges"
	RelationCorrects     RelationType = "corrects"
	RelationRecoversFrom RelationType = "recovers_from"
	RelationFollows      RelationType = "follows"
	RelationRelatedTo    RelationType = "related_to"
	RelationSupersedes   RelationType = "supersedes"
)

func (value RelationType) Valid() bool {
	switch value {
	case RelationDependsOn,
		RelationConstrains,
		RelationDerivedFrom,
		RelationAppliesTo,
		RelationChallenges,
		RelationCorrects,
		RelationRecoversFrom,
		RelationFollows,
		RelationRelatedTo,
		RelationSupersedes:
		return true
	default:
		return false
	}
}

// Scope locates one atomic knowledge record without changing its L1/L2/L3 depth.
type Scope struct {
	Project           string   `json:"project"`
	Domains           []string `json:"domains"`
	ArchitectureUnits []string `json:"architecture_units"`
	Features          []string `json:"features"`
}

// L1 is the shared discovery projection for every knowledge type.
type L1 struct {
	Title    string   `json:"title"`
	Summary  string   `json:"summary"`
	Triggers []string `json:"triggers"`
	Tags     []string `json:"tags"`
}

// L2 is the shared planning projection header plus a strictly typed factory payload.
type L2 struct {
	CoreConclusion    string          `json:"core_conclusion"`
	ApplicableWhen    []string        `json:"applicable_when"`
	NotApplicableWhen []string        `json:"not_applicable_when"`
	Impact            []string        `json:"impact"`
	EvidenceSummary   []string        `json:"evidence_summary"`
	UpgradeWhen       []string        `json:"upgrade_when"`
	Payload           json.RawMessage `json:"payload"`
}

// SourceRef binds a root-relative source path to the exact bytes used by a revision.
type SourceRef struct {
	Path   string `json:"path"`
	Digest string `json:"digest"`
}

// Relation binds a source revision to another stable record identity.
type Relation struct {
	Type                 RelationType `json:"type"`
	TargetRecordID       string       `json:"target_record_id"`
	TargetRecordRevision string       `json:"target_record_revision,omitempty"`
	CrossZone            bool         `json:"cross_zone,omitempty"`
}

// CandidateRevision is one immutable candidate state.
type CandidateRevision struct {
	Schema                  string          `json:"schema"`
	CandidateID             string          `json:"candidate_id"`
	Revision                string          `json:"candidate_revision"`
	Status                  CandidateStatus `json:"status"`
	Zone                    Zone            `json:"zone"`
	Scope                   Scope           `json:"scope"`
	ProposedType            KnowledgeType   `json:"proposed_type"`
	ClassificationRationale string          `json:"classification_rationale"`
	KnowledgeType           KnowledgeType   `json:"knowledge_type,omitempty"`
	Sources                 []SourceRef     `json:"sources"`
	Relations               []Relation      `json:"relations"`
	L1                      L1              `json:"l1"`
	L2                      L2              `json:"l2"`
	L1Digest                string          `json:"l1_digest"`
	L2Digest                string          `json:"l2_digest"`
	L3Digest                string          `json:"l3_digest"`
	ProposedBy              string          `json:"proposed_by"`
	RevisedBy               string          `json:"revised_by,omitempty"`
	CreatedAt               string          `json:"created_at"`
	PublishedRecordID       string          `json:"published_record_id,omitempty"`
	ContentMarkdown         []byte          `json:"-"`
}

// RecordRevision is one immutable formal knowledge state.
type RecordRevision struct {
	Schema              string        `json:"schema"`
	RecordID            string        `json:"record_id"`
	Revision            string        `json:"record_revision"`
	KnowledgeType       KnowledgeType `json:"knowledge_type"`
	Zone                Zone          `json:"zone"`
	Status              RecordStatus  `json:"status"`
	Scope               Scope         `json:"scope"`
	Sources             []SourceRef   `json:"sources"`
	Relations           []Relation    `json:"relations"`
	L1                  L1            `json:"l1"`
	L2                  L2            `json:"l2"`
	L1Digest            string        `json:"l1_digest"`
	L2Digest            string        `json:"l2_digest"`
	L3Digest            string        `json:"l3_digest"`
	AuthorizationDigest string        `json:"authorization_digest"`
	Reason              string        `json:"reason,omitempty"`
	CreatedAt           string        `json:"created_at"`
	Generation          uint64        `json:"generation"`
	ContentMarkdown     []byte        `json:"-"`
}

// Projection binds L1 and L2 to the same formal record revision and L3 digest.
type Projection struct {
	Schema        string        `json:"schema"`
	RecordID      string        `json:"record_id"`
	Revision      string        `json:"record_revision"`
	KnowledgeType KnowledgeType `json:"knowledge_type"`
	Zone          Zone          `json:"zone"`
	Status        RecordStatus  `json:"status"`
	Scope         Scope         `json:"scope"`
	L1            L1            `json:"l1"`
	L2            L2            `json:"l2"`
	L1Digest      string        `json:"l1_digest"`
	L2Digest      string        `json:"l2_digest"`
	L3Digest      string        `json:"l3_digest"`
}

// CandidatePointer is the manifest's current candidate revision binding.
type CandidatePointer struct {
	CandidateID string          `json:"candidate_id"`
	Revision    string          `json:"candidate_revision"`
	Status      CandidateStatus `json:"status"`
	RecordID    string          `json:"record_id,omitempty"`
}

// RecordPointer is the manifest's current formal record revision binding.
type RecordPointer struct {
	RecordID string       `json:"record_id"`
	Revision string       `json:"record_revision"`
	Status   RecordStatus `json:"status"`
}

// ProjectionRef binds immutable projection bytes to one record revision.
type ProjectionRef struct {
	RecordID string `json:"record_id"`
	Revision string `json:"record_revision"`
	L1Digest string `json:"l1_digest"`
	L2Digest string `json:"l2_digest"`
	L3Digest string `json:"l3_digest"`
}

// Manifest is one generation's complete current-state pointer set.
type Manifest struct {
	Schema               string             `json:"schema"`
	Generation           uint64             `json:"generation"`
	ParentGeneration     *uint64            `json:"parent_generation,omitempty"`
	ParentManifestDigest string             `json:"parent_manifest_digest,omitempty"`
	CurrentCandidates    []CandidatePointer `json:"current_candidates"`
	CurrentRecords       []RecordPointer    `json:"current_records"`
	Projections          []ProjectionRef    `json:"projections"`
	ViewsDigest          string             `json:"views_digest"`
	Digest               string             `json:"digest"`
}

// DesignDecisionL2 is the type-specific L2 payload for design decisions.
type DesignDecisionL2 struct {
	AffectedUnits  []string `json:"affected_units"`
	Constraints    []string `json:"constraints"`
	Alternatives   []string `json:"alternatives"`
	Consequences   []string `json:"consequences"`
	ReevaluateWhen []string `json:"reevaluate_when"`
}

// DevelopmentStandardL2 is the type-specific L2 payload for development standards.
type DevelopmentStandardL2 struct {
	LifecycleStages   []string `json:"lifecycle_stages"`
	Trigger           []string `json:"trigger"`
	RequiredActions   []string `json:"required_actions"`
	ProhibitedActions []string `json:"prohibited_actions"`
	Verification      []string `json:"verification"`
	ExceptionPolicy   []string `json:"exception_policy"`
}

// DevelopmentExperienceL2 is the type-specific L2 payload for development experience.
type DevelopmentExperienceL2 struct {
	Symptoms          []string `json:"symptoms"`
	Preconditions     []string `json:"preconditions"`
	ObservedFacts     []string `json:"observed_facts"`
	RecommendedAction []string `json:"recommended_action"`
	EvidenceStrength  string   `json:"evidence_strength"`
	Risks             []string `json:"risks"`
	StopConditions    []string `json:"stop_conditions"`
}

// NormalizeStrings returns a sorted, duplicate-free copy for set-semantic strings.
func NormalizeStrings(values []string) []string {
	if values == nil {
		return nil
	}
	normalized := append([]string(nil), values...)
	slices.Sort(normalized)
	return slices.Compact(normalized)
}

func NormalizeScope(value Scope) Scope {
	value.Domains = NormalizeStrings(value.Domains)
	value.ArchitectureUnits = NormalizeStrings(value.ArchitectureUnits)
	value.Features = NormalizeStrings(value.Features)
	return value
}

func NormalizeL1(value L1) L1 {
	value.Triggers = NormalizeStrings(value.Triggers)
	value.Tags = NormalizeStrings(value.Tags)
	return value
}

func NormalizeL2(value L2) L2 {
	value.ApplicableWhen = NormalizeStrings(value.ApplicableWhen)
	value.NotApplicableWhen = NormalizeStrings(value.NotApplicableWhen)
	value.Impact = NormalizeStrings(value.Impact)
	value.EvidenceSummary = NormalizeStrings(value.EvidenceSummary)
	value.UpgradeWhen = NormalizeStrings(value.UpgradeWhen)
	value.Payload = append(json.RawMessage(nil), value.Payload...)
	return value
}

func NormalizeSources(values []SourceRef) []SourceRef {
	if values == nil {
		return nil
	}
	normalized := append([]SourceRef(nil), values...)
	slices.SortFunc(normalized, func(left, right SourceRef) int {
		if left.Path != right.Path {
			return compare(left.Path, right.Path)
		}
		return compare(left.Digest, right.Digest)
	})
	return slices.Compact(normalized)
}

func NormalizeRelations(values []Relation) []Relation {
	if values == nil {
		return nil
	}
	normalized := append([]Relation(nil), values...)
	slices.SortFunc(normalized, func(left, right Relation) int {
		if left.Type != right.Type {
			return compare(left.Type, right.Type)
		}
		if left.TargetRecordID != right.TargetRecordID {
			return compare(left.TargetRecordID, right.TargetRecordID)
		}
		if left.TargetRecordRevision != right.TargetRecordRevision {
			return compare(left.TargetRecordRevision, right.TargetRecordRevision)
		}
		return compareBool(left.CrossZone, right.CrossZone)
	})
	return slices.Compact(normalized)
}

func NormalizeCandidateRevision(value CandidateRevision) CandidateRevision {
	value.Scope = NormalizeScope(value.Scope)
	value.Sources = NormalizeSources(value.Sources)
	value.Relations = NormalizeRelations(value.Relations)
	value.L1 = NormalizeL1(value.L1)
	value.L2 = NormalizeL2(value.L2)
	value.ContentMarkdown = append([]byte(nil), value.ContentMarkdown...)
	return value
}

func NormalizeRecordRevision(value RecordRevision) RecordRevision {
	value.Scope = NormalizeScope(value.Scope)
	value.Sources = NormalizeSources(value.Sources)
	value.Relations = NormalizeRelations(value.Relations)
	value.L1 = NormalizeL1(value.L1)
	value.L2 = NormalizeL2(value.L2)
	value.ContentMarkdown = append([]byte(nil), value.ContentMarkdown...)
	return value
}

func NormalizeProjection(value Projection) Projection {
	value.Scope = NormalizeScope(value.Scope)
	value.L1 = NormalizeL1(value.L1)
	value.L2 = NormalizeL2(value.L2)
	return value
}

func NormalizeManifest(value Manifest) Manifest {
	value.CurrentCandidates = normalizeCandidatePointers(value.CurrentCandidates)
	value.CurrentRecords = normalizeRecordPointers(value.CurrentRecords)
	value.Projections = normalizeProjectionRefs(value.Projections)
	return value
}

func normalizeCandidatePointers(values []CandidatePointer) []CandidatePointer {
	if values == nil {
		return nil
	}
	normalized := append([]CandidatePointer(nil), values...)
	slices.SortFunc(normalized, func(left, right CandidatePointer) int {
		if left.CandidateID != right.CandidateID {
			return compare(left.CandidateID, right.CandidateID)
		}
		if left.Revision != right.Revision {
			return compare(left.Revision, right.Revision)
		}
		if left.Status != right.Status {
			return compare(left.Status, right.Status)
		}
		return compare(left.RecordID, right.RecordID)
	})
	return slices.Compact(normalized)
}

func normalizeRecordPointers(values []RecordPointer) []RecordPointer {
	if values == nil {
		return nil
	}
	normalized := append([]RecordPointer(nil), values...)
	slices.SortFunc(normalized, func(left, right RecordPointer) int {
		if left.RecordID != right.RecordID {
			return compare(left.RecordID, right.RecordID)
		}
		if left.Revision != right.Revision {
			return compare(left.Revision, right.Revision)
		}
		return compare(left.Status, right.Status)
	})
	return slices.Compact(normalized)
}

func normalizeProjectionRefs(values []ProjectionRef) []ProjectionRef {
	if values == nil {
		return nil
	}
	normalized := append([]ProjectionRef(nil), values...)
	slices.SortFunc(normalized, func(left, right ProjectionRef) int {
		if left.RecordID != right.RecordID {
			return compare(left.RecordID, right.RecordID)
		}
		if left.Revision != right.Revision {
			return compare(left.Revision, right.Revision)
		}
		if left.L1Digest != right.L1Digest {
			return compare(left.L1Digest, right.L1Digest)
		}
		if left.L2Digest != right.L2Digest {
			return compare(left.L2Digest, right.L2Digest)
		}
		return compare(left.L3Digest, right.L3Digest)
	})
	return slices.Compact(normalized)
}

type orderedString interface {
	~string
}

func compare[T orderedString](left, right T) int {
	switch {
	case left < right:
		return -1
	case left > right:
		return 1
	default:
		return 0
	}
}

func compareBool(left, right bool) int {
	switch {
	case left == right:
		return 0
	case !left:
		return -1
	default:
		return 1
	}
}
