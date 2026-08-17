package governance

import (
	"strings"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

const assessmentSchema = "themico/semantic-assessment"

// checkAssessment proves binding and structure only. Whether the notes are
// correct is a Human judgment the CLI never makes.
func checkAssessment(assessment model.SemanticAssessment, candidate model.CandidateRevision) error {
	if assessment.Schema != assessmentSchema {
		return validationError("assessment schema is invalid", nil)
	}
	if !assessment.Status.Valid() {
		return validationError("assessment status is invalid", nil)
	}
	if assessment.Status != model.AssessmentPass {
		return preconditionError("assessment did not pass", nil)
	}
	if assessment.CandidateID != candidate.CandidateID || assessment.CandidateRevision != candidate.Revision {
		return preconditionError("assessment is not bound to the candidate revision", nil)
	}
	if strings.TrimSpace(assessment.CheckerIdentity) == "" {
		return validationError("assessment checker identity is required", nil)
	}
	if assessment.CheckerIdentity == candidate.ProposedBy {
		return preconditionError("assessment checker must differ from the proposer", nil)
	}
	// candidate.RevisedBy names whoever produced the *current* revision —
	// either the last real content Revise, or (per candidate.Service.
	// ConfirmType, which this check does not and must not change) the
	// identity that confirmed the type, overwriting any earlier reviser. An
	// empty RevisedBy means the current revision is still exactly as the
	// proposer first wrote it, so there is no separate reviser identity to
	// exclude beyond the proposer check above.
	if candidate.RevisedBy != "" && assessment.CheckerIdentity == candidate.RevisedBy {
		return preconditionError("assessment checker must differ from the reviser", nil)
	}
	if _, err := time.Parse(time.RFC3339, assessment.CheckedAt); err != nil {
		return validationError("assessment time is invalid", err)
	}
	return nil
}
