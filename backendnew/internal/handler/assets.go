package handler

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/errors"
	"assetscanner/internal/model"
	"assetscanner/internal/scanner"
	"assetscanner/internal/storage"
	"assetscanner/internal/util"
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/labstack/echo/v4"
)

// AssetsHandler handles asset-related endpoints
type AssetsHandler struct {
	storage         storage.Storage
	scanner         *scanner.LuaScanner
	recontoolPath   string
	enableSudo      bool
	enableScanning  bool
	enableStreaming bool
	jobs            map[string]*model.Job
	jobsMu          sync.RWMutex
}

// NewAssetsHandler creates a new assets handler
func NewAssetsHandler(storage storage.Storage, scanner *scanner.LuaScanner, recontoolPath string, enableSudo, enableScanning, enableStreaming bool) *AssetsHandler {
	return &AssetsHandler{
		storage:         storage,
		scanner:         scanner,
		recontoolPath:   recontoolPath,
		enableSudo:      enableSudo,
		enableScanning:  enableScanning,
		enableStreaming: enableStreaming,
		jobs:            make(map[string]*model.Job),
	}
}

// DiscoverAssets starts asset discovery for the given hosts
// @Summary Discover assets
// @Description Start asset discovery for a list of hosts using recontool
// @Tags assets
// @Accept json
// @Produce json
// @Param request body v1.DiscoverAssetsRequest true "Hosts to discover"
// @Success 202 {object} v1.DiscoverAssetsResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /assets/discover [post]
func (h *AssetsHandler) DiscoverAssets(c echo.Context) error {
	var req v1.DiscoverAssetsRequest
	if err := c.Bind(&req); err != nil {
		return errors.NewBadRequest("Invalid request body", nil)
	}

	if len(req.Hosts) == 0 {
		return errors.NewValidationError(map[string]string{
			"hosts": "At least one host is required",
		})
	}

	// Check if discovery is already running
	h.jobsMu.RLock()
	for _, job := range h.jobs {
		if job.Type == model.JobTypeDiscovery && job.Status == model.JobStatusRunning {
			h.jobsMu.RUnlock()
			return c.JSON(http.StatusConflict, map[string]interface{}{
				"error":   "Discovery job already in progress",
				"details": fmt.Sprintf("Job %s is currently running", job.ID),
			})
		}
	}
	h.jobsMu.RUnlock()

	// Create discovery job
	jobID := util.GenerateJobID("discovery")
	job := model.NewJob(model.JobTypeDiscovery)
	job.ID = jobID
	job.Status = model.JobStatusRunning
	job.Metadata = map[string]interface{}{
		"hosts":      req.Hosts,
		"host_count": len(req.Hosts),
	}

	// Store job
	h.jobsMu.Lock()
	h.jobs[jobID] = job
	h.jobsMu.Unlock()

	if err := h.storage.CreateJob(c.Request().Context(), job); err != nil {
		return errors.NewStorageError("create job", err)
	}

	// Clear existing assets before starting discovery
	fmt.Printf("[AssetsHandler] Clearing existing assets before starting discovery\n")
	if err := h.storage.ClearAllAssets(c.Request().Context()); err != nil {
		fmt.Printf("[AssetsHandler] Warning: Failed to clear existing assets: %v\n", err)
	} else {
		fmt.Printf("[AssetsHandler] Successfully cleared all existing assets\n")
	}

	// Start discovery in background
	fmt.Printf("[AssetsHandler] Starting discovery job %s for hosts: %v\n", jobID, req.Hosts)
	go h.runDiscovery(jobID, req.Hosts)

	response := v1.DiscoverAssetsResponse{
		Message:   "Asset discovery started",
		JobID:     jobID,
		HostCount: len(req.Hosts),
		StartedAt: job.StartedAt.Format(time.RFC3339),
	}

	return c.JSON(http.StatusAccepted, response)
}

