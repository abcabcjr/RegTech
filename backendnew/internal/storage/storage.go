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

	// Script operations
	CreateScript(ctx context.Context, script *model.Script) error
	GetScript(ctx context.Context, name string) (*model.Script, error)
	UpdateScript(ctx context.Context, script *model.Script) error
	DeleteScript(ctx context.Context, name string) error
	ListScripts(ctx context.Context) ([]*model.Script, error)

	// Utility operations
	Close() error
	Backup() error
	GetStats() (*StorageStats, error)
}

// StorageStats provides statistics about the storage
type StorageStats struct {
	AssetCount      int64   `json:"asset_count"`
	JobCount        int64   `json:"job_count"`
	ScanResultCount int64   `json:"scan_result_count"`
	ScriptCount     int64   `json:"script_count"`
	LastBackup      *string `json:"last_backup,omitempty"`
}
