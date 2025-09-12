package v1

import (
	"time"
)

// Generic responses
type GenericStatusResponse struct {
	Message string `json:"message" binding:"required"`
}

type GenericStatusResponseWithID struct {
	Message string `json:"message" binding:"required"`
	ID      string `json:"id" binding:"required"`
}

// Asset Discovery
type DiscoverAssetsRequest struct {
	Hosts []string `json:"hosts" binding:"required" example:"example.com,192.168.1.1"`
}

type DiscoverAssetsResponse struct {
	Message   string `json:"message" binding:"required"`
	JobID     string `json:"job_id" binding:"required"`
	HostCount int    `json:"host_count" binding:"required"`
	StartedAt string `json:"started_at" binding:"required"`
}

// Asset Catalogue
type AssetCatalogueResponse struct {
	Assets []AssetSummary `json:"assets" binding:"required"`
	Total  int            `json:"total" binding:"required"`
}

type AssetSummary struct {
	ID            string     `json:"id" binding:"required"`
	Type          string     `json:"type" binding:"required" example:"domain,subdomain,ip,service"`
	Value         string     `json:"value" binding:"required"`
	DiscoveredAt  time.Time  `json:"discovered_at" binding:"required"`
	LastScannedAt *time.Time `json:"last_scanned_at,omitempty"`
	ScanCount     int        `json:"scan_count" binding:"required"`
	Status        string     `json:"status" binding:"required" example:"discovered,scanning,scanned,error"`
}

// Asset Details
type AssetDetailsResponse struct {
	Asset AssetDetails `json:"asset" binding:"required"`
}

type AssetDetails struct {
	ID            string                 `json:"id" binding:"required"`
	Type          string                 `json:"type" binding:"required"`
	Value         string                 `json:"value" binding:"required"`
	DiscoveredAt  time.Time              `json:"discovered_at" binding:"required"`
	LastScannedAt *time.Time             `json:"last_scanned_at,omitempty"`
	ScanCount     int                    `json:"scan_count" binding:"required"`
	Status        string                 `json:"status" binding:"required"`
	Properties    map[string]interface{} `json:"properties,omitempty"`
	ScanResults   []ScanResult           `json:"scan_results,omitempty"`
}

type ScanResult struct {
	ID         string                 `json:"id" binding:"required"`
	ScriptName string                 `json:"script_name" binding:"required"`
	ExecutedAt time.Time              `json:"executed_at" binding:"required"`
	Success    bool                   `json:"success" binding:"required"`
	Output     []string               `json:"output,omitempty"`
	Error      string                 `json:"error,omitempty"`
	Duration   string                 `json:"duration" binding:"required"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// Asset Scanning
type StartAssetScanRequest struct {
	Scripts []string `json:"scripts,omitempty" example:"vulnerability_scan.lua,port_scan.lua"`
}

type StartAssetScanResponse struct {
	Message   string `json:"message" binding:"required"`
	JobID     string `json:"job_id" binding:"required"`
	AssetID   string `json:"asset_id" binding:"required"`
	StartedAt string `json:"started_at" binding:"required"`
}

type StartAllAssetsScanRequest struct {
	Scripts    []string `json:"scripts,omitempty"`
	AssetTypes []string `json:"asset_types,omitempty" example:"domain,ip,service"`
}

type StartAllAssetsScanResponse struct {
	Message    string `json:"message" binding:"required"`
	JobID      string `json:"job_id" binding:"required"`
	AssetCount int    `json:"asset_count" binding:"required"`
	StartedAt  string `json:"started_at" binding:"required"`
}

// Job Status
type JobStatusResponse struct {
	JobID       string      `json:"job_id" binding:"required"`
	Status      string      `json:"status" binding:"required" example:"pending,running,completed,failed"`
	StartedAt   time.Time   `json:"started_at" binding:"required"`
	CompletedAt *time.Time  `json:"completed_at,omitempty"`
	Progress    JobProgress `json:"progress" binding:"required"`
	Error       string      `json:"error,omitempty"`
}

type JobProgress struct {
	Total     int `json:"total" binding:"required"`
	Completed int `json:"completed" binding:"required"`
	Failed    int `json:"failed" binding:"required"`
}

// Script Management
type ScriptListResponse struct {
	Scripts []ScriptInfo `json:"scripts" binding:"required"`
	Total   int          `json:"total" binding:"required"`
}

type ScriptInfo struct {
	Name        string   `json:"name" binding:"required"`
	Description string   `json:"description,omitempty"`
	Category    string   `json:"category,omitempty"`
	Author      string   `json:"author,omitempty"`
	Version     string   `json:"version,omitempty"`
	AssetTypes  []string `json:"asset_types,omitempty"`
}

// Health Check
type HealthResponse struct {
	Status    string            `json:"status" binding:"required" example:"healthy,unhealthy"`
	Timestamp time.Time         `json:"timestamp" binding:"required"`
	Services  map[string]string `json:"services" binding:"required"`
	Version   string            `json:"version,omitempty"`
}

// Error Response
type ErrorResponse struct {
	Error   string            `json:"error" binding:"required"`
	Code    int               `json:"code" binding:"required"`
	Details map[string]string `json:"details,omitempty"`
}

// Utility functions
func NewGenericStatusResponse(message string) GenericStatusResponse {
	return GenericStatusResponse{Message: message}
}

func NewGenericStatusResponseWithID(id, message string) GenericStatusResponseWithID {
	return GenericStatusResponseWithID{ID: id, Message: message}
}

func NewErrorResponse(code int, message string, details map[string]string) ErrorResponse {
	return ErrorResponse{
		Error:   message,
		Code:    code,
		Details: details,
	}
}