// GetAssetCatalogue returns all discovered assets
// @Summary Get asset catalogue
// @Description Retrieve all discovered assets for 2D view
// @Tags assets
// @Produce json
// @Param type query string false "Filter by asset type"
// @Param status query string false "Filter by asset status"
// @Success 200 {object} v1.AssetCatalogueResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /assets/catalogue [get]
func (h *AssetsHandler) GetAssetCatalogue(c echo.Context) error {
	// Build filter from query parameters
	filter := &model.AssetFilter{}

	if assetType := c.QueryParam("type"); assetType != "" {
		filter.Types = strings.Split(assetType, ",")
	}

	if status := c.QueryParam("status"); status != "" {
		filter.Status = strings.Split(status, ",")
	}

	// Get assets from storage
	assets, err := h.storage.ListAssets(c.Request().Context(), filter)
	if err != nil {
		return errors.NewStorageError("list assets", err)
	}

	// Convert to response format
	assetSummaries := make([]v1.AssetSummary, len(assets))
	for i, asset := range assets {
		assetSummaries[i] = v1.AssetSummary{
			ID:            asset.ID,
			Type:          asset.Type,
			Value:         asset.Value,
			DiscoveredAt:  asset.DiscoveredAt,
			LastScannedAt: asset.LastScannedAt,
			ScanCount:     asset.ScanCount,
			Status:        asset.Status,
		}
	}

	response := v1.AssetCatalogueResponse{
		Assets: assetSummaries,
		Total:  len(assetSummaries),
	}

	return c.JSON(http.StatusOK, response)
}

// GetAssetDetails returns detailed information about a specific asset
// @Summary Get asset details
// @Description Get detailed information about a specific asset including scan results
// @Tags assets
// @Produce json
// @Param id path string true "Asset ID"
// @Success 200 {object} v1.AssetDetailsResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /assets/{id} [get]
func (h *AssetsHandler) GetAssetDetails(c echo.Context) error {
	assetID := c.Param("id")
	if assetID == "" {
		return errors.NewBadRequest("Asset ID is required", nil)
	}

	// Get asset from storage
	asset, err := h.storage.GetAsset(c.Request().Context(), assetID)
	if err != nil {
		return err
	}

	// Get scan results for this asset
	scanResults, err := h.storage.GetScanResultsByAsset(c.Request().Context(), assetID)
	if err != nil {
		return errors.NewStorageError("get scan results", err)
	}

	// Convert scan results to response format
	responseScanResults := make([]v1.ScanResult, len(scanResults))
	for i, result := range scanResults {
		responseScanResults[i] = v1.ScanResult{
			ID:         result.ID,
			ScriptName: result.ScriptName,
			ExecutedAt: result.ExecutedAt,
			Success:    result.Success,
			Output:     result.Output,
			Error:      result.Error,
			Duration:   result.Duration.String(),
			Metadata:   result.Metadata,
		}
	}

	response := v1.AssetDetailsResponse{
		Asset: v1.AssetDetails{
			ID:            asset.ID,
			Type:          asset.Type,
			Value:         asset.Value,
			DiscoveredAt:  asset.DiscoveredAt,
			LastScannedAt: asset.LastScannedAt,
			ScanCount:     asset.ScanCount,
			Status:        asset.Status,
			Properties:    asset.Properties,
			ScanResults:   responseScanResults,
		},
	}

	return c.JSON(http.StatusOK, response)
}

