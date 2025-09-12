package storage

import (
	"assetscanner/internal/config"
	"assetscanner/internal/errors"
	"assetscanner/internal/model"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// JSONStorage implements Storage interface using JSON files
type JSONStorage struct {
	config      *config.StorageConfig
	mu          sync.RWMutex
	assets      map[string]*model.Asset
	jobs        map[string]*model.Job
	scanResults map[string]*model.ScanResult
	scripts     map[string]*model.Script
	lastBackup  *time.Time
}

// NewJSONStorage creates a new JSON file storage
func NewJSONStorage(cfg *config.StorageConfig) (*JSONStorage, error) {
	storage := &JSONStorage{
		config:      cfg,
		assets:      make(map[string]*model.Asset),
		jobs:        make(map[string]*model.Job),
		scanResults: make(map[string]*model.ScanResult),
		scripts:     make(map[string]*model.Script),
	}

	// Create data directory if it doesn't exist
	if err := os.MkdirAll(cfg.DataDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create data directory: %w", err)
	}

	// Load existing data
	if err := storage.loadData(); err != nil {
		return nil, fmt.Errorf("failed to load existing data: %w", err)
	}

	// Start backup routine if enabled
	if cfg.BackupEnabled {
		go storage.backupRoutine()
	}

	return storage, nil
}

// Asset operations

func (s *JSONStorage) CreateAsset(ctx context.Context, asset *model.Asset) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.assets[asset.ID]; exists {
		return errors.NewConflict(fmt.Sprintf("Asset with ID %s already exists", asset.ID))
	}

	s.assets[asset.ID] = asset
	return s.saveAssets()
}

func (s *JSONStorage) GetAsset(ctx context.Context, id string) (*model.Asset, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	asset, exists := s.assets[id]
	if !exists {
		return nil, errors.NewNotFound("Asset")
	}

	return asset, nil
}

func (s *JSONStorage) UpdateAsset(ctx context.Context, asset *model.Asset) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.assets[asset.ID]; !exists {
		return errors.NewNotFound("Asset")
	}

	s.assets[asset.ID] = asset
	return s.saveAssets()
}

func (s *JSONStorage) DeleteAsset(ctx context.Context, id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.assets[id]; !exists {
		return errors.NewNotFound("Asset")
	}

	delete(s.assets, id)
	return s.saveAssets()
}

func (s *JSONStorage) ListAssets(ctx context.Context, filter *model.AssetFilter) ([]*model.Asset, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var assets []*model.Asset
	for _, asset := range s.assets {
		if filter == nil || s.matchesFilter(asset, filter) {
			assets = append(assets, asset)
		}
	}

	return assets, nil
}

func (s *JSONStorage) GetAssetsByType(ctx context.Context, assetType string) ([]*model.Asset, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var assets []*model.Asset
	for _, asset := range s.assets {
		if asset.Type == assetType {
			assets = append(assets, asset)
		}
	}

	return assets, nil
}

// Job operations

func (s *JSONStorage) CreateJob(ctx context.Context, job *model.Job) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.jobs[job.ID]; exists {
		return errors.NewConflict(fmt.Sprintf("Job with ID %s already exists", job.ID))
	}

	s.jobs[job.ID] = job
	return s.saveJobs()
}

func (s *JSONStorage) GetJob(ctx context.Context, id string) (*model.Job, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	job, exists := s.jobs[id]
	if !exists {
		return nil, errors.NewNotFound("Job")
	}

	return job, nil
}

func (s *JSONStorage) UpdateJob(ctx context.Context, job *model.Job) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.jobs[job.ID]; !exists {
		return errors.NewNotFound("Job")
	}

	s.jobs[job.ID] = job
	return s.saveJobs()
}

func (s *JSONStorage) ListJobs(ctx context.Context) ([]*model.Job, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var jobs []*model.Job
	for _, job := range s.jobs {
		jobs = append(jobs, job)
	}

	return jobs, nil
}

func (s *JSONStorage) GetActiveJobs(ctx context.Context) ([]*model.Job, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var jobs []*model.Job
	for _, job := range s.jobs {
		if !job.IsCompleted() {
			jobs = append(jobs, job)
		}
	}

	return jobs, nil
}

// Scan result operations

