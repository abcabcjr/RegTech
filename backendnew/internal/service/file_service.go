package service

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"assetscanner/internal/util"
)

// FileService handles file upload/download operations with local file storage
type FileService struct {
	storage   storage.Storage
	filesDir  string // Directory to store uploaded files
	available bool   // Track if file service is available
}

// NewFileService creates a new file service instance
func NewFileService(dataDir string, storage storage.Storage) (*FileService, error) {
	filesDir := filepath.Join(dataDir, "files")

	service := &FileService{
		storage:   storage,
		filesDir:  filesDir,
		available: false,
	}

	// Create files directory if it doesn't exist
	if err := os.MkdirAll(filesDir, 0755); err != nil {
		log.Printf("Warning: Failed to create files directory: %v. File operations will be unavailable.", err)
		return service, nil // Return service but mark as unavailable
	}

	service.available = true
	log.Printf("File service initialized successfully with directory: %s", filesDir)
	return service, nil
}

// generateFilePath generates a unique file path for storage
func (fs *FileService) generateFilePath(checklistKey, fileID, originalName string) string {
	// Create subdirectory structure: files/checklist_key/fileID_originalName
	sanitizedKey := strings.ReplaceAll(checklistKey, ":", "_")
	fileName := fileID + "_" + originalName
	return filepath.Join(fs.filesDir, sanitizedKey, fileName)
}

// UploadFile directly uploads a file to local storage
func (fs *FileService) UploadFile(ctx context.Context, checklistKey, originalName, contentType string, fileHeader *multipart.FileHeader, description string) (*model.FileAttachment, error) {
	// Check if file service is available
	if !fs.available {
		return nil, fmt.Errorf("file upload service is unavailable - files directory not accessible")
	}

	// Validate inputs
	if checklistKey == "" {
		return nil, fmt.Errorf("checklist key is required")
	}
	if originalName == "" {
		return nil, fmt.Errorf("original file name is required")
	}
	if fileHeader == nil {
		return nil, fmt.Errorf("file is required")
	}
	if fileHeader.Size <= 0 {
		return nil, fmt.Errorf("file size must be positive")
	}
	if fileHeader.Size > model.MaxFileSize {
		return nil, fmt.Errorf("file size exceeds maximum allowed size of %d bytes", model.MaxFileSize)
	}
	if contentType != "" && !model.IsContentTypeSupported(contentType) {
		return nil, fmt.Errorf("content type %s is not supported", contentType)
	}

	// Generate file ID and path
	fileID := util.GenerateID()
	filePath := fs.generateFilePath(checklistKey, fileID, originalName)

	// Create directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
		return nil, fmt.Errorf("failed to create file directory: %w", err)
	}

	// Open uploaded file
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()

	// Create destination file
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, src); err != nil {
		// Clean up partial file
		os.Remove(filePath)
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	// Create file attachment record
	attachment := &model.FileAttachment{
		ID:           fileID,
		FileName:     filepath.Base(originalName),
		OriginalName: originalName,
		ContentType:  contentType,
		FileSize:     fileHeader.Size,
		UploadedAt:   time.Now(),
		Description:  description,
		ChecklistKey: checklistKey,
		FilePath:     filePath, // Store local file path instead of MinIO keys
		Status:       model.FileStatusUploaded,
	}

	// Save attachment record
	if err := fs.storage.CreateFileAttachment(ctx, attachment); err != nil {
		// Clean up file if database save fails
		os.Remove(filePath)
		return nil, fmt.Errorf("failed to create file attachment record: %w", err)
	}

	// Add attachment to checklist status
	if err := fs.addAttachmentToChecklist(ctx, attachment.ChecklistKey, fileID); err != nil {
		log.Printf("Failed to add attachment to checklist: %v", err)
		// Don't fail the operation, just log the error
	}

	return attachment, nil
}

// addAttachmentToChecklist adds the file attachment ID to the checklist status
func (fs *FileService) addAttachmentToChecklist(ctx context.Context, checklistKey, fileID string) error {
	status, err := fs.storage.GetChecklistStatus(ctx, checklistKey)
	if err != nil {
		// Create new status if it doesn't exist
		status = &model.SimpleChecklistStatus{
			Key:         checklistKey,
			Status:      model.ChecklistStatusNA,
			UpdatedAt:   time.Now(),
			Attachments: []string{fileID},
		}
		return fs.storage.SetChecklistStatus(ctx, checklistKey, status)
	}

	// Add attachment ID if not already present
	for _, attachmentID := range status.Attachments {
		if attachmentID == fileID {
			return nil // Already present
		}
	}

	status.Attachments = append(status.Attachments, fileID)
	status.UpdatedAt = time.Now()

	return fs.storage.SetChecklistStatus(ctx, checklistKey, status)
}