// StartAssetScan starts scanning a specific asset
// @Summary Start asset scan
// @Description Start scanning a specific asset with specified scripts
// @Tags assets
// @Accept json
// @Produce json
// @Param id path string true "Asset ID"
// @Param request body v1.StartAssetScanRequest true "Scan configuration"
// @Success 202 {object} v1.StartAssetScanResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /assets/{id}/scan [post]
func (h *AssetsHandler) StartAssetScan(c echo.Context) error {
	assetID := c.Param("id")
	if assetID == "" {
		return errors.NewBadRequest("Asset ID is required", nil)
	}

	var req v1.StartAssetScanRequest
	if err := c.Bind(&req); err != nil {
		return errors.NewBadRequest("Invalid request body", nil)
	}

	// Get asset from storage
	asset, err := h.storage.GetAsset(c.Request().Context(), assetID)
	if err != nil {
		return err
	}

	// Check if asset can be scanned
	if !asset.CanBeScanned() {
		return errors.NewConflict("Asset is currently being scanned")
	}

	// Create scan job
	jobID := util.GenerateJobID("scan_asset")
	job := model.NewJob(model.JobTypeScanAsset)
	job.ID = jobID
	job.Status = model.JobStatusRunning
	job.Metadata = map[string]interface{}{
		"asset_id": assetID,
		"scripts":  req.Scripts,
	}

	// Store job
	h.jobsMu.Lock()
	h.jobs[jobID] = job
	h.jobsMu.Unlock()

	if err := h.storage.CreateJob(c.Request().Context(), job); err != nil {
		return errors.NewStorageError("create job", err)
	}

	// Update asset status
	asset.Status = model.AssetStatusScanning
	if err := h.storage.UpdateAsset(c.Request().Context(), asset); err != nil {
		return errors.NewStorageError("update asset", err)
	}

	// Start scan in background
	go h.runAssetScan(jobID, asset, req.Scripts)

	response := v1.StartAssetScanResponse{
		Message:   "Asset scan started",
		JobID:     jobID,
		AssetID:   assetID,
		StartedAt: job.StartedAt.Format(time.RFC3339),
	}

	return c.JSON(http.StatusAccepted, response)
}

// StartAllAssetsScan starts scanning all assets
// @Summary Start scan of all assets
// @Description Start scanning all assets with specified scripts
// @Tags assets
// @Accept json
// @Produce json
// @Param request body v1.StartAllAssetsScanRequest true "Scan configuration"
// @Success 202 {object} v1.StartAllAssetsScanResponse
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /assets/scan [post]
func (h *AssetsHandler) StartAllAssetsScan(c echo.Context) error {
	var req v1.StartAllAssetsScanRequest
	if err := c.Bind(&req); err != nil {
		return errors.NewBadRequest("Invalid request body", nil)
	}

	// Build filter for asset types
	filter := &model.AssetFilter{}
	if len(req.AssetTypes) > 0 {
		filter.Types = req.AssetTypes
	}

	// Get assets to scan
	assets, err := h.storage.ListAssets(c.Request().Context(), filter)
	if err != nil {
		return errors.NewStorageError("list assets", err)
	}

	// Filter out assets that can't be scanned
	var scannableAssets []*model.Asset
	for _, asset := range assets {
		if asset.CanBeScanned() {
			scannableAssets = append(scannableAssets, asset)
		}
	}

	if len(scannableAssets) == 0 {
		return errors.NewBadRequest("No assets available for scanning", nil)
	}

	// Create scan job
	jobID := util.GenerateJobID("scan_all")
	job := model.NewJob(model.JobTypeScanAll)
	job.ID = jobID
	job.Status = model.JobStatusRunning
	job.Progress.Total = len(scannableAssets)
	job.Metadata = map[string]interface{}{
		"asset_count": len(scannableAssets),
		"scripts":     req.Scripts,
		"asset_types": req.AssetTypes,
	}

	// Store job
	h.jobsMu.Lock()
	h.jobs[jobID] = job
	h.jobsMu.Unlock()

	if err := h.storage.CreateJob(c.Request().Context(), job); err != nil {
		return errors.NewStorageError("create job", err)
	}

	// Start scan in background
	go h.runAllAssetsScan(jobID, scannableAssets, req.Scripts)

	response := v1.StartAllAssetsScanResponse{
		Message:    "All assets scan started",
		JobID:      jobID,
		AssetCount: len(scannableAssets),
		StartedAt:  job.StartedAt.Format(time.RFC3339),
	}

	return c.JSON(http.StatusAccepted, response)
}

