package handler

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/model"
	"assetscanner/internal/service"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
)

// IncidentHandler handles incident-related HTTP requests
type IncidentHandler struct {
	incidentService *service.IncidentService
}

// NewIncidentHandler creates a new incident handler
func NewIncidentHandler(incidentService *service.IncidentService) *IncidentHandler {
	return &IncidentHandler{
		incidentService: incidentService,
	}
}

// CreateIncident creates a new incident
// @Summary Create a new incident
// @Description Create a new incident record with initial details
// @Tags incidents
// @Accept json
// @Produce json
// @Param request body v1.CreateIncidentRequest true "Incident creation request"
// @Success 201 {object} v1.IncidentResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents [post]
func (h *IncidentHandler) CreateIncident(c echo.Context) error {
	var req v1.CreateIncidentRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Convert API request to service request
	serviceReq := &service.CreateIncidentRequest{
		InitialDetails: model.InitialDetails{
			Title:               req.InitialDetails.Title,
			Summary:             req.InitialDetails.Summary,
			DetectedAt:          req.InitialDetails.DetectedAt,
			SuspectedIllegal:    req.InitialDetails.SuspectedIllegal,
			PossibleCrossBorder: req.InitialDetails.PossibleCrossBorder,
		},
		Significant:        req.Significant,
		Recurring:          req.Recurring,
		CauseTag:           model.CauseTag(req.CauseTag),
		UsersAffected:      req.UsersAffected,
		DowntimeMinutes:    req.DowntimeMinutes,
		FinancialImpactPct: req.FinancialImpactPct,
		SectorPreset:       req.SectorPreset,
		Attachments:        convertAttachmentsFromAPI(req.Attachments),
	}

	incident, err := h.incidentService.CreateIncident(c.Request().Context(), serviceReq)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to create incident",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := convertIncidentToAPI(incident)
	return c.JSON(http.StatusCreated, response)
}

// GetIncident retrieves an incident by ID
// @Summary Get incident by ID
// @Description Retrieve a specific incident by its ID
// @Tags incidents
// @Accept json
// @Produce json
// @Param id path string true "Incident ID"
// @Success 200 {object} v1.IncidentResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents/{id} [get]
func (h *IncidentHandler) GetIncident(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Incident ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "missing id parameter"},
		})
	}

	incident, err := h.incidentService.GetIncident(c.Request().Context(), id)
	if err != nil {
		return c.JSON(http.StatusNotFound, v1.ErrorResponse{
			Error:   "Incident not found",
			Code:    http.StatusNotFound,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := convertIncidentToAPI(incident)
	return c.JSON(http.StatusOK, response)
}

// UpdateIncident updates an existing incident
// @Summary Update incident
// @Description Update an existing incident record
// @Tags incidents
// @Accept json
// @Produce json
// @Param id path string true "Incident ID"
// @Param request body v1.UpdateIncidentRequest true "Incident update request"
// @Success 200 {object} v1.IncidentResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents/{id} [put]
func (h *IncidentHandler) UpdateIncident(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Incident ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "missing id parameter"},
		})
	}

	var req v1.UpdateIncidentRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Convert API request to service request
	serviceReq := &service.UpdateIncidentRequest{
		Stage:              model.IncidentStage(req.Stage),
		Significant:        req.Significant,
		Recurring:          req.Recurring,
		CauseTag:           model.CauseTag(req.CauseTag),
		UsersAffected:      req.UsersAffected,
		DowntimeMinutes:    req.DowntimeMinutes,
		FinancialImpactPct: req.FinancialImpactPct,
		SectorPreset:       req.SectorPreset,
	}

	// Convert stage-specific details
	if req.InitialDetails != nil {
		serviceReq.InitialDetails = &model.InitialDetails{
			Title:               req.InitialDetails.Title,
			Summary:             req.InitialDetails.Summary,
			DetectedAt:          req.InitialDetails.DetectedAt,
			SuspectedIllegal:    req.InitialDetails.SuspectedIllegal,
			PossibleCrossBorder: req.InitialDetails.PossibleCrossBorder,
		}
	}

	if req.UpdateDetails != nil {
		serviceReq.UpdateDetails = &model.UpdateDetails{
			Gravity:     req.UpdateDetails.Gravity,
			Impact:      req.UpdateDetails.Impact,
			IOCs:        req.UpdateDetails.IOCs,
			Corrections: req.UpdateDetails.Corrections,
		}
	}

	if req.FinalDetails != nil {
		serviceReq.FinalDetails = &model.FinalDetails{
			RootCause:       req.FinalDetails.RootCause,
			Gravity:         req.FinalDetails.Gravity,
			Impact:          req.FinalDetails.Impact,
			Mitigations:     req.FinalDetails.Mitigations,
			CrossBorderDesc: req.FinalDetails.CrossBorderDesc,
			Lessons:         req.FinalDetails.Lessons,
		}
	}

	if req.Attachments != nil {
		attachments := convertAttachmentsFromAPI(*req.Attachments)
		serviceReq.Attachments = &attachments
	}

	incident, err := h.incidentService.UpdateIncident(c.Request().Context(), id, serviceReq)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to update incident",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := convertIncidentToAPI(incident)
	return c.JSON(http.StatusOK, response)
}

