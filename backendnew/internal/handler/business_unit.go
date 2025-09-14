package handler

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/model"
	"assetscanner/internal/service"
	"net/http"

	"github.com/labstack/echo/v4"
)

// BusinessUnitHandler handles business unit-related endpoints
type BusinessUnitHandler struct {
	businessUnitService *service.BusinessUnitService
}

// NewBusinessUnitHandler creates a new business unit handler
func NewBusinessUnitHandler(businessUnitService *service.BusinessUnitService) *BusinessUnitHandler {
	return &BusinessUnitHandler{
		businessUnitService: businessUnitService,
	}
}

// CreateBusinessUnit creates a new business unit
// @Summary Create business unit
// @Description Create a new business unit with the specified name
// @Tags business-units
// @Accept json
// @Produce json
// @Param request body v1.CreateBusinessUnitRequest true "Business unit creation request"
// @Success 201 {object} v1.BusinessUnitResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 409 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /business-units [post]
func (h *BusinessUnitHandler) CreateBusinessUnit(c echo.Context) error {
	var req v1.CreateBusinessUnitRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	businessUnit, err := h.businessUnitService.CreateBusinessUnitWithDetails(c.Request().Context(), req.Name, req.LegalEntityName, req.RegistrationCode, req.InternalCode, req.Sector, req.Subsector, req.CompanySizeBand, req.HeadcountRange, req.Country, req.Address, req.Timezone, req.PrimaryDomain, req.OtherDomainsCount, req.FurnizorServicii, req.FurnizorDate)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "business unit name cannot be empty" {
			statusCode = http.StatusBadRequest
		} else if err.Error() != "" && err.Error()[len(err.Error())-15:] == "already exists" {
			statusCode = http.StatusConflict
		}

		return c.JSON(statusCode, v1.ErrorResponse{
			Error:   "Failed to create business unit",
			Code:    statusCode,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := h.convertToBusinessUnitResponse(businessUnit)
	return c.JSON(http.StatusCreated, response)
}

// GetBusinessUnit retrieves a business unit by ID
// @Summary Get business unit
// @Description Retrieve a business unit by its ID
// @Tags business-units
// @Accept json
// @Produce json
// @Param id path string true "Business unit ID"
// @Success 200 {object} v1.BusinessUnitResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /business-units/{id} [get]
func (h *BusinessUnitHandler) GetBusinessUnit(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Business unit ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "Missing ID parameter"},
		})
	}

	businessUnit, err := h.businessUnitService.GetBusinessUnit(c.Request().Context(), id)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "Business unit not found" {
			statusCode = http.StatusNotFound
		}

		return c.JSON(statusCode, v1.ErrorResponse{
			Error:   "Failed to get business unit",
			Code:    statusCode,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := h.convertToBusinessUnitResponse(businessUnit)
	return c.JSON(http.StatusOK, response)
}

// UpdateBusinessUnit updates a business unit
// @Summary Update business unit
// @Description Update a business unit's name
// @Tags business-units
// @Accept json
// @Produce json
// @Param id path string true "Business unit ID"
// @Param request body v1.UpdateBusinessUnitRequest true "Business unit update request"
// @Success 200 {object} v1.BusinessUnitResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 409 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /business-units/{id} [put]
func (h *BusinessUnitHandler) UpdateBusinessUnit(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Business unit ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "Missing ID parameter"},
		})
	}

	var req v1.UpdateBusinessUnitRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	businessUnit, err := h.businessUnitService.UpdateBusinessUnitWithDetails(c.Request().Context(), id, req.Name, req.LegalEntityName, req.RegistrationCode, req.InternalCode, req.Sector, req.Subsector, req.CompanySizeBand, req.HeadcountRange, req.Country, req.Address, req.Timezone, req.PrimaryDomain, req.OtherDomainsCount, req.FurnizorServicii, req.FurnizorDate)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "business unit name cannot be empty" {
			statusCode = http.StatusBadRequest
		} else if err.Error() == "Business unit not found" {
			statusCode = http.StatusNotFound
		} else if err.Error() != "" && err.Error()[len(err.Error())-15:] == "already exists" {
			statusCode = http.StatusConflict
		}

		return c.JSON(statusCode, v1.ErrorResponse{
			Error:   "Failed to update business unit",
			Code:    statusCode,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := h.convertToBusinessUnitResponse(businessUnit)
	return c.JSON(http.StatusOK, response)
}

// DeleteBusinessUnit deletes a business unit
// @Summary Delete business unit
// @Description Delete a business unit by its ID
// @Tags business-units
// @Accept json
// @Produce json
// @Param id path string true "Business unit ID"
// @Success 200 {object} v1.GenericStatusResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /business-units/{id} [delete]
func (h *BusinessUnitHandler) DeleteBusinessUnit(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Business unit ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "Missing ID parameter"},
		})
	}

	err := h.businessUnitService.DeleteBusinessUnit(c.Request().Context(), id)
	if err != nil {
		statusCode := http.StatusInternalServerError
		if err.Error() == "Business unit not found" {
			statusCode = http.StatusNotFound
		}

		return c.JSON(statusCode, v1.ErrorResponse{
			Error:   "Failed to delete business unit",
			Code:    statusCode,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, v1.GenericStatusResponse{
		Message: "Business unit deleted successfully",
	})
}

// ListBusinessUnits retrieves all business units
// @Summary List business units
// @Description Retrieve all business units
// @Tags business-units
// @Accept json
// @Produce json
// @Success 200 {object} v1.ListBusinessUnitsResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /business-units [get]
func (h *BusinessUnitHandler) ListBusinessUnits(c echo.Context) error {
	businessUnits, err := h.businessUnitService.ListBusinessUnits(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to list business units",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := v1.ListBusinessUnitsResponse{
		BusinessUnits: make([]v1.BusinessUnitResponse, len(businessUnits)),
		Total:         len(businessUnits),
	}

	for i, businessUnit := range businessUnits {
		response.BusinessUnits[i] = h.convertToBusinessUnitResponse(businessUnit)
	}

	return c.JSON(http.StatusOK, response)
}

// convertToBusinessUnitResponse converts a model.BusinessUnit to v1.BusinessUnitResponse
func (h *BusinessUnitHandler) convertToBusinessUnitResponse(businessUnit *model.BusinessUnit) v1.BusinessUnitResponse {
	return v1.BusinessUnitResponse{
		ID:        businessUnit.ID,
		Name:      businessUnit.Name,
		CreatedAt: businessUnit.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt: businessUnit.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		
		// Legal Entity Information
		LegalEntityName:     businessUnit.LegalEntityName,
		RegistrationCode:    businessUnit.RegistrationCode,
		InternalCode:        businessUnit.InternalCode,
		
		// Business Information
		Sector:              businessUnit.Sector,
		Subsector:           businessUnit.Subsector,
		CompanySizeBand:     businessUnit.CompanySizeBand,
		HeadcountRange:      businessUnit.HeadcountRange,
		
		// Location Information
		Country:             businessUnit.Country,
		Address:             businessUnit.Address,
		Timezone:            businessUnit.Timezone,
		
		// Domain Information
		PrimaryDomain:       businessUnit.PrimaryDomain,
		OtherDomainsCount:   businessUnit.OtherDomainsCount,
		
		// Legal Compliance
		FurnizorServicii:    businessUnit.FurnizorServicii,
		FurnizorDate:        businessUnit.FurnizorDate,
	}
}
