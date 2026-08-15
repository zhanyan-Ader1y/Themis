package query

import (
	"context"
	"os"

	"github.com/zhanyan-Ader1y/Themis/internal/themico/canonical"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/model"
	"github.com/zhanyan-Ader1y/Themis/internal/themico/store"
)

// InspectRequest asks for a bounded-depth read of exact record IDs already
// discovered via Search. Depth must be 1 (L1 only), 2 (+L2), or 3 (+L3, the
// full Markdown record). There is no history, relation expansion, or
// cross-Zone lookup: every RecordID must name a record in the current
// manifest.
type InspectRequest struct {
	RecordIDs          []string `json:"record_ids"`
	Depth              int      `json:"depth"`
	ContentBudgetBytes int64    `json:"content_budget_bytes"`
}

// Item is one inspected record at the requested depth.
type Item struct {
	RecordID string              `json:"record_id"`
	Revision string              `json:"record_revision"`
	Zone     model.Zone          `json:"zone"`
	Type     model.KnowledgeType `json:"knowledge_type"`
	Status   model.RecordStatus  `json:"status"`
	Scope    model.Scope         `json:"scope"`
	L1       model.L1            `json:"l1"`
	L2       *model.L2           `json:"l2,omitempty"`
	L3       string              `json:"l3,omitempty"`
}

// InspectResult is Inspect's return value.
type InspectResult struct {
	Generation uint64 `json:"generation"`
	Items      []Item `json:"items"`
	Trace      Trace  `json:"trace"`
}

// Inspect upgrades exact record IDs already found by Search to depth 1
// (L1 only), 2 (+L2), or 3 (+L3). The byte budget is enforced on the exact
// bytes canonically encoded for every returned item: it never truncates,
// summarizes, or partially returns a request that would exceed the budget —
// the whole call fails closed with ErrBudgetExceeded and an empty Items
// slice instead. Every read independently re-verifies its projection/content
// binding against the manifest's frozen references; any binding failure
// fails the whole request closed with store.ErrValidation.
func Inspect(ctx context.Context, st *store.Store, request InspectRequest) (InspectResult, error) {
	if err := ctx.Err(); err != nil {
		return InspectResult{}, err
	}
	if st == nil {
		return InspectResult{}, validationError("query requires a store", nil)
	}
	if err := validateInspectRequest(request); err != nil {
		return InspectResult{}, err
	}

	manifest, err := st.Current()
	if err != nil {
		return InspectResult{}, err
	}
	root, err := os.OpenRoot(st.Root())
	if err != nil {
		return InspectResult{}, validationError("open store root", err)
	}
	defer root.Close()

	candidateIDs := append([]string{}, request.RecordIDs...)
	items := make([]Item, 0, len(request.RecordIDs))
	var totalBytes int64

	for _, recordID := range request.RecordIDs {
		if err := ctx.Err(); err != nil {
			return InspectResult{}, err
		}
		pointer, ok := findRecordPointer(manifest.CurrentRecords, recordID)
		if !ok {
			return InspectResult{}, notFoundError("record id is not in the current manifest")
		}
		ref, ok := findProjectionRef(manifest.Projections, pointer.RecordID, pointer.Revision)
		if !ok {
			return InspectResult{}, validationError("record pointer has no matching projection reference", nil)
		}
		projection, err := readProjectionL1(root, ref)
		if err != nil {
			return InspectResult{}, err
		}

		item := Item{
			RecordID: projection.RecordID,
			Revision: projection.Revision,
			Zone:     projection.Zone,
			Type:     projection.KnowledgeType,
			Status:   projection.Status,
			Scope:    projection.Scope,
			L1:       projection.L1,
		}

		if request.Depth >= 2 {
			l2, err := readProjectionL2(root, ref)
			if err != nil {
				return InspectResult{}, err
			}
			item.L2 = &l2
		}
		if request.Depth >= 3 {
			l3, err := readContentL3(root, pointer.RecordID, pointer.Revision, ref)
			if err != nil {
				return InspectResult{}, err
			}
			item.L3 = l3
		}

		encoded, err := canonical.Encode(item)
		if err != nil {
			return InspectResult{}, validationError("encode item", err)
		}
		totalBytes += int64(len(encoded))
		items = append(items, item)
	}

	trace := Trace{
		ObservedGeneration: manifest.Generation,
		SearchedZones:      []string{},
		CandidateIDs:       candidateIDs,
		SelectedIDs:        recordIDsOf(items),
		ExcludedIDs:        []string{},
		ContentBytes:       totalBytes,
		RemainingBytes:     request.ContentBudgetBytes - totalBytes,
	}

	if totalBytes > request.ContentBudgetBytes {
		trace.SelectedIDs = []string{}
		trace.ExcludedIDs = candidateIDs
		return InspectResult{Generation: manifest.Generation, Items: []Item{}, Trace: trace}, ErrBudgetExceeded
	}

	return InspectResult{Generation: manifest.Generation, Items: items, Trace: trace}, nil
}

func validateInspectRequest(request InspectRequest) error {
	if len(request.RecordIDs) == 0 {
		return validationError("record_ids is required", nil)
	}
	if request.Depth < 1 || request.Depth > 3 {
		return validationError("depth must be 1, 2, or 3", nil)
	}
	return validateBudget(request.ContentBudgetBytes)
}

func recordIDsOf(items []Item) []string {
	ids := make([]string, 0, len(items))
	for _, item := range items {
		ids = append(ids, item.RecordID)
	}
	return ids
}
