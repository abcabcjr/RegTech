package storage

import (
	"assetscanner/internal/model"
	"context"
)

// Storage defines the interface for data persistence
type Storage interface {
	// Asset operations
	CreateAsset(ctx context.Context, asset *model.Asset) error
	GetAsset(ctx context.Context, id string) (*model.Asset, error)
	UpdateAsset(ctx context.Context, asset *model.Asset) error
	DeleteAsset(ctx context.Context, id string) error
	ClearAllAssets(ctx context.Context) error
	ListAssets(ctx context.Context, filter *model.AssetFilter) ([]*model.Asset, error)
	GetAssetsByType(ctx context.Context, assetType string) ([]*model.Asset, error)

	// Job operations
	CreateJob(ctx context.Context, job *model.Job) error
	GetJob(ctx context.Context, id string) (*model.Job, error)
	UpdateJob(ctx context.Context, job *model.Job) error
	ListJobs(ctx context.Context) ([]*model.Job, error)
	GetActiveJobs(ctx context.Context) ([]*model.Job, error)

	// Scan result operations
	CreateScanResult(ctx context.Context, result *model.ScanResult) error
	GetScanResult(ctx context.Context, id string) (*model.ScanResult, error)
	GetScanResultsByAsset(ctx context.Context, assetID string) ([]*model.ScanResult, error)
	GetScanResultsByScript(ctx context.Context, scriptName string) ([]*model.ScanResult, error)
	ListScanResults(ctx context.Context) ([]*model.ScanResult, error)
	ClearScanResultsByAsset(ctx context.Context, assetID string) error

	// Script operations
	CreateScript(ctx context.Context, script *model.Script) error
	GetScript(ctx context.Context, name string) (*model.Script, error)
	UpdateScript(ctx context.Context, script *model.Script) error
	DeleteScript(ctx context.Context, name string) error
	ListScripts(ctx context.Context) ([]*model.Script, error)

	// Checklist operations
	CreateChecklistTemplate(ctx context.Context, template *model.ChecklistItemTemplate) error
	GetChecklistTemplate(ctx context.Context, id string) (*model.ChecklistItemTemplate, error)
	UpdateChecklistTemplate(ctx context.Context, template *model.ChecklistItemTemplate) error
	DeleteChecklistTemplate(ctx context.Context, id string) error
	ListChecklistTemplates(ctx context.Context) ([]*model.ChecklistItemTemplate, error)

	// Simple checklist status operations
	SetChecklistStatus(ctx context.Context, key string, status *model.SimpleChecklistStatus) error
	GetChecklistStatus(ctx context.Context, key string) (*model.SimpleChecklistStatus, error)
	ListChecklistStatuses(ctx context.Context) (map[string]*model.SimpleChecklistStatus, error)

	// File attachment operations
	CreateFileAttachment(ctx context.Context, attachment *model.FileAttachment) error
	GetFileAttachment(ctx context.Context, id string) (*model.FileAttachment, error)
	UpdateFileAttachment(ctx context.Context, attachment *model.FileAttachment) error
	DeleteFileAttachment(ctx context.Context, id string) error
	ListFileAttachments(ctx context.Context, checklistKey string) ([]*model.FileAttachment, error)
	ListAllFileAttachments(ctx context.Context) ([]*model.FileAttachment, error)

	// Utility operations
	Close() error
	Backup() error
	GetStats() (*StorageStats, error)
}

// StorageStats provides statistics about the storage
type StorageStats struct {
	AssetCount          int64   `json:"asset_count"`
	JobCount            int64   `json:"job_count"`
	ScanResultCount     int64   `json:"scan_result_count"`
	ScriptCount         int64   `json:"script_count"`
	FileAttachmentCount int64   `json:"file_attachment_count"`
	LastBackup          *string `json:"last_backup,omitempty"`
}