func (s *JSONStorage) CreateScanResult(ctx context.Context, result *model.ScanResult) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.scanResults[result.ID]; exists {
		return errors.NewConflict(fmt.Sprintf("Scan result with ID %s already exists", result.ID))
	}

	s.scanResults[result.ID] = result
	return s.saveScanResults()
}

func (s *JSONStorage) GetScanResult(ctx context.Context, id string) (*model.ScanResult, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	result, exists := s.scanResults[id]
	if !exists {
		return nil, errors.NewNotFound("Scan result")
	}

	return result, nil
}

func (s *JSONStorage) GetScanResultsByAsset(ctx context.Context, assetID string) ([]*model.ScanResult, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var results []*model.ScanResult
	for _, result := range s.scanResults {
		if result.AssetID == assetID {
			results = append(results, result)
		}
	}

	return results, nil
}

func (s *JSONStorage) GetScanResultsByScript(ctx context.Context, scriptName string) ([]*model.ScanResult, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var results []*model.ScanResult
	for _, result := range s.scanResults {
		if result.ScriptName == scriptName {
			results = append(results, result)
		}
	}

	return results, nil
}

func (s *JSONStorage) ListScanResults(ctx context.Context) ([]*model.ScanResult, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var results []*model.ScanResult
	for _, result := range s.scanResults {
		results = append(results, result)
	}

	return results, nil
}

// Script operations

func (s *JSONStorage) CreateScript(ctx context.Context, script *model.Script) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.scripts[script.Name]; exists {
		return errors.NewConflict(fmt.Sprintf("Script with name %s already exists", script.Name))
	}

	s.scripts[script.Name] = script
	return s.saveScripts()
}

func (s *JSONStorage) GetScript(ctx context.Context, name string) (*model.Script, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	script, exists := s.scripts[name]
	if !exists {
		return nil, errors.NewNotFound("Script")
	}

	return script, nil
}

func (s *JSONStorage) UpdateScript(ctx context.Context, script *model.Script) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.scripts[script.Name]; !exists {
		return errors.NewNotFound("Script")
	}

	s.scripts[script.Name] = script
	return s.saveScripts()
}

func (s *JSONStorage) DeleteScript(ctx context.Context, name string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.scripts[name]; !exists {
		return errors.NewNotFound("Script")
	}

	delete(s.scripts, name)
	return s.saveScripts()
}

func (s *JSONStorage) ListScripts(ctx context.Context) ([]*model.Script, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var scripts []*model.Script
	for _, script := range s.scripts {
		scripts = append(scripts, script)
	}

	return scripts, nil
}

// Utility operations

func (s *JSONStorage) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Save all data before closing
	if err := s.saveAll(); err != nil {
		return fmt.Errorf("failed to save data on close: %w", err)
	}

	return nil
}

func (s *JSONStorage) Backup() error {
	s.mu.RLock()
	defer s.mu.RUnlock()

	timestamp := time.Now().Format("20060102_150405")
	backupDir := filepath.Join(s.config.DataDir, "backups", timestamp)

	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %w", err)
	}

	// Backup each data file
	files := []string{
		s.config.AssetsFile,
		s.config.JobsFile,
		s.config.ScanResultsFile,
	}

	for _, file := range files {
		srcPath := filepath.Join(s.config.DataDir, file)
		dstPath := filepath.Join(backupDir, file)

		if err := s.copyFile(srcPath, dstPath); err != nil {
			return fmt.Errorf("failed to backup %s: %w", file, err)
		}
	}

	now := time.Now()
	s.lastBackup = &now

	return nil
}

func (s *JSONStorage) GetStats() (*StorageStats, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var lastBackupStr *string
	if s.lastBackup != nil {
		str := s.lastBackup.Format(time.RFC3339)
		lastBackupStr = &str
	}

	return &StorageStats{
		AssetCount:      int64(len(s.assets)),
		JobCount:        int64(len(s.jobs)),
		ScanResultCount: int64(len(s.scanResults)),
		ScriptCount:     int64(len(s.scripts)),
		LastBackup:      lastBackupStr,
	}, nil
}

// Private helper methods

func (s *JSONStorage) loadData() error {
	if err := s.loadAssets(); err != nil {
		return err
	}
	if err := s.loadJobs(); err != nil {
		return err
	}
	if err := s.loadScanResults(); err != nil {
		return err
	}
	return s.loadScripts()
}

