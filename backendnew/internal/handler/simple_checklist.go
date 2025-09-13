package handler

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/model"
	"assetscanner/internal/service"
	"net/http"

	"github.com/labstack/echo/v4"
)

// SimpleChecklistHandler handles checklist-related HTTP requests with a simpler approach
type SimpleChecklistHandler struct {
	checklistService *service.SimpleChecklistService
}

// NewSimpleChecklistHandler creates a new simple checklist handler
func NewSimpleChecklistHandler(checklistService *service.SimpleChecklistService) *SimpleChecklistHandler {
	return &SimpleChecklistHandler{
		checklistService: checklistService,
	}
}

// GetGlobalChecklist returns global checklist items
// @Summary Get global checklist items
// @Description Retrieve all global checklist items with their current status
// @Tags checklist
// @Accept json
// @Produce json
// @Success 200 {array} model.DerivedChecklistItem
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/global [get]
func (h *SimpleChecklistHandler) GetGlobalChecklist(c echo.Context) error {
	items, err := h.checklistService.GetGlobalChecklist(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to get global checklist",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, items)
}

// GetAssetChecklist returns asset checklist items
// @Summary Get asset-specific checklist items
// @Description Retrieve all checklist items applicable to a specific asset with their current status
// @Tags checklist
// @Accept json
// @Produce json
// @Param id path string true "Asset ID"
// @Success 200 {array} model.DerivedChecklistItem
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/asset/{id} [get]
func (h *SimpleChecklistHandler) GetAssetChecklist(c echo.Context) error {
	assetID := c.Param("id")
	if assetID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error: "Asset ID is required",
			Code:  http.StatusBadRequest,
		})
	}

	items, err := h.checklistService.GetAssetChecklist(c.Request().Context(), assetID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to get asset checklist",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, items)
}

// SetStatusRequest represents the simple request to set status
type SetStatusRequest struct {
	ItemID  string `json:"item_id" example:"security-policy-001"`                    // Checklist item template ID
	AssetID string `json:"asset_id,omitempty" example:"asset-123"`                   // Asset ID (empty for global items)
	Status  string `json:"status" example:"yes" enums:"yes,no,na"`                   // Status: yes, no, or na
	Notes   string `json:"notes,omitempty" example:"Verified during security audit"` // Optional notes
}

// SetStatus sets the status of a checklist item
// @Summary Set checklist item status
// @Description Set the status (yes/no/na) of a checklist item, either global or asset-specific
// @Tags checklist
// @Accept json
// @Produce json
// @Param request body SetStatusRequest true "Status update request"
// @Success 200 {object} map[string]string
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/status [post]
func (h *SimpleChecklistHandler) SetStatus(c echo.Context) error {
	var req SetStatusRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	if err := h.checklistService.SetStatus(c.Request().Context(), req.ItemID, req.AssetID, req.Status, req.Notes); err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to set status",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "Status updated successfully"})
}

// ListTemplates returns all templates
// @Summary List all checklist templates
// @Description Retrieve all available checklist item templates
// @Tags checklist
// @Accept json
// @Produce json
// @Success 200 {array} model.ChecklistItemTemplate
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/templates [get]
func (h *SimpleChecklistHandler) ListTemplates(c echo.Context) error {
	templates, err := h.checklistService.ListTemplates(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to get templates",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, templates)
}

// UploadTemplatesRequest represents the request to upload templates
type UploadTemplatesRequest struct {
	Templates []*model.ChecklistItemTemplate `json:"templates"` // Array of checklist templates to upload
}

// UploadTemplates uploads and overwrites all checklist templates
// @Summary Upload checklist templates from JSON
// @Description Upload a JSON file containing checklist templates that will overwrite all existing templates
// @Tags checklist
// @Accept json
// @Produce json
// @Param request body UploadTemplatesRequest true "Templates upload request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/templates/upload [post]
func (h *SimpleChecklistHandler) UploadTemplates(c echo.Context) error {
	var req UploadTemplatesRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	if len(req.Templates) == 0 {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error: "No templates provided",
			Code:  http.StatusBadRequest,
		})
	}

	// Call service to upload templates (this will overwrite existing ones)
	count, err := h.checklistService.UploadTemplates(c.Request().Context(), req.Templates)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to upload templates",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"message": "Templates uploaded successfully",
		"count":   count,
	})
}

// GetComplianceCoverageSummary returns a summary of compliance coverage across all assets
// @Summary Get compliance coverage summary
// @Description Get a summary of compliance coverage showing which assets are covered by compliance checks
// @Tags checklist
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/coverage/summary [get]
func (h *SimpleChecklistHandler) GetComplianceCoverageSummary(c echo.Context) error {
	summary, err := h.checklistService.GetComplianceCoverageSummary(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to get compliance coverage summary",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, summary)
}