// GetFile returns the file content for direct download
func (fs *FileService) GetFile(ctx context.Context, fileID string) (*os.File, *model.FileAttachment, error) {
	// Check if file service is available
	if !fs.available {
		return nil, nil, fmt.Errorf("file download service is unavailable - files directory not accessible")
	}

	// Get file attachment record
	attachment, err := fs.storage.GetFileAttachment(ctx, fileID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get file attachment: %w", err)
	}

	if attachment.Status != model.FileStatusUploaded {
		return nil, nil, fmt.Errorf("file is not available for download (status: %s)", attachment.Status)
	}

	// Check if file exists
	if _, err := os.Stat(attachment.FilePath); os.IsNotExist(err) {
		return nil, nil, fmt.Errorf("file not found on disk: %s", attachment.FilePath)
	}

	// Open file for reading
	file, err := os.Open(attachment.FilePath)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to open file: %w", err)
	}

	return file, attachment, nil
}

// GetFileAttachment retrieves file attachment metadata
func (fs *FileService) GetFileAttachment(ctx context.Context, fileID string) (*model.FileAttachment, error) {
	return fs.storage.GetFileAttachment(ctx, fileID)
}

// ListFileAttachments retrieves file attachments for a checklist key
func (fs *FileService) ListFileAttachments(ctx context.Context, checklistKey string) ([]*model.FileAttachmentSummary, error) {
	attachments, err := fs.storage.ListFileAttachments(ctx, checklistKey)
	if err != nil {
		return nil, fmt.Errorf("failed to list file attachments: %w", err)
	}

	summaries := make([]*model.FileAttachmentSummary, len(attachments))
	for i, attachment := range attachments {
		summaries[i] = &model.FileAttachmentSummary{
			ID:           attachment.ID,
			FileName:     attachment.FileName,
			OriginalName: attachment.OriginalName,
			ContentType:  attachment.ContentType,
			FileSize:     attachment.FileSize,
			UploadedAt:   attachment.UploadedAt,
			Description:  attachment.Description,
			Status:       attachment.Status,
		}
	}

	return summaries, nil
}

// DeleteFile removes a file attachment and the associated file from disk
func (fs *FileService) DeleteFile(ctx context.Context, fileID string) error {
	// Get file attachment record
	attachment, err := fs.storage.GetFileAttachment(ctx, fileID)
	if err != nil {
		return fmt.Errorf("failed to get file attachment: %w", err)
	}

	// Remove file from disk if it exists
	if attachment.Status == model.FileStatusUploaded && attachment.FilePath != "" {
		if err := os.Remove(attachment.FilePath); err != nil && !os.IsNotExist(err) {
			log.Printf("Failed to remove file from disk: %v", err)
			// Continue with deletion from database
		}
	}

	// Remove attachment from checklist status
	if err := fs.removeAttachmentFromChecklist(ctx, attachment.ChecklistKey, fileID); err != nil {
		log.Printf("Failed to remove attachment from checklist: %v", err)
		// Continue with deletion
	}

	// Update status to deleted
	attachment.Status = model.FileStatusDeleted
	if err := fs.storage.UpdateFileAttachment(ctx, attachment); err != nil {
		return fmt.Errorf("failed to update file attachment status: %w", err)
	}

	return nil
}

// removeAttachmentFromChecklist removes the file attachment ID from the checklist status
func (fs *FileService) removeAttachmentFromChecklist(ctx context.Context, checklistKey, fileID string) error {
	status, err := fs.storage.GetChecklistStatus(ctx, checklistKey)
	if err != nil {
		return err // Checklist status doesn't exist
	}

	// Remove attachment ID
	newAttachments := make([]string, 0, len(status.Attachments))
	for _, attachmentID := range status.Attachments {
		if attachmentID != fileID {
			newAttachments = append(newAttachments, attachmentID)
		}
	}

	status.Attachments = newAttachments
	status.UpdatedAt = time.Now()

	return fs.storage.SetChecklistStatus(ctx, checklistKey, status)
}

// CleanupFailedUploads removes file attachment records for uploads that failed or were abandoned
func (fs *FileService) CleanupFailedUploads(ctx context.Context, olderThan time.Duration) error {
	// This would require additional storage methods to query by status and time
	// For now, we'll implement this as a placeholder
	log.Printf("Cleanup of failed uploads older than %v would be performed here", olderThan)

	return nil
}

// IsAvailable returns whether file service is available
func (fs *FileService) IsAvailable() bool {
	return fs.available
}

// GetServiceStatus returns detailed service status information
func (fs *FileService) GetServiceStatus() map[string]interface{} {
	status := map[string]interface{}{
		"available":    fs.available,
		"files_dir":    fs.filesDir,
		"storage_type": "local_filesystem",
	}

	if !fs.available {
		status["error"] = "File service is not accessible"
	}

	return status
}

// ValidateFileName checks if a filename is safe for storage
func ValidateFileName(filename string) error {
	if filename == "" {
		return fmt.Errorf("filename cannot be empty")
	}

	// Check for dangerous characters
	dangerous := []string{"..", "/", "\\", ":", "*", "?", "\"", "<", ">", "|"}
	for _, char := range dangerous {
		if strings.Contains(filename, char) {
			return fmt.Errorf("filename contains invalid character: %s", char)
		}
	}

	// Check length
	if len(filename) > 255 {
		return fmt.Errorf("filename too long (max 255 characters)")
	}

	return nil
}
