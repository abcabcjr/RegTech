package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"

	v1 "assetscanner/api/v1"
	"assetscanner/internal/model"
	"assetscanner/internal/service"
)

// FilesHandler handles file upload/download operations
type FilesHandler struct {
	fileService *service.FileService
}

// NewFilesHandler creates a new files handler
func NewFilesHandler(fileService *service.FileService) *FilesHandler {
	return &FilesHandler{
		fileService: fileService,
	}
}

// InitiateUploadRequest represents the request to initiate a file upload
type InitiateUploadRequest struct {
	ChecklistKey string `json:"checklist_key" validate:"required" example:"global:item1"`
	FileName     string `json:"file_name" validate:"required" example:"evidence.pdf"`
	ContentType  string `json:"content_type,omitempty" example:"application/pdf"`
	FileSize     int64  `json:"file_size" validate:"required,min=1" example:"1024"`
	Description  string `json:"description,omitempty" example:"Evidence for compliance check"`
}

// InitiateUpload creates a file attachment record and returns pre-signed upload URL
// @Summary Initiate file upload
// @Description Create a file attachment record and get a pre-signed upload URL
// @Tags files
// @Accept json
// @Produce json
// @Param request body InitiateUploadRequest true "Upload initiation request"
// @Success 200 {object} model.PresignedUploadResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/upload/initiate [post]
func (h *FilesHandler) InitiateUpload(c echo.Context) error {
	var req InitiateUploadRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid request body",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Validate filename
	if err := service.ValidateFileName(req.FileName); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid filename",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response, err := h.fileService.InitiateUpload(
		c.Request().Context(),
		req.ChecklistKey,
		req.FileName,
		req.ContentType,
		req.FileSize,
		req.Description,
	)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to initiate upload",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, response)
}

// ConfirmUpload verifies that a file upload was completed successfully
// @Summary Confirm file upload
// @Description Verify that a file upload was completed and update the file status
// @Tags files
// @Accept json
// @Produce json
// @Param fileId path string true "File ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/{fileId}/confirm [post]
func (h *FilesHandler) ConfirmUpload(c echo.Context) error {
	fileID := c.Param("fileId")
	if fileID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "fileId parameter is missing"},
		})
	}

	err := h.fileService.ConfirmUpload(c.Request().Context(), fileID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to confirm upload",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Upload confirmed successfully",
		"file_id": fileID,
	})
}

// GenerateDownloadURL creates a pre-signed download URL for a file
// @Summary Generate download URL
// @Description Generate a pre-signed download URL for a file attachment
// @Tags files
// @Produce json
// @Param fileId path string true "File ID"
// @Success 200 {object} model.PresignedDownloadResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/{fileId}/download [get]
func (h *FilesHandler) GenerateDownloadURL(c echo.Context) error {
	fileID := c.Param("fileId")
	if fileID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "fileId parameter is missing"},
		})
	}

	response, err := h.fileService.GenerateDownloadURL(c.Request().Context(), fileID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to generate download URL",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, response)
}

// GetFileInfo retrieves file attachment metadata
// @Summary Get file information
// @Description Get metadata for a file attachment
// @Tags files
// @Produce json
// @Param fileId path string true "File ID"
// @Success 200 {object} model.FileAttachment
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/{fileId} [get]
func (h *FilesHandler) GetFileInfo(c echo.Context) error {
	fileID := c.Param("fileId")
	if fileID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "fileId parameter is missing"},
		})
	}

	attachment, err := h.fileService.GetFileAttachment(c.Request().Context(), fileID)
	if err != nil {
		return c.JSON(http.StatusNotFound, v1.ErrorResponse{
			Error:   "File not found",
			Code:    http.StatusNotFound,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, attachment)
}

// ListFileAttachments retrieves file attachments for a checklist key
// @Summary List file attachments
// @Description List all file attachments for a specific checklist key
// @Tags files
// @Produce json
// @Param checklistKey query string true "Checklist key (e.g., global:item1 or asset:assetId:item1)"
// @Success 200 {array} model.FileAttachmentSummary
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files [get]
func (h *FilesHandler) ListFileAttachments(c echo.Context) error {
	checklistKey := c.QueryParam("checklistKey")
	if checklistKey == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Checklist key is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "checklistKey query parameter is missing"},
		})
	}

	attachments, err := h.fileService.ListFileAttachments(c.Request().Context(), checklistKey)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to list file attachments",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, attachments)
}

// DeleteFile removes a file attachment
// @Summary Delete file attachment
// @Description Delete a file attachment and remove it from MinIO storage
// @Tags files
// @Produce json
// @Param fileId path string true "File ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/{fileId} [delete]
func (h *FilesHandler) DeleteFile(c echo.Context) error {
	fileID := c.Param("fileId")
	if fileID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "fileId parameter is missing"},
		})
	}

	err := h.fileService.DeleteFile(c.Request().Context(), fileID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to delete file",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "File deleted successfully",
		"file_id": fileID,
	})
}

// GetSupportedContentTypes returns the list of supported content types
// @Summary Get supported content types
// @Description Get the list of content types that are supported for file uploads
// @Tags files
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /files/supported-types [get]
func (h *FilesHandler) GetSupportedContentTypes(c echo.Context) error {
	supportedTypes := make([]string, 0, len(model.SupportedContentTypes))
	for contentType := range model.SupportedContentTypes {
		supportedTypes = append(supportedTypes, contentType)
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"supported_content_types": supportedTypes,
		"max_file_size_bytes":     model.MaxFileSize,
		"max_file_size_mb":        model.MaxFileSize / (1024 * 1024),
	})
}

// GetUploadLimits returns upload limits and restrictions
// @Summary Get upload limits
// @Description Get information about file upload limits and restrictions
// @Tags files
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /files/limits [get]
func (h *FilesHandler) GetUploadLimits(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]interface{}{
		"max_file_size_bytes": model.MaxFileSize,
		"max_file_size_mb":    model.MaxFileSize / (1024 * 1024),
		"max_filename_length": 255,
		"supported_types":     len(model.SupportedContentTypes),
	})
}

// GetServiceStatus returns the status of the file upload service
// @Summary Get file service status
// @Description Get the current status of the MinIO file upload service
// @Tags files
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /files/status [get]
func (h *FilesHandler) GetServiceStatus(c echo.Context) error {
	status := h.fileService.GetServiceStatus()
	
	// Return 503 if service is unavailable, but still provide status info
	if !h.fileService.IsAvailable() {
		return c.JSON(http.StatusServiceUnavailable, status)
	}
	
	return c.JSON(http.StatusOK, status)
}
