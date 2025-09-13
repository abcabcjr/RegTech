package service

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"path/filepath"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"

	"assetscanner/internal/config"
	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"assetscanner/internal/util"
)

// FileService handles file upload/download operations with MinIO
type FileService struct {
	minioClient *minio.Client
	storage     storage.Storage
	config      *config.MinIOConfig
	available   bool // Track if MinIO is available
}

// NewFileService creates a new file service instance
func NewFileService(minioConfig *config.MinIOConfig, storage storage.Storage) (*FileService, error) {
	service := &FileService{
		storage:   storage,
		config:    minioConfig,
		available: false,
	}

	// Try to initialize MinIO client
	client, err := minio.New(minioConfig.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(minioConfig.AccessKeyID, minioConfig.SecretAccessKey, ""),
		Secure: minioConfig.UseSSL,
	})
	if err != nil {
		log.Printf("Warning: Failed to create MinIO client: %v. File operations will be unavailable.", err)
		return service, nil // Return service but mark as unavailable
	}

	service.minioClient = client

	// Try to ensure bucket exists
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	if err := service.ensureBucket(ctx); err != nil {
		log.Printf("Warning: Failed to ensure MinIO bucket exists: %v. File operations will be unavailable.", err)
		return service, nil // Return service but mark as unavailable
	}

	service.available = true
	log.Printf("MinIO file service initialized successfully")
	return service, nil
}

// ensureBucket creates the bucket if it doesn't exist
func (fs *FileService) ensureBucket(ctx context.Context) error {
	exists, err := fs.minioClient.BucketExists(ctx, fs.config.BucketName)
	if err != nil {
		return fmt.Errorf("failed to check bucket existence: %w", err)
	}

	if !exists {
		err = fs.minioClient.MakeBucket(ctx, fs.config.BucketName, minio.MakeBucketOptions{
			Region: fs.config.Region,
		})
		if err != nil {
			return fmt.Errorf("failed to create bucket: %w", err)
		}
		log.Printf("Created MinIO bucket: %s", fs.config.BucketName)
	}

	return nil
}

// InitiateUpload creates a file attachment record and returns pre-signed upload URL
func (fs *FileService) InitiateUpload(ctx context.Context, checklistKey, originalName, contentType string, fileSize int64, description string) (*model.PresignedUploadResponse, error) {
	// Check if MinIO is available
	if !fs.available {
		return nil, fmt.Errorf("file upload service is unavailable - MinIO is not accessible")
	}

	// Validate inputs
	if checklistKey == "" {
		return nil, fmt.Errorf("checklist key is required")
	}
	if originalName == "" {
		return nil, fmt.Errorf("original file name is required")
	}
	if fileSize <= 0 {
		return nil, fmt.Errorf("file size must be positive")
	}
	if fileSize > model.MaxFileSize {
		return nil, fmt.Errorf("file size exceeds maximum allowed size of %d bytes", model.MaxFileSize)
	}
	if contentType != "" && !model.IsContentTypeSupported(contentType) {
		return nil, fmt.Errorf("content type %s is not supported", contentType)
	}

	// Generate file ID and object key
	fileID := util.GenerateID()
	objectKey := model.GenerateObjectKey(checklistKey, fileID, originalName)

	// Create file attachment record
	attachment := &model.FileAttachment{
		ID:           fileID,
		FileName:     filepath.Base(originalName),
		OriginalName: originalName,
		ContentType:  contentType,
		FileSize:     fileSize,
		UploadedAt:   time.Now(),
		Description:  description,
		ChecklistKey: checklistKey,
		BucketName:   fs.config.BucketName,
		ObjectKey:    objectKey,
		Status:       model.FileStatusUploading,
	}

	// Save attachment record
	if err := fs.storage.CreateFileAttachment(ctx, attachment); err != nil {
		return nil, fmt.Errorf("failed to create file attachment record: %w", err)
	}

	// Generate pre-signed upload URL
	presignedURL, err := fs.minioClient.PresignedPutObject(ctx, fs.config.BucketName, objectKey, fs.config.PresignDuration)
	if err != nil {
		return nil, fmt.Errorf("failed to generate pre-signed upload URL: %w", err)
	}

	response := &model.PresignedUploadResponse{
		FileID:    fileID,
		UploadURL: presignedURL.String(),
		ExpiresAt: time.Now().Add(fs.config.PresignDuration),
		Method:    "PUT",
	}

	return response, nil
}