// DeleteIncident deletes an incident
// @Summary Delete incident
// @Description Delete an incident by ID
// @Tags incidents
// @Accept json
// @Produce json
// @Param id path string true "Incident ID"
// @Success 200 {object} v1.GenericStatusResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents/{id} [delete]
func (h *IncidentHandler) DeleteIncident(c echo.Context) error {
	id := c.Param("id")
	if id == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Incident ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "missing id parameter"},
		})
	}

	err := h.incidentService.DeleteIncident(c.Request().Context(), id)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to delete incident",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, v1.GenericStatusResponse{
		Message: "Incident deleted successfully",
	})
}

// ListIncidents retrieves all incidents
// @Summary List incidents
// @Description Retrieve all incidents with optional filtering
// @Tags incidents
// @Accept json
// @Produce json
// @Param stages query string false "Filter by stages (comma-separated)" example:"initial,update,final"
// @Param causeTags query string false "Filter by cause tags (comma-separated)" example:"phishing,malware"
// @Param significant query bool false "Filter by significant incidents only"
// @Param recurring query bool false "Filter by recurring incidents only"
// @Success 200 {object} v1.ListIncidentsResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents [get]
func (h *IncidentHandler) ListIncidents(c echo.Context) error {
	// Parse query parameters
	req := &service.ListIncidentsRequest{}

	// Parse stages filter
	if stagesStr := c.QueryParam("stages"); stagesStr != "" {
		stages := parseCommaSeparatedString(stagesStr)
		for _, stage := range stages {
			req.Stages = append(req.Stages, model.IncidentStage(stage))
		}
	}

	// Parse cause tags filter
	if causeTagsStr := c.QueryParam("causeTags"); causeTagsStr != "" {
		causeTags := parseCommaSeparatedString(causeTagsStr)
		for _, causeTag := range causeTags {
			req.CauseTags = append(req.CauseTags, model.CauseTag(causeTag))
		}
	}

	// Parse boolean filters
	if significantStr := c.QueryParam("significant"); significantStr != "" {
		if significant, err := strconv.ParseBool(significantStr); err == nil {
			req.SignificantOnly = &significant
		}
	}

	if recurringStr := c.QueryParam("recurring"); recurringStr != "" {
		if recurring, err := strconv.ParseBool(recurringStr); err == nil {
			req.RecurringOnly = &recurring
		}
	}

	// Parse date filters
	if createdAfterStr := c.QueryParam("createdAfter"); createdAfterStr != "" {
		if createdAfter, err := time.Parse(time.RFC3339, createdAfterStr); err == nil {
			req.CreatedAfter = &createdAfter
		}
	}

	if createdBeforeStr := c.QueryParam("createdBefore"); createdBeforeStr != "" {
		if createdBefore, err := time.Parse(time.RFC3339, createdBeforeStr); err == nil {
			req.CreatedBefore = &createdBefore
		}
	}

	incidents, err := h.incidentService.ListIncidents(c.Request().Context(), req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to list incidents",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Convert to API response
	apiIncidents := make([]v1.IncidentResponse, len(incidents))
	for i, incident := range incidents {
		apiIncidents[i] = convertIncidentToAPI(incident)
	}

	response := v1.ListIncidentsResponse{
		Incidents: apiIncidents,
		Total:     len(apiIncidents),
	}

	return c.JSON(http.StatusOK, response)
}

// ListIncidentSummaries retrieves incident summaries
// @Summary List incident summaries
// @Description Retrieve incident summaries with optional filtering
// @Tags incidents
// @Accept json
// @Produce json
// @Param stages query string false "Filter by stages (comma-separated)" example:"initial,update,final"
// @Param causeTags query string false "Filter by cause tags (comma-separated)" example:"phishing,malware"
// @Param significant query bool false "Filter by significant incidents only"
// @Param recurring query bool false "Filter by recurring incidents only"
// @Success 200 {object} v1.ListIncidentSummariesResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents/summaries [get]
func (h *IncidentHandler) ListIncidentSummaries(c echo.Context) error {
	// Parse query parameters (same as ListIncidents)
	req := &service.ListIncidentsRequest{}

	if stagesStr := c.QueryParam("stages"); stagesStr != "" {
		stages := parseCommaSeparatedString(stagesStr)
		for _, stage := range stages {
			req.Stages = append(req.Stages, model.IncidentStage(stage))
		}
	}

	if causeTagsStr := c.QueryParam("causeTags"); causeTagsStr != "" {
		causeTags := parseCommaSeparatedString(causeTagsStr)
		for _, causeTag := range causeTags {
			req.CauseTags = append(req.CauseTags, model.CauseTag(causeTag))
		}
	}

	if significantStr := c.QueryParam("significant"); significantStr != "" {
		if significant, err := strconv.ParseBool(significantStr); err == nil {
			req.SignificantOnly = &significant
		}
	}

	if recurringStr := c.QueryParam("recurring"); recurringStr != "" {
		if recurring, err := strconv.ParseBool(recurringStr); err == nil {
			req.RecurringOnly = &recurring
		}
	}

	summaries, err := h.incidentService.ListIncidentSummaries(c.Request().Context(), req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to list incident summaries",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Convert to API response
	apiSummaries := make([]v1.IncidentSummaryResponse, len(summaries))
	for i, summary := range summaries {
		apiSummaries[i] = v1.IncidentSummaryResponse{
			ID:          summary.ID,
			Title:       summary.Title,
			Summary:     summary.Summary,
			Stage:       string(summary.Stage),
			Significant: summary.Significant,
			Recurring:   summary.Recurring,
			CauseTag:    string(summary.CauseTag),
			CreatedAt:   summary.CreatedAt.Format(time.RFC3339),
			UpdatedAt:   summary.UpdatedAt.Format(time.RFC3339),
		}
	}

	response := v1.ListIncidentSummariesResponse{
		Summaries: apiSummaries,
		Total:     len(apiSummaries),
	}

	return c.JSON(http.StatusOK, response)
}

// GetIncidentStats retrieves incident statistics
// @Summary Get incident statistics
// @Description Retrieve statistics about incidents
// @Tags incidents
// @Accept json
// @Produce json
// @Success 200 {object} v1.IncidentStatsResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /incidents/stats [get]
func (h *IncidentHandler) GetIncidentStats(c echo.Context) error {
	stats, err := h.incidentService.GetIncidentStats(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to get incident statistics",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Convert to API response
	response := v1.IncidentStatsResponse{
		TotalIncidents:       stats.TotalIncidents,
		SignificantIncidents: stats.SignificantIncidents,
		RecurringIncidents:   stats.RecurringIncidents,
		ByStage:              make(map[string]int),
		ByCause:              make(map[string]int),
	}

	// Convert stage stats
	for stage, count := range stats.ByStage {
		response.ByStage[string(stage)] = count
	}

	// Convert cause stats
	for cause, count := range stats.ByCause {
		response.ByCause[string(cause)] = count
	}

	return c.JSON(http.StatusOK, response)
}

// Helper functions

func convertIncidentToAPI(incident *model.IncidentRecord) v1.IncidentResponse {
	response := v1.IncidentResponse{
		ID:                 incident.ID,
		CreatedAt:          incident.CreatedAt.Format(time.RFC3339),
		UpdatedAt:          incident.UpdatedAt.Format(time.RFC3339),
		Stage:              string(incident.Stage),
		Significant:        incident.Significant,
		Recurring:          incident.Recurring,
		CauseTag:           string(incident.CauseTag),
		UsersAffected:      incident.UsersAffected,
		DowntimeMinutes:    incident.DowntimeMinutes,
		FinancialImpactPct: incident.FinancialImpactPct,
		SectorPreset:       incident.SectorPreset,
		Details:            v1.IncidentDetails{},
		Attachments:        convertAttachmentsToAPI(incident.Attachments),
	}

	// Convert stage-specific details
	if incident.Details.Initial != nil {
		response.Details.Initial = &v1.InitialDetails{
			Title:               incident.Details.Initial.Title,
			Summary:             incident.Details.Initial.Summary,
			DetectedAt:          incident.Details.Initial.DetectedAt,
			SuspectedIllegal:    incident.Details.Initial.SuspectedIllegal,
			PossibleCrossBorder: incident.Details.Initial.PossibleCrossBorder,
		}
	}

	if incident.Details.Update != nil {
		response.Details.Update = &v1.UpdateDetails{
			Gravity:     incident.Details.Update.Gravity,
			Impact:      incident.Details.Update.Impact,
			IOCs:        incident.Details.Update.IOCs,
			Corrections: incident.Details.Update.Corrections,
		}
	}

	if incident.Details.Final != nil {
		response.Details.Final = &v1.FinalDetails{
			RootCause:       incident.Details.Final.RootCause,
			Gravity:         incident.Details.Final.Gravity,
			Impact:          incident.Details.Final.Impact,
			Mitigations:     incident.Details.Final.Mitigations,
			CrossBorderDesc: incident.Details.Final.CrossBorderDesc,
			Lessons:         incident.Details.Final.Lessons,
		}
	}

	return response
}

func convertAttachmentsToAPI(attachments []model.Attachment) []v1.Attachment {
	apiAttachments := make([]v1.Attachment, len(attachments))
	for i, attachment := range attachments {
		apiAttachments[i] = v1.Attachment{
			Name: attachment.Name,
			Note: attachment.Note,
		}
	}
	return apiAttachments
}

func convertAttachmentsFromAPI(attachments []v1.Attachment) []model.Attachment {
	modelAttachments := make([]model.Attachment, len(attachments))
	for i, attachment := range attachments {
		modelAttachments[i] = model.Attachment{
			Name: attachment.Name,
			Note: attachment.Note,
		}
	}
	return modelAttachments
}

func parseCommaSeparatedString(s string) []string {
	if s == "" {
		return nil
	}
	var result []string
	for _, item := range parseCommaSeparated(s) {
		if trimmed := trimSpace(item); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func parseCommaSeparated(s string) []string {
	var result []string
	current := ""
	for _, char := range s {
		if char == ',' {
			result = append(result, current)
			current = ""
		} else {
			current += string(char)
		}
	}
	result = append(result, current)
	return result
}

func trimSpace(s string) string {
	// Simple trim implementation
	start := 0
	end := len(s)

	for start < end && (s[start] == ' ' || s[start] == '\t' || s[start] == '\n' || s[start] == '\r') {
		start++
	}

	for end > start && (s[end-1] == ' ' || s[end-1] == '\t' || s[end-1] == '\n' || s[end-1] == '\r') {
		end--
	}

	return s[start:end]
}