// GetJobStatus returns the status of a job
// @Summary Get job status
// @Description Get the status and progress of a job
// @Tags jobs
// @Produce json
// @Param id path string true "Job ID"
// @Success 200 {object} v1.JobStatusResponse
// @Failure 404 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /jobs/{id} [get]
func (h *AssetsHandler) GetJobStatus(c echo.Context) error {
	jobID := c.Param("id")
	if jobID == "" {
		return errors.NewBadRequest("Job ID is required", nil)
	}

	// Get job from storage
	job, err := h.storage.GetJob(c.Request().Context(), jobID)
	if err != nil {
		return err
	}

	response := v1.JobStatusResponse{
		JobID:       job.ID,
		Status:      job.Status,
		StartedAt:   job.StartedAt,
		CompletedAt: job.CompletedAt,
		Progress: v1.JobProgress{
			Total:     job.Progress.Total,
			Completed: job.Progress.Completed,
			Failed:    job.Progress.Failed,
		},
		Error: job.Error,
	}

	return c.JSON(http.StatusOK, response)
}

// Background job execution methods

func (h *AssetsHandler) runDiscovery(jobID string, hosts []string) {
	ctx := context.Background()
	fmt.Printf("[AssetsHandler] Starting discovery job %s for hosts: %v\n", jobID, hosts)

	// Get job
	job, err := h.storage.GetJob(ctx, jobID)
	if err != nil {
		fmt.Printf("[AssetsHandler] Failed to get job %s: %v\n", jobID, err)
		return
	}

	// Run recontool for each host
	var allAssets []*model.Asset
	for i, host := range hosts {
		fmt.Printf("[AssetsHandler] Processing host %d/%d: %s\n", i+1, len(hosts), host)
		assets, err := h.runRecontoolDiscoveryWithJob(ctx, host, jobID)
		if err != nil {
			fmt.Printf("[AssetsHandler] Discovery failed for host %s: %v\n", host, err)
			job.Error = fmt.Sprintf("Discovery failed for %s: %v", host, err)
			continue
		}
		fmt.Printf("[AssetsHandler] Found %d assets for host %s\n", len(assets), host)
		allAssets = append(allAssets, assets...)
	}

	// Assets were already saved during streaming, just log the summary
	fmt.Printf("[AssetsHandler] Discovery completed with %d assets (already saved during streaming)\n", len(allAssets))

	// Update job status to completed
	fmt.Printf("[AssetsHandler] Discovery job %s completed with %d assets\n", jobID, len(allAssets))

	// Get the latest job state from storage to ensure we have the most recent data
	if latestJob, err := h.storage.GetJob(ctx, jobID); err == nil {
		job = latestJob
	}

	job.Status = model.JobStatusCompleted
	now := time.Now()
	job.CompletedAt = &now
	job.Metadata["assets_found"] = len(allAssets)
	job.Metadata["final_status"] = "completed"

	// Save to storage
	if err := h.storage.UpdateJob(ctx, job); err != nil {
		fmt.Printf("[AssetsHandler] Failed to update job completion status: %v\n", err)
	} else {
		fmt.Printf("[AssetsHandler] Successfully marked job %s as completed\n", jobID)
	}

	// Update local job cache
	h.jobsMu.Lock()
	h.jobs[jobID] = job
	h.jobsMu.Unlock()
}