// ConfirmUpload verifies the upload was successful and updates the file status
func (fs *FileService) ConfirmUpload(ctx context.Context, fileID string) error {
	// Check if MinIO is available
	if !fs.available {
		return fmt.Errorf("file service is unavailable - MinIO is not accessible")
	}

	// Get file attachment record
	attachment, err := fs.storage.GetFileAttachment(ctx, fileID)
	if err != nil {
		return fmt.Errorf("failed to get file attachment: %w", err)
	}

	// Check if object exists in MinIO
	objInfo, err := fs.minioClient.StatObject(ctx, attachment.BucketName, attachment.ObjectKey, minio.StatObjectOptions{})
	if err != nil {
		// Update status to failed
		attachment.Status = model.FileStatusFailed
		attachment.Error = fmt.Sprintf("Upload verification failed: %v", err)
		if updateErr := fs.storage.UpdateFileAttachment(ctx, attachment); updateErr != nil {
			log.Printf("Failed to update file attachment status: %v", updateErr)
		}
		return fmt.Errorf("file upload verification failed: %w", err)
	}

	// Update attachment with successful upload info
	attachment.Status = model.FileStatusUploaded
	attachment.ETag = objInfo.ETag
	attachment.FileSize = objInfo.Size
	attachment.Error = ""

	if err := fs.storage.UpdateFileAttachment(ctx, attachment); err != nil {
		return fmt.Errorf("failed to update file attachment: %w", err)
	}

	// Add attachment to checklist status
	if err := fs.addAttachmentToChecklist(ctx, attachment.ChecklistKey, fileID); err != nil {
		log.Printf("Failed to add attachment to checklist: %v", err)
		// Don't fail the operation, just log the error
	}

	return nil
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

// GenerateDownloadURL creates a pre-signed download URL for a file
func (fs *FileService) GenerateDownloadURL(ctx context.Context, fileID string) (*model.PresignedDownloadResponse, error) {
	// Check if MinIO is available
	if !fs.available {
		return nil, fmt.Errorf("file download service is unavailable - MinIO is not accessible")
	}

	// Get file attachment record
	attachment, err := fs.storage.GetFileAttachment(ctx, fileID)
	if err != nil {
		return nil, fmt.Errorf("failed to get file attachment: %w", err)
	}

	if attachment.Status != model.FileStatusUploaded {
		return nil, fmt.Errorf("file is not available for download (status: %s)", attachment.Status)
	}

	// Generate pre-signed download URL
	presignedURL, err := fs.minioClient.PresignedGetObject(ctx, attachment.BucketName, attachment.ObjectKey, fs.config.PresignDuration, url.Values{})
	if err != nil {
		return nil, fmt.Errorf("failed to generate pre-signed download URL: %w", err)
	}

	response := &model.PresignedDownloadResponse{
		DownloadURL: presignedURL.String(),
		ExpiresAt:   time.Now().Add(fs.config.PresignDuration),
		FileName:    attachment.OriginalName,
		ContentType: attachment.ContentType,
		FileSize:    attachment.FileSize,
	}

	return response, nil
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

// DeleteFile removes a file attachment and the associated object from MinIO
func (fs *FileService) DeleteFile(ctx context.Context, fileID string) error {
	// Get file attachment record
	attachment, err := fs.storage.GetFileAttachment(ctx, fileID)
	if err != nil {
		return fmt.Errorf("failed to get file attachment: %w", err)
	}

	// Remove object from MinIO if it exists and MinIO is available
	if attachment.Status == model.FileStatusUploaded && fs.available {
		err = fs.minioClient.RemoveObject(ctx, attachment.BucketName, attachment.ObjectKey, minio.RemoveObjectOptions{})
		if err != nil {
			log.Printf("Failed to remove object from MinIO: %v", err)
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

// IsAvailable returns whether MinIO file service is available
func (fs *FileService) IsAvailable() bool {
	return fs.available
}

// GetServiceStatus returns detailed service status information
func (fs *FileService) GetServiceStatus() map[string]interface{} {
	status := map[string]interface{}{
		"available": fs.available,
		"endpoint":  fs.config.Endpoint,
		"bucket":    fs.config.BucketName,
	}
	
	if !fs.available {
		status["error"] = "MinIO service is not accessible"
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
