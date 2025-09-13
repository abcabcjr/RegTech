package service

import (
	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"context"
	"fmt"
	"sort"
	"time"
)

// SimpleChecklistService handles checklist operations with a much simpler approach
type SimpleChecklistService struct {
	storage storage.Storage
}

// NewSimpleChecklistService creates a new simple checklist service
func NewSimpleChecklistService(storage storage.Storage) *SimpleChecklistService {
	return &SimpleChecklistService{
		storage: storage,
	}
}

// GetGlobalChecklist returns all global checklist items with their status
func (s *SimpleChecklistService) GetGlobalChecklist(ctx context.Context) ([]*model.DerivedChecklistItem, error) {
	// Get all templates with global scope
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	// Get all statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	var globalItems []*model.DerivedChecklistItem
	for _, template := range templates {
		if template.Scope == model.ChecklistScopeGlobal {
			derived := &model.DerivedChecklistItem{
				ChecklistItemTemplate: *template,
				Status:                model.ChecklistStatusNA,
				Source:                model.ChecklistSourceManual,
				Evidence:              make(map[string]interface{}),
			}

			// Check if there's a status for this item
			key := model.GlobalChecklistKey(template.ID)
			if status, exists := statuses[key]; exists {
				derived.Status = status.Status
				derived.Notes = status.Notes
				derived.UpdatedAt = &status.UpdatedAt
			}

			// If template has evidence rules or is script controlled, it's automated
			if len(template.EvidenceRules) > 0 || template.ScriptControlled {
				derived.Source = model.ChecklistSourceAuto

				// Check for script-controlled results
				if template.ScriptControlled {
					scriptStatus := s.getScriptControlledStatus(ctx, template.ID, "")
					if scriptStatus != nil {
						derived.Status = scriptStatus.Status
						if scriptStatus.Reason != "" {
							derived.Notes = scriptStatus.Reason
						}
						derived.UpdatedAt = &scriptStatus.UpdatedAt
					}
				}
				// TODO: Evaluate evidence rules if needed
			}

			globalItems = append(globalItems, derived)
		}
	}

	// Sort by ID for consistent ordering
	sort.Slice(globalItems, func(i, j int) bool {
		return globalItems[i].ID < globalItems[j].ID
	})

	return globalItems, nil
}

// GetAssetChecklist returns all asset-specific checklist items for a given asset
func (s *SimpleChecklistService) GetAssetChecklist(ctx context.Context, assetID string) ([]*model.DerivedChecklistItem, error) {
	// Get the asset to check its type
	asset, err := s.storage.GetAsset(ctx, assetID)
	if err != nil {
		return nil, fmt.Errorf("failed to get asset: %w", err)
	}

	// Get all templates with asset scope
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	// Get all statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	var assetItems []*model.DerivedChecklistItem
	for _, template := range templates {
		if template.Scope == model.ChecklistScopeAsset {
			// Check if this template applies to this asset type
			if s.templateAppliesToAsset(template, asset.Type) {
				derived := &model.DerivedChecklistItem{
					ChecklistItemTemplate: *template,
					Status:                model.ChecklistStatusNA,
					Source:                model.ChecklistSourceManual,
					Evidence:              make(map[string]interface{}),
				}

				// Check if there's a status for this item
				key := model.AssetChecklistKey(assetID, template.ID)
				if status, exists := statuses[key]; exists {
					derived.Status = status.Status
					derived.Notes = status.Notes
					derived.UpdatedAt = &status.UpdatedAt
				}

				// If template has evidence rules or is script controlled, it's automated
				if len(template.EvidenceRules) > 0 || template.ScriptControlled {
					derived.Source = model.ChecklistSourceAuto

					// Check for script-controlled results
					if template.ScriptControlled {
						scriptStatus := s.getScriptControlledStatus(ctx, template.ID, assetID)
						if scriptStatus != nil {
							derived.Status = scriptStatus.Status
							if scriptStatus.Reason != "" {
								derived.Notes = scriptStatus.Reason
							}
							derived.UpdatedAt = &scriptStatus.UpdatedAt
						}
					}
					// TODO: Evaluate evidence rules if needed
				}

				assetItems = append(assetItems, derived)
			}
		}
	}

	// Sort by ID for consistent ordering
	sort.Slice(assetItems, func(i, j int) bool {
		return assetItems[i].ID < assetItems[j].ID
	})

	return assetItems, nil
}

