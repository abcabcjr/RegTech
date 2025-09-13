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
	BucketName string `json:"bucket_name"`
	ObjectKey  string `json:"object_key"`     // Full path in MinIO
	ETag       string `json:"etag,omitempty"` // MinIO ETag for integrity

	// Status
	Status string `json:"status"`          // "uploading", "uploaded", "failed", "deleted"
	Error  string `json:"error,omitempty"` // Error message if status is "failed"
}

// PresignedUploadResponse represents a pre-signed upload URL response
type PresignedUploadResponse struct {
	FileID    string            `json:"file_id"`
	UploadURL string            `json:"upload_url"`
	ExpiresAt time.Time         `json:"expires_at"`
	Fields    map[string]string `json:"fields,omitempty"` // Additional form fields for POST uploads
	Method    string            `json:"method"`           // "PUT" or "POST"
}

// PresignedDownloadResponse represents a pre-signed download URL response
type PresignedDownloadResponse struct {
	DownloadURL string    `json:"download_url"`
	ExpiresAt   time.Time `json:"expires_at"`
	FileName    string    `json:"file_name"`
	ContentType string    `json:"content_type"`
	FileSize    int64     `json:"file_size"`
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

// GenerateObjectKey generates a unique object key for MinIO storage
func GenerateObjectKey(checklistKey, fileID, originalName string) string {
	// Format: compliance/{checklistKey}/{fileID}_{originalName}
	return "compliance/" + checklistKey + "/" + fileID + "_" + originalName
}
