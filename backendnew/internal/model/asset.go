package model

import (
	"assetscanner/internal/util"
	"time"
)

// DNSRecords holds various DNS record types
type DNSRecords struct {
	A     []string `json:"a,omitempty"`     // A records (IPv4)
	AAAA  []string `json:"aaaa,omitempty"`  // AAAA records (IPv6)
	CNAME []string `json:"cname,omitempty"` // CNAME records
	MX    []string `json:"mx,omitempty"`    // MX records (mail exchange)
	TXT   []string `json:"txt,omitempty"`   // TXT records
	NS    []string `json:"ns,omitempty"`    // NS records (name servers)
	SOA   []string `json:"soa,omitempty"`   // SOA records (start of authority)
	PTR   []string `json:"ptr,omitempty"`   // PTR records (reverse DNS)
}

// Asset represents a discovered network asset
type Asset struct {
	ID            string                 `json:"id"`
	Type          string                 `json:"type"` // domain, subdomain, ip, service
	Value         string                 `json:"value"`
	DiscoveredAt  time.Time              `json:"discovered_at"`
	LastScannedAt *time.Time             `json:"last_scanned_at,omitempty"`
	ScanCount     int                    `json:"scan_count"`
	Status        string                 `json:"status"` // discovered, scanning, scanned, error
	Properties    map[string]interface{} `json:"properties,omitempty"`
	ScanResults   []ScanResult           `json:"scan_results,omitempty"`
	DNSRecords    *DNSRecords            `json:"dns_records,omitempty"` // DNS records for domains/subdomains
	Tags          []string               `json:"tags,omitempty"`        // Tags like "http", "cf-proxied", etc.
}

// ScanResult represents the result of running a Lua script on an asset
type ScanResult struct {
	ID         string                 `json:"id"`
	AssetID    string                 `json:"asset_id"`
	ScriptName string                 `json:"script_name"`
	ExecutedAt time.Time              `json:"executed_at"`
	Success    bool                   `json:"success"`
	Decision   string                 `json:"decision,omitempty"`
	Output     []string               `json:"output"`
	Error      string                 `json:"error,omitempty"`
	Duration   time.Duration          `json:"duration"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// Job represents a background task (discovery or scanning)
type Job struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`   // discovery, scan_asset, scan_all
	Status      string                 `json:"status"` // pending, running, completed, failed
	StartedAt   time.Time              `json:"started_at"`
	CompletedAt *time.Time             `json:"completed_at,omitempty"`
	Progress    JobProgress            `json:"progress"`
	Error       string                 `json:"error,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// JobProgress tracks the progress of a job
type JobProgress struct {
	Total     int `json:"total"`
	Completed int `json:"completed"`
	Failed    int `json:"failed"`
}

// DiscoveryJob represents an asset discovery job
type DiscoveryJob struct {
	Job
	Hosts       []string `json:"hosts"`
	AssetsFound int      `json:"assets_found"`
}

// ScanJob represents a scanning job
type ScanJob struct {
	Job
	AssetIDs    []string `json:"asset_ids"`
	Scripts     []string `json:"scripts"`
	ResultCount int      `json:"result_count"`
}

// Script represents a Lua scanning script
type Script struct {
	Name           string   `json:"name"`
	Path           string   `json:"path"`
	Title          string   `json:"title,omitempty"`
	Description    string   `json:"description,omitempty"`
	Category       string   `json:"category,omitempty"`
	Author         string   `json:"author,omitempty"`
	Version        string   `json:"version,omitempty"`
	AssetTypes     []string `json:"asset_types,omitempty"` // Which asset types this script can process
	RequiresPassed []string `json:"requires_passed,omitempty"`
	Content        string   `json:"content"`
}

// AssetFilter represents filtering criteria for assets
type AssetFilter struct {
	Types      []string   `json:"types,omitempty"`
	Status     []string   `json:"status,omitempty"`
	DateFrom   *time.Time `json:"date_from,omitempty"`
	DateTo     *time.Time `json:"date_to,omitempty"`
	HasResults *bool      `json:"has_results,omitempty"`
}

// Constants for asset types
const (
	AssetTypeDomain    = "domain"
	AssetTypeSubdomain = "subdomain"
	AssetTypeIP        = "ip"
	AssetTypeService   = "service"
)

// Constants for asset status
const (
	AssetStatusDiscovered = "discovered"
	AssetStatusScanning   = "scanning"
	AssetStatusScanned    = "scanned"
	AssetStatusError      = "error"
)

// Constants for job types
const (
	JobTypeDiscovery = "discovery"
	JobTypeScanAsset = "scan_asset"
	JobTypeScanAll   = "scan_all"
)

// Constants for job status
const (
	JobStatusPending   = "pending"
	JobStatusRunning   = "running"
	JobStatusCompleted = "completed"
	JobStatusFailed    = "failed"
)

// Helper methods
func (a *Asset) IsScanned() bool {
	return a.Status == AssetStatusScanned
}

func (a *Asset) CanBeScanned() bool {
	return a.Status != AssetStatusScanning
}

func (j *Job) IsCompleted() bool {
	return j.Status == JobStatusCompleted || j.Status == JobStatusFailed
}

func (j *Job) IsRunning() bool {
	return j.Status == JobStatusRunning
}

func (jp *JobProgress) GetPercentage() float64 {
	if jp.Total == 0 {
		return 0.0
	}
	return float64(jp.Completed+jp.Failed) / float64(jp.Total) * 100.0
}

// NewAsset creates a new asset with default values
func NewAsset(assetType, value string) *Asset {
	return &Asset{
		ID:           util.GenerateAssetID(assetType, value),
		Type:         assetType,
		Value:        value,
		DiscoveredAt: time.Now(),
		Status:       AssetStatusDiscovered,
		ScanCount:    0,
		Properties:   make(map[string]interface{}),
		ScanResults:  make([]ScanResult, 0),
		Tags:         make([]string, 0),
	}
}

// NewJob creates a new job with default values
func NewJob(jobType string) *Job {
	return &Job{
		Type:      jobType,
		Status:    JobStatusPending,
		StartedAt: time.Now(),
		Progress:  JobProgress{},
		Metadata:  make(map[string]interface{}),
	}
}
