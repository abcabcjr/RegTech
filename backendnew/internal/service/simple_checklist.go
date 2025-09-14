package service

import (
	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"context"
	"fmt"
	"sort"
	"strings"
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
				derived.Attachments = status.Attachments
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

	// Global-scoped items don't need covered assets - they apply organization-wide
	for _, item := range globalItems {
		item.CoveredAssets = []model.AssetCoverage{}
	}

	return globalItems, nil
}

// GetBusinessUnitChecklist returns all global checklist items with their status for a specific business unit
func (s *SimpleChecklistService) GetBusinessUnitChecklist(ctx context.Context, businessUnitID string) ([]*model.DerivedChecklistItem, error) {
	// Verify business unit exists
	_, err := s.storage.GetBusinessUnit(ctx, businessUnitID)
	if err != nil {
		return nil, fmt.Errorf("business unit not found: %w", err)
	}

	// Get all templates with global scope (these will be duplicated per business unit)
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	// Get all statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	var businessUnitItems []*model.DerivedChecklistItem
	for _, template := range templates {
		if template.Scope == model.ChecklistScopeGlobal {
			derived := &model.DerivedChecklistItem{
				ChecklistItemTemplate: *template,
				Status:                model.ChecklistStatusNA,
				Source:                model.ChecklistSourceManual,
				Evidence:              make(map[string]interface{}),
			}

			// Check if there's a status for this item in this business unit
			key := model.BusinessUnitChecklistKey(businessUnitID, template.ID)
			if status, exists := statuses[key]; exists {
				derived.Status = status.Status
				derived.Notes = status.Notes
				derived.UpdatedAt = &status.UpdatedAt
				derived.Attachments = status.Attachments
			}

			// If template has evidence rules or is script controlled, it's automated
			if len(template.EvidenceRules) > 0 || template.ScriptControlled {
				derived.Source = model.ChecklistSourceAuto

				// Check for script-controlled results
				if template.ScriptControlled {
					scriptStatus := s.getScriptControlledStatus(ctx, template.ID, businessUnitID)
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

			businessUnitItems = append(businessUnitItems, derived)
		}
	}

	// Sort by ID for consistent ordering
	sort.Slice(businessUnitItems, func(i, j int) bool {
		return businessUnitItems[i].ID < businessUnitItems[j].ID
	})

	// Business unit scoped items don't need covered assets - they apply to the business unit
	for _, item := range businessUnitItems {
		item.CoveredAssets = []model.AssetCoverage{}
	}

	return businessUnitItems, nil
}

// GetAllAssetTemplates returns all asset-scoped templates with coverage across all assets
func (s *SimpleChecklistService) GetAllAssetTemplates(ctx context.Context) ([]*model.DerivedChecklistItem, error) {
	// Get all templates
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	var assetTemplates []*model.DerivedChecklistItem
	for _, template := range templates {
		if template.Scope == model.ChecklistScopeAsset {
			derived := &model.DerivedChecklistItem{
				ChecklistItemTemplate: *template,
				Status:                model.ChecklistStatusNA,
				Source:                model.ChecklistSourceManual,
				Evidence:              make(map[string]interface{}),
			}

			// If template has evidence rules or is script controlled, it's automated
			if len(template.EvidenceRules) > 0 || template.ScriptControlled {
				derived.Source = model.ChecklistSourceAuto
			}

			// Get covered assets for this template
			coveredAssets, err := s.getCoveredAssets(ctx, template.ID, template.Scope)
			if err != nil {
				// Log error but don't fail the entire request
				fmt.Printf("Warning: Failed to get covered assets for %s: %v\n", template.ID, err)
				derived.CoveredAssets = []model.AssetCoverage{} // Empty on error
			} else {
				derived.CoveredAssets = coveredAssets
			}

			assetTemplates = append(assetTemplates, derived)
		}
	}

	// Sort by ID for consistent ordering
	sort.Slice(assetTemplates, func(i, j int) bool {
		return assetTemplates[i].ID < assetTemplates[j].ID
	})

	return assetTemplates, nil
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
					derived.Attachments = status.Attachments
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

	// Populate covered assets for each asset item
	for _, item := range assetItems {
		coveredAssets, err := s.getCoveredAssets(ctx, item.ID, item.Scope)
		if err != nil {
			// Log error but don't fail the entire request
			fmt.Printf("Warning: Failed to get covered assets for %s: %v\n", item.ID, err)
			item.CoveredAssets = []model.AssetCoverage{} // Empty on error
		} else {
			item.CoveredAssets = coveredAssets
		}
	}

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

// SetBusinessUnitStatus sets the status of a checklist item for a specific business unit
func (s *SimpleChecklistService) SetBusinessUnitStatus(ctx context.Context, itemID, businessUnitID, status, notes string) error {
	// Verify business unit exists
	_, err := s.storage.GetBusinessUnit(ctx, businessUnitID)
	if err != nil {
		return fmt.Errorf("business unit not found: %w", err)
	}

	key := model.BusinessUnitChecklistKey(businessUnitID, itemID)

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

// ListTemplatesWithCoverage returns all checklist templates with covered assets for non-compliant ones
func (s *SimpleChecklistService) ListTemplatesWithCoverage(ctx context.Context) ([]*model.DerivedChecklistItem, error) {
	// Get all templates
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	var derivedTemplates []*model.DerivedChecklistItem
	for _, template := range templates {
		derived := &model.DerivedChecklistItem{
			ChecklistItemTemplate: *template,
			Status:                model.ChecklistStatusNA,
			Source:                model.ChecklistSourceManual,
			Evidence:              make(map[string]interface{}),
		}

		// If template has evidence rules or is script controlled, it's automated
		if len(template.EvidenceRules) > 0 || template.ScriptControlled {
			derived.Source = model.ChecklistSourceAuto
		}

		// Get covered assets for this template (only non-compliant ones)
		coveredAssets, err := s.getNonCompliantCoveredAssets(ctx, template.ID, template.Scope)
		if err != nil {
			// Log error but don't fail the entire request
			fmt.Printf("Warning: Failed to get covered assets for %s: %v\n", template.ID, err)
			derived.CoveredAssets = []model.AssetCoverage{} // Empty on error
		} else {
			derived.CoveredAssets = coveredAssets
		}

		derivedTemplates = append(derivedTemplates, derived)
	}

	// Sort by ID for consistent ordering
	sort.Slice(derivedTemplates, func(i, j int) bool {
		return derivedTemplates[i].ID < derivedTemplates[j].ID
	})

	return derivedTemplates, nil
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

// ProcessScanResultsForChecklists processes scan results and updates checklist statuses
// This should be called after a scan completes to update checklist items based on script results
func (s *SimpleChecklistService) ProcessScanResultsForChecklists(ctx context.Context, assetID string, scanResults []*model.ScanResult) error {
	// Get all templates to know which ones are script-controlled
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return fmt.Errorf("failed to get checklist templates: %w", err)
	}

	// Process each scan result for checklist updates
	for _, scanResult := range scanResults {
		if scanResult.Metadata != nil {
			if checklistResults, ok := scanResult.Metadata["checklist_results"].(map[string]interface{}); ok {
				// Process each checklist result in this scan
				for checklistID, result := range checklistResults {
					if resultMap, ok := result.(map[string]interface{}); ok {
						status, hasStatus := resultMap["status"].(string)
						reason, _ := resultMap["reason"].(string)

						if hasStatus {
							// Find the template to make sure it's script-controlled
							var isScriptControlled bool
							for _, template := range templates {
								if template.ID == checklistID && template.ScriptControlled {
									isScriptControlled = true
									break
								}
							}

							if isScriptControlled {
								// Update the checklist status
								err := s.SetStatus(ctx, checklistID, assetID, status, reason)
								if err != nil {
									fmt.Printf("Warning: Failed to update checklist status for %s: %v\n", checklistID, err)
								} else {
									fmt.Printf("Updated checklist %s for asset %s: %s (%s)\n", checklistID, assetID, status, reason)
								}
							}
						}
					}
				}
			}
		}
	}

	return nil
}

// getCoveredAssets returns assets that have compliance status (YES/NO) for a specific checklist item
func (s *SimpleChecklistService) getCoveredAssets(ctx context.Context, itemID string, scope string) ([]model.AssetCoverage, error) {
	// Get all assets
	assets, err := s.storage.ListAssets(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get assets: %w", err)
	}

	// Get all checklist statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	// Get the template to check asset type compatibility
	template, err := s.storage.GetChecklistTemplate(ctx, itemID)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist template: %w", err)
	}

	var coveredAssets []model.AssetCoverage

	// For global items, we don't check individual assets, but we can show
	// if there are any asset-specific overrides
	if scope == model.ChecklistScopeGlobal {
		// Check if any assets have specific status overrides for this global item
		for _, asset := range assets {
			key := model.AssetChecklistKey(asset.ID, itemID)
			if status, exists := statuses[key]; exists {
				// Only include assets with YES/NO status (not N/A)
				if status.Status == model.ChecklistStatusYes || status.Status == model.ChecklistStatusNo {
					coveredAssets = append(coveredAssets, model.AssetCoverage{
						AssetID:    asset.ID,
						AssetType:  asset.Type,
						AssetValue: asset.Value,
						Status:     status.Status,
						Notes:      status.Notes,
						UpdatedAt:  &status.UpdatedAt,
					})
				}
			}
		}
	} else {
		// For asset-scoped items, check all compatible assets
		for _, asset := range assets {
			// Check if this template applies to this asset type
			if s.templateAppliesToAsset(template, asset.Type) {
				key := model.AssetChecklistKey(asset.ID, itemID)
				if status, exists := statuses[key]; exists {
					// Only include assets with YES/NO status (not N/A)
					if status.Status == model.ChecklistStatusYes || status.Status == model.ChecklistStatusNo {
						coveredAssets = append(coveredAssets, model.AssetCoverage{
							AssetID:    asset.ID,
							AssetType:  asset.Type,
							AssetValue: asset.Value,
							Status:     status.Status,
							Notes:      status.Notes,
							UpdatedAt:  &status.UpdatedAt,
						})
					}
				} else {
					// Check if there's script-controlled status
					scriptStatus := s.getScriptControlledStatus(ctx, itemID, asset.ID)
					if scriptStatus != nil && (scriptStatus.Status == model.ChecklistStatusYes || scriptStatus.Status == model.ChecklistStatusNo) {
						coveredAssets = append(coveredAssets, model.AssetCoverage{
							AssetID:    asset.ID,
							AssetType:  asset.Type,
							AssetValue: asset.Value,
							Status:     scriptStatus.Status,
							Notes:      scriptStatus.Reason,
							UpdatedAt:  &scriptStatus.UpdatedAt,
						})
					}
				}
			}
		}
	}

	// Sort by asset type then by asset value for consistent ordering
	sort.Slice(coveredAssets, func(i, j int) bool {
		if coveredAssets[i].AssetType != coveredAssets[j].AssetType {
			return coveredAssets[i].AssetType < coveredAssets[j].AssetType
		}
		return coveredAssets[i].AssetValue < coveredAssets[j].AssetValue
	})

	return coveredAssets, nil
}

// getNonCompliantCoveredAssets returns assets that have non-compliant status (NO) for a specific checklist item
func (s *SimpleChecklistService) getNonCompliantCoveredAssets(ctx context.Context, itemID string, scope string) ([]model.AssetCoverage, error) {
	// Get all assets
	assets, err := s.storage.ListAssets(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get assets: %w", err)
	}

	// Get all checklist statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	// Get the template to check asset type compatibility
	template, err := s.storage.GetChecklistTemplate(ctx, itemID)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist template: %w", err)
	}

	var nonCompliantAssets []model.AssetCoverage

	// For global items, check if any assets have specific non-compliant status overrides
	if scope == model.ChecklistScopeGlobal {
		// Check if any assets have specific status overrides for this global item
		for _, asset := range assets {
			key := model.AssetChecklistKey(asset.ID, itemID)
			if status, exists := statuses[key]; exists {
				// Only include assets with NO status (non-compliant)
				if status.Status == model.ChecklistStatusNo {
					nonCompliantAssets = append(nonCompliantAssets, model.AssetCoverage{
						AssetID:    asset.ID,
						AssetType:  asset.Type,
						AssetValue: asset.Value,
						Status:     status.Status,
						Notes:      status.Notes,
						UpdatedAt:  &status.UpdatedAt,
					})
				}
			}
		}
	} else {
		// For asset-scoped items, check all compatible assets
		for _, asset := range assets {
			// Check if this template applies to this asset type
			if s.templateAppliesToAsset(template, asset.Type) {
				key := model.AssetChecklistKey(asset.ID, itemID)
				if status, exists := statuses[key]; exists {
					// Only include assets with NO status (non-compliant)
					if status.Status == model.ChecklistStatusNo {
						nonCompliantAssets = append(nonCompliantAssets, model.AssetCoverage{
							AssetID:    asset.ID,
							AssetType:  asset.Type,
							AssetValue: asset.Value,
							Status:     status.Status,
							Notes:      status.Notes,
							UpdatedAt:  &status.UpdatedAt,
						})
					}
				} else {
					// Check if there's script-controlled non-compliant status
					scriptStatus := s.getScriptControlledStatus(ctx, itemID, asset.ID)
					if scriptStatus != nil && scriptStatus.Status == model.ChecklistStatusNo {
						nonCompliantAssets = append(nonCompliantAssets, model.AssetCoverage{
							AssetID:    asset.ID,
							AssetType:  asset.Type,
							AssetValue: asset.Value,
							Status:     scriptStatus.Status,
							Notes:      scriptStatus.Reason,
							UpdatedAt:  &scriptStatus.UpdatedAt,
						})
					}
				}
			}
		}
	}

	// Sort by asset type then by asset value for consistent ordering
	sort.Slice(nonCompliantAssets, func(i, j int) bool {
		if nonCompliantAssets[i].AssetType != nonCompliantAssets[j].AssetType {
			return nonCompliantAssets[i].AssetType < nonCompliantAssets[j].AssetType
		}
		return nonCompliantAssets[i].AssetValue < nonCompliantAssets[j].AssetValue
	})

	return nonCompliantAssets, nil
}

// GetComplianceCoverageSummary returns a summary of compliance coverage across all assets
func (s *SimpleChecklistService) GetComplianceCoverageSummary(ctx context.Context) (map[string]interface{}, error) {
	// Get all assets
	assets, err := s.storage.ListAssets(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get assets: %w", err)
	}

	// Get all templates
	templates, err := s.storage.ListChecklistTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist templates: %w", err)
	}

	// Get all statuses
	statuses, err := s.storage.ListChecklistStatuses(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
	}

	summary := map[string]interface{}{
		"total_assets":                len(assets),
		"total_compliance_checks":     len(templates),
		"assets_with_compliance_data": 0,
		"coverage_by_asset_type":      make(map[string]interface{}),
		"coverage_by_check":           make(map[string]interface{}),
	}

	// Track assets with compliance data
	assetsWithData := make(map[string]bool)

	// Coverage by asset type
	assetTypeCoverage := make(map[string]map[string]int)

	// Coverage by check
	checkCoverage := make(map[string]map[string]int)

	// Initialize coverage maps
	for _, template := range templates {
		checkCoverage[template.ID] = map[string]int{
			"yes_count":        0,
			"no_count":         0,
			"total_applicable": 0,
		}
	}

	// Count compliance statuses
	for key, status := range statuses {
		if status.Status == model.ChecklistStatusYes || status.Status == model.ChecklistStatusNo {
			// Extract asset ID and check ID from key
			if strings.HasPrefix(key, "asset:") {
				parts := strings.Split(key, ":")
				if len(parts) >= 3 {
					assetID := parts[1]
					checkID := parts[2]

					// Find the asset
					for _, asset := range assets {
						if asset.ID == assetID {
							assetsWithData[assetID] = true

							// Update asset type coverage
							if assetTypeCoverage[asset.Type] == nil {
								assetTypeCoverage[asset.Type] = map[string]int{
									"yes_count":    0,
									"no_count":     0,
									"total_checks": 0,
								}
							}

							assetTypeCoverage[asset.Type]["total_checks"]++
							if status.Status == model.ChecklistStatusYes {
								assetTypeCoverage[asset.Type]["yes_count"]++
							} else {
								assetTypeCoverage[asset.Type]["no_count"]++
							}

							// Update check coverage
							if checkCoverage[checkID] != nil {
								checkCoverage[checkID]["total_applicable"]++
								if status.Status == model.ChecklistStatusYes {
									checkCoverage[checkID]["yes_count"]++
								} else {
									checkCoverage[checkID]["no_count"]++
								}
							}
							break
						}
					}
				}
			}
		}
	}

	summary["assets_with_compliance_data"] = len(assetsWithData)
	summary["coverage_by_asset_type"] = assetTypeCoverage
	summary["coverage_by_check"] = checkCoverage

	return summary, nil
}
