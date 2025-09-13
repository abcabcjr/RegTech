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

// UploadFileRequest represents the form data for file upload
type UploadFileRequest struct {
	ChecklistKey string `form:"checklist_key" validate:"required" example:"global:item1"`
	Description  string `form:"description,omitempty" example:"Evidence for compliance check"`
}

// UploadFile handles direct file upload
// @Summary Upload file
// @Description Upload a file directly as part of a checklist item
// @Tags files
// @Accept multipart/form-data
// @Produce json
// @Param checklist_key formData string true "Checklist key (e.g., global:item1)"
// @Param description formData string false "File description"
// @Param file formData file true "File to upload"
// @Success 201 {object} model.FileUploadResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/upload [post]
func (h *FilesHandler) UploadFile(c echo.Context) error {
	// Parse multipart form
	checklistKey := c.FormValue("checklist_key")
	description := c.FormValue("description")

	if checklistKey == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Checklist key is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "checklist_key form field is missing"},
		})
	}

	// Get uploaded file
	fileHeader, err := c.FormFile("file")
	if err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Validate filename
	if err := service.ValidateFileName(fileHeader.Filename); err != nil {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "Invalid filename",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": err.Error()},
		})
	}

	// Detect content type from file header
	contentType := fileHeader.Header.Get("Content-Type")

	// Upload file
	attachment, err := h.fileService.UploadFile(
		c.Request().Context(),
		checklistKey,
		fileHeader.Filename,
		contentType,
		fileHeader,
		description,
	)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
			Error:   "Failed to upload file",
			Code:    http.StatusInternalServerError,
			Details: map[string]string{"error": err.Error()},
		})
	}

	response := &model.FileUploadResponse{
		FileID:      attachment.ID,
		FileName:    attachment.FileName,
		ContentType: attachment.ContentType,
		FileSize:    attachment.FileSize,
		UploadedAt:  attachment.UploadedAt,
		Status:      attachment.Status,
	}

	return c.JSON(http.StatusCreated, response)
}

// DownloadFile serves a file directly for download
// @Summary Download file
// @Description Download a file attachment directly
// @Tags files
// @Produce application/octet-stream
// @Param fileId path string true "File ID"
// @Success 200 {file} binary "File content"
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /files/{fileId}/download [get]
func (h *FilesHandler) DownloadFile(c echo.Context) error {
	fileID := c.Param("fileId")
	if fileID == "" {
		return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
			Error:   "File ID is required",
			Code:    http.StatusBadRequest,
			Details: map[string]string{"error": "fileId parameter is missing"},
		})
	}

	file, attachment, err := h.fileService.GetFile(c.Request().Context(), fileID)
	if err != nil {
		return c.JSON(http.StatusNotFound, v1.ErrorResponse{
			Error:   "File not found",
			Code:    http.StatusNotFound,
			Details: map[string]string{"error": err.Error()},
		})
	}
	defer file.Close()

	// Set appropriate headers
	c.Response().Header().Set("Content-Disposition", `attachment; filename="`+attachment.OriginalName+`"`)
	if attachment.ContentType != "" {
		c.Response().Header().Set("Content-Type", attachment.ContentType)
	} else {
		c.Response().Header().Set("Content-Type", "application/octet-stream")
	}

	// Stream the file
	return c.Stream(http.StatusOK, attachment.ContentType, file)
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