func (h *AssetsHandler) runRecontoolDiscoveryWithJob(ctx context.Context, host string, jobID string) ([]*model.Asset, error) {
	// Build recontool command
	args := []string{}
	if h.enableSudo {
		args = append(args, "sudo")
	}

	args = append(args, h.recontoolPath)

	if h.enableStreaming {
		args = append(args, "--stream")
	}
	if h.enableScanning {
		args = append(args, "--scan")
	}

	args = append(args, host)

	fmt.Printf("[AssetsHandler] Executing recontool command: %s\n", strings.Join(args, " "))

	// Create context with timeout
	ctxWithTimeout, cancel := context.WithTimeout(ctx, 5*time.Minute)
	defer cancel()

	// Execute recontool
	cmd := exec.CommandContext(ctxWithTimeout, args[0], args[1:]...)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Printf("[AssetsHandler] Failed to create stdout pipe: %v\n", err)
		return nil, fmt.Errorf("failed to create stdout pipe: %w", err)
	}

	// Also capture stderr for debugging
	stderr, err := cmd.StderrPipe()
	if err != nil {
		fmt.Printf("[AssetsHandler] Failed to create stderr pipe: %v\n", err)
		return nil, fmt.Errorf("failed to create stderr pipe: %w", err)
	}

	if err := cmd.Start(); err != nil {
		fmt.Printf("[AssetsHandler] Failed to start recontool: %v\n", err)
		return nil, fmt.Errorf("failed to start recontool: %w", err)
	}

	fmt.Printf("[AssetsHandler] recontool started successfully, reading output...\n")

	// Read stderr in background for debugging
	go func() {
		stderrScanner := bufio.NewScanner(stderr)
		for stderrScanner.Scan() {
			fmt.Printf("[AssetsHandler] recontool stderr: %s\n", stderrScanner.Text())
		}
	}()

	// Parse streaming output
	var assets []*model.Asset
	scanner := bufio.NewScanner(stdout)
	lineCount := 0

	// Set a reasonable buffer size for large JSON lines
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		lineCount++
		fmt.Printf("[AssetsHandler] Line %d: %s\n", lineCount, line)

		if line == "" {
			continue
		}

		// Skip non-JSON lines (verbose output)
		if !strings.HasPrefix(line, "{") {
			fmt.Printf("[AssetsHandler] Skipping non-JSON line: %s\n", line)
			continue
		}

		// Parse JSON asset - try the actual recontool Asset structure
		var recontoolAsset model.Asset
		var asset *model.Asset

		if err := json.Unmarshal([]byte(line), &recontoolAsset); err != nil {
			fmt.Printf("[AssetsHandler] Failed to parse as Asset JSON: %v\n", err)

			// Try a simpler structure
			var simpleAsset struct {
				ID    string `json:"id"`
				Type  string `json:"type"`
				Value string `json:"value"`
			}

			if err2 := json.Unmarshal([]byte(line), &simpleAsset); err2 != nil {
				fmt.Printf("[AssetsHandler] Failed to parse as simple JSON: %v\n", err2)
				continue // Skip invalid JSON
			}

			// Create asset from simple structure
			asset = model.NewAsset(simpleAsset.Type, simpleAsset.Value)
			if simpleAsset.ID != "" {
				asset.ID = simpleAsset.ID
			}
		} else {
			// Successfully parsed as full Asset
			fmt.Printf("[AssetsHandler] Parsed asset: %s (type: %s)\n", recontoolAsset.Value, recontoolAsset.Type)

			// Ensure the asset has an ID
			if recontoolAsset.ID == "" {
				recontoolAsset.ID = util.GenerateID()
			}

			asset = &recontoolAsset
		}

		// Immediately save asset to storage (streaming persistence)
		if err := h.storage.CreateAsset(ctx, asset); err != nil {
			fmt.Printf("[AssetsHandler] Failed to save asset %s during streaming: %v\n", asset.Value, err)
			// Try to update if it already exists
			if existingAsset, getErr := h.storage.GetAsset(ctx, asset.ID); getErr == nil {
				existingAsset.DiscoveredAt = asset.DiscoveredAt
				if updateErr := h.storage.UpdateAsset(ctx, existingAsset); updateErr != nil {
					fmt.Printf("[AssetsHandler] Failed to update existing asset %s: %v\n", asset.Value, updateErr)
				} else {
					fmt.Printf("[AssetsHandler] Updated existing asset %s\n", asset.Value)
				}
			}
		} else {
			fmt.Printf("[AssetsHandler] Successfully saved asset %s to storage\n", asset.Value)
		}

		assets = append(assets, asset)

		// Update job progress in real-time
		if currentJob, jobErr := h.storage.GetJob(ctx, jobID); jobErr == nil {
			currentJob.Progress.Completed = len(assets)
			currentJob.Metadata["assets_found_so_far"] = len(assets)
			currentJob.Metadata["current_host"] = host
			h.storage.UpdateJob(ctx, currentJob)
			fmt.Printf("[AssetsHandler] Updated job %s progress: %d assets found\n", jobID, len(assets))
		}
	}

	fmt.Printf("[AssetsHandler] Processed %d lines from recontool output\n", lineCount)

	if err := cmd.Wait(); err != nil {
		fmt.Printf("[AssetsHandler] recontool command failed: %v\n", err)

		// Update job status to failed if recontool fails
		if currentJob, jobErr := h.storage.GetJob(ctx, jobID); jobErr == nil {
			currentJob.Status = model.JobStatusFailed
			currentJob.Error = fmt.Sprintf("recontool execution failed: %v", err)
			now := time.Now()
			currentJob.CompletedAt = &now
			h.storage.UpdateJob(ctx, currentJob)
			fmt.Printf("[AssetsHandler] Updated job %s status to failed\n", jobID)
		}

		return assets, fmt.Errorf("recontool execution failed: %w", err)
	}

	fmt.Printf("[AssetsHandler] recontool completed successfully, found %d assets\n", len(assets))

	// Final job progress update for this host
	if currentJob, jobErr := h.storage.GetJob(ctx, jobID); jobErr == nil {
		currentJob.Progress.Completed = len(assets)
		currentJob.Metadata["final_asset_count_for_host"] = len(assets)
		currentJob.Metadata["host_completed"] = host
		h.storage.UpdateJob(ctx, currentJob)
		fmt.Printf("[AssetsHandler] Final progress update for job %s: %d assets from host %s\n", jobID, len(assets), host)
	}

	return assets, nil
}

