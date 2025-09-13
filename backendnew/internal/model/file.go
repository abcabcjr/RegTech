package model

import "time"

// FileAttachment represents a file attached to a compliance checklist item
type FileAttachment struct {
	ID           string    `json:"id"`
	FileName     string    `json:"file_name"`
	OriginalName string    `json:"original_name"`
	ContentType  string    `json:"content_type"`
	FileSize     int64     `json:"file_size"`
	UploadedAt   time.Time `json:"uploaded_at"`
	UploadedBy   string    `json:"uploaded_by,omitempty"` // Future: user identification
	Description  string    `json:"description,omitempty"`

	// Compliance context
	ChecklistKey string `json:"checklist_key"`      // Links to SimpleChecklistStatus.Key
	AssetID      string `json:"asset_id,omitempty"` // Optional: links to specific asset

	// Storage metadata
	FilePath string `json:"file_path"` // Local file system path

	// Status
	Status string `json:"status"`          // "uploading", "uploaded", "failed", "deleted"
	Error  string `json:"error,omitempty"` // Error message if status is "failed"
}

// FileUploadResponse represents a successful file upload response
type FileUploadResponse struct {
	FileID      string    `json:"file_id"`
	FileName    string    `json:"file_name"`
	ContentType string    `json:"content_type"`
	FileSize    int64     `json:"file_size"`
	UploadedAt  time.Time `json:"uploaded_at"`
	Status      string    `json:"status"`
}

// FileAttachmentSummary represents a summary view of file attachments
type FileAttachmentSummary struct {
	ID           string    `json:"id"`
	FileName     string    `json:"file_name"`
	OriginalName string    `json:"original_name"`
	ContentType  string    `json:"content_type"`
	FileSize     int64     `json:"file_size"`
	UploadedAt   time.Time `json:"uploaded_at"`
	Description  string    `json:"description,omitempty"`
	Status       string    `json:"status"`
}

// Constants for FileAttachment Status
const (
	FileStatusUploading = "uploading"
	FileStatusUploaded  = "uploaded"
	FileStatusFailed    = "failed"
	FileStatusDeleted   = "deleted"
)

// Constants for supported content types (can be extended)
var SupportedContentTypes = map[string]bool{
	"image/jpeg":         true,
	"image/png":          true,
	"image/gif":          true,
	"image/webp":         true,
	"application/pdf":    true,
	"text/plain":         true,
	"text/csv":           true,
	"application/json":   true,
	"application/xml":    true,
	"application/msword": true,
	"application/vnd.openxmlformats-officedocument.wordprocessingml.document": true,
	"application/vnd.ms-excel": true,
	"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": true,
	"application/zip":              true,
	"application/x-zip-compressed": true,
}

// MaxFileSize defines the maximum allowed file size (50MB)
const MaxFileSize = 50 * 1024 * 1024

// IsContentTypeSupported checks if a content type is supported
func IsContentTypeSupported(contentType string) bool {
	return SupportedContentTypes[contentType]
}

// GenerateFileName generates a unique file name for local storage
func GenerateFileName(fileID, originalName string) string {
	// Format: {fileID}_{originalName}
	return fileID + "_" + originalName
}
