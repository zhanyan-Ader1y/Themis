package governance

import (
	"strings"
	"time"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
)

const approvalSchema = "themico/approval"

// checkApproval verifies the authorization artifact's structure and its exact
// binding. It never claims to have verified the human behind approved_by.
func checkApproval(approval model.Approval, prepare model.Prepare) error {
	if approval.Schema != approvalSchema {
		return validationError("approval schema is invalid", nil)
	}
	if approval.Operation != operationPublish || prepare.Operation != operationPublish {
		return preconditionError("approval operation does not match publish", nil)
	}
	if approval.PrepareID != prepare.PrepareID || approval.PrepareDigest != prepare.Digest {
		return preconditionError("approval is not bound to this prepare", nil)
	}
	if strings.TrimSpace(approval.ApprovedBy) == "" || strings.TrimSpace(approval.AuthorityRef) == "" {
		return preconditionError("approval identity and authority reference are required", nil)
	}
	if _, err := time.Parse(time.RFC3339, approval.ApprovedAt); err != nil {
		return validationError("approval time is invalid", err)
	}
	return nil
}