func (h *AssetsHandler) runAssetScan(jobID string, asset *model.Asset, scriptNames []string) {
	ctx := context.Background()

	// Run scan
	results, err := h.scanner.ScanAsset(ctx, asset, scriptNames)
	if err != nil {
		// Update job with error
		job, _ := h.storage.GetJob(ctx, jobID)
		job.Status = model.JobStatusFailed
		job.Error = err.Error()
		now := time.Now()
		job.CompletedAt = &now
		h.storage.UpdateJob(ctx, job)

		// Update asset status
		asset.Status = model.AssetStatusError
		h.storage.UpdateAsset(ctx, asset)
		return
	}

	// Store scan results
	for _, result := range results {
		h.storage.CreateScanResult(ctx, result)
	}

	// Update asset
	asset.Status = model.AssetStatusScanned
	asset.ScanCount++
	now := time.Now()
	asset.LastScannedAt = &now
	for _, result := range results {
		asset.ScanResults = append(asset.ScanResults, *result)
	}
	h.storage.UpdateAsset(ctx, asset)

	// Update job
	job, _ := h.storage.GetJob(ctx, jobID)
	job.Status = model.JobStatusCompleted
	job.CompletedAt = &now
	job.Progress.Total = 1
	job.Progress.Completed = 1
	h.storage.UpdateJob(ctx, job)
}

func (h *AssetsHandler) runAllAssetsScan(jobID string, assets []*model.Asset, scriptNames []string) {
	ctx := context.Background()

	job, _ := h.storage.GetJob(ctx, jobID)

	// Scan assets concurrently
	var wg sync.WaitGroup
	semaphore := make(chan struct{}, 5) // Limit concurrent scans

	for _, asset := range assets {
		wg.Add(1)
		go func(asset *model.Asset) {
			defer wg.Done()

			// Acquire semaphore
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			// Update asset status
			asset.Status = model.AssetStatusScanning
			h.storage.UpdateAsset(ctx, asset)

			// Run scan
			results, err := h.scanner.ScanAsset(ctx, asset, scriptNames)

			// Update progress
			h.jobsMu.Lock()
			if err != nil {
				job.Progress.Failed++
			} else {
				job.Progress.Completed++

				// Store results
				for _, result := range results {
					h.storage.CreateScanResult(ctx, result)
				}

				// Update asset
				asset.Status = model.AssetStatusScanned
				asset.ScanCount++
				now := time.Now()
				asset.LastScannedAt = &now
				for _, result := range results {
					asset.ScanResults = append(asset.ScanResults, *result)
				}
			}

			h.storage.UpdateAsset(ctx, asset)
			h.storage.UpdateJob(ctx, job)
			h.jobsMu.Unlock()
		}(asset)
	}

	wg.Wait()

	// Complete job
	job.Status = model.JobStatusCompleted
	now := time.Now()
	job.CompletedAt = &now
	h.storage.UpdateJob(ctx, job)
}