// SetStatus sets the status of a checklist item (much simpler!)
func (s *SimpleChecklistService) SetStatus(ctx context.Context, itemID, assetID, status, notes string) error {
	var key string
	if assetID == "" {
		key = model.GlobalChecklistKey(itemID)
	} else {
		key = model.AssetChecklistKey(assetID, itemID)
	}

	statusObj := &model.SimpleChecklistStatus{
		Key:       key,
		Status:    status,
		Notes:     notes,
		UpdatedAt: time.Now(),
	}

	return s.storage.SetChecklistStatus(ctx, key, statusObj)
}

// ListTemplates returns all checklist templates
func (s *SimpleChecklistService) ListTemplates(ctx context.Context) ([]*model.ChecklistItemTemplate, error) {
	return s.storage.ListChecklistTemplates(ctx)
}

// CreateTemplate creates a new checklist template
func (s *SimpleChecklistService) CreateTemplate(ctx context.Context, template *model.ChecklistItemTemplate) error {
	return s.storage.CreateChecklistTemplate(ctx, template)
}

// UploadTemplates uploads and overwrites all checklist templates
func (s *SimpleChecklistService) UploadTemplates(ctx context.Context, templates []*model.ChecklistItemTemplate) (int, error) {
	// First, get all existing templates to delete them
	existingTemplates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to get existing templates: %w", err)
	}

	// Delete all existing templates
	for _, template := range existingTemplates {
		if err := s.storage.DeleteChecklistTemplate(ctx, template.ID); err != nil {
			return 0, fmt.Errorf("failed to delete existing template %s: %w", template.ID, err)
		}
	}

	// Create all new templates
	count := 0
	for _, template := range templates {
		if err := s.storage.CreateChecklistTemplate(ctx, template); err != nil {
			return count, fmt.Errorf("failed to create template %s: %w", template.ID, err)
		}
		count++
	}

	return count, nil
}

// templateAppliesToAsset checks if a template applies to a given asset type
func (s *SimpleChecklistService) templateAppliesToAsset(template *model.ChecklistItemTemplate, assetType string) bool {
	if len(template.AssetTypes) == 0 {
		// If no asset types specified, applies to all
		return true
	}

	for _, t := range template.AssetTypes {
		if t == assetType {
			return true
		}
	}
	return false
}

// ScriptControlledResult represents a checklist result from Lua scripts
type ScriptControlledResult struct {
	Status    string
	Reason    string
	UpdatedAt time.Time
}

// getScriptControlledStatus gets the latest script-controlled status for a checklist item
func (s *SimpleChecklistService) getScriptControlledStatus(ctx context.Context, checklistID, assetID string) *ScriptControlledResult {
	var targetAssetID string
	if assetID != "" {
		targetAssetID = assetID
	}

	// Get the asset to check its scan results
	if targetAssetID != "" {
		asset, err := s.storage.GetAsset(ctx, targetAssetID)
		if err != nil {
			return nil
		}

		// Look through scan results for checklist results
		var latestResult *ScriptControlledResult
		var latestTime time.Time

		for _, scanResult := range asset.ScanResults {
			if scanResult.Metadata != nil {
				if checklistResults, ok := scanResult.Metadata["checklist_results"].(map[string]interface{}); ok {
					if result, exists := checklistResults[checklistID]; exists {
						if resultMap, ok := result.(map[string]interface{}); ok {
							status, hasStatus := resultMap["status"].(string)
							reason, _ := resultMap["reason"].(string)

							if hasStatus && scanResult.ExecutedAt.After(latestTime) {
								latestResult = &ScriptControlledResult{
									Status:    status,
									Reason:    reason,
									UpdatedAt: scanResult.ExecutedAt,
								}
								latestTime = scanResult.ExecutedAt
							}
						}
					}
				}
			}
		}

		return latestResult
	}

	// For global checklist items, we need to check all assets
	// This is more complex - for now, return nil for global items controlled by scripts
	// TODO: Implement global script-controlled checklist logic if needed
	return nil
}