func (s *JSONStorage) loadAssets() error {
	filePath := filepath.Join(s.config.DataDir, s.config.AssetsFile)
	return s.loadJSONFile(filePath, &s.assets)
}

func (s *JSONStorage) loadJobs() error {
	filePath := filepath.Join(s.config.DataDir, s.config.JobsFile)
	return s.loadJSONFile(filePath, &s.jobs)
}

func (s *JSONStorage) loadScanResults() error {
	filePath := filepath.Join(s.config.DataDir, s.config.ScanResultsFile)
	return s.loadJSONFile(filePath, &s.scanResults)
}

func (s *JSONStorage) loadScripts() error {
	filePath := filepath.Join(s.config.DataDir, "scripts.json")
	return s.loadJSONFile(filePath, &s.scripts)
}

func (s *JSONStorage) saveAssets() error {
	filePath := filepath.Join(s.config.DataDir, s.config.AssetsFile)
	return s.saveJSONFile(filePath, s.assets)
}

func (s *JSONStorage) saveJobs() error {
	filePath := filepath.Join(s.config.DataDir, s.config.JobsFile)
	return s.saveJSONFile(filePath, s.jobs)
}

func (s *JSONStorage) saveScanResults() error {
	filePath := filepath.Join(s.config.DataDir, s.config.ScanResultsFile)
	return s.saveJSONFile(filePath, s.scanResults)
}

func (s *JSONStorage) saveScripts() error {
	filePath := filepath.Join(s.config.DataDir, "scripts.json")
	return s.saveJSONFile(filePath, s.scripts)
}

func (s *JSONStorage) saveAll() error {
	if err := s.saveAssets(); err != nil {
		return err
	}
	if err := s.saveJobs(); err != nil {
		return err
	}
	if err := s.saveScanResults(); err != nil {
		return err
	}
	return s.saveScripts()
}

func (s *JSONStorage) loadJSONFile(filePath string, data interface{}) error {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		// File doesn't exist, that's okay
		return nil
	}

	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("failed to open file %s: %w", filePath, err)
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	if err := decoder.Decode(data); err != nil {
		return fmt.Errorf("failed to decode JSON from %s: %w", filePath, err)
	}

	return nil
}

func (s *JSONStorage) saveJSONFile(filePath string, data interface{}) error {
	file, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("failed to create file %s: %w", filePath, err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(data); err != nil {
		return fmt.Errorf("failed to encode JSON to %s: %w", filePath, err)
	}

	return nil
}

func (s *JSONStorage) matchesFilter(asset *model.Asset, filter *model.AssetFilter) bool {
	// Type filter
	if len(filter.Types) > 0 {
		found := false
		for _, t := range filter.Types {
			if asset.Type == t {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Status filter
	if len(filter.Status) > 0 {
		found := false
		for _, s := range filter.Status {
			if asset.Status == s {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Date filters
	if filter.DateFrom != nil && asset.DiscoveredAt.Before(*filter.DateFrom) {
		return false
	}
	if filter.DateTo != nil && asset.DiscoveredAt.After(*filter.DateTo) {
		return false
	}

	// Has results filter
	if filter.HasResults != nil {
		hasResults := len(asset.ScanResults) > 0
		if *filter.HasResults != hasResults {
			return false
		}
	}

	return true
}

func (s *JSONStorage) copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = destFile.ReadFrom(sourceFile)
	return err
}

func (s *JSONStorage) backupRoutine() {
	ticker := time.NewTicker(s.config.BackupInterval)
	defer ticker.Stop()

	for range ticker.C {
		if err := s.Backup(); err != nil {
			// Log error but continue
			fmt.Printf("Backup failed: %v\n", err)
		}
	}
}

// ClearAllAssets removes all assets from storage
func (s *JSONStorage) ClearAllAssets(ctx context.Context) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Clear the in-memory assets map
	s.assets = make(map[string]*model.Asset)

	// Save the empty assets to file
	if err := s.saveAssets(); err != nil {
		return fmt.Errorf("failed to save cleared assets: %w", err)
	}

	fmt.Printf("[JSONStorage] Cleared all assets from storage\n")
	return nil
}
