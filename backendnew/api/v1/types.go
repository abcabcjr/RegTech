package v1

import (
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
	DNSRecords    *DNSRecords            `json:"dns_records,omitempty"` // DNS records for domains/subdomains
	Tags          []string               `json:"tags,omitempty"`        // Tags like "http", "cf-proxied", etc.
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

// Incident Management

// CreateIncidentRequest represents a request to create an incident
type CreateIncidentRequest struct {
	InitialDetails     InitialDetails `json:"initialDetails" binding:"required"`
	Significant        bool           `json:"significant"`
	Recurring          bool           `json:"recurring"`
	CauseTag           string         `json:"causeTag" binding:"required" example:"phishing,vuln_exploit,misconfig,malware,other"`
	UsersAffected      *int           `json:"usersAffected,omitempty" example:"100"`
	DowntimeMinutes    *int           `json:"downtimeMinutes,omitempty" example:"30"`
	FinancialImpactPct *float64       `json:"financialImpactPct,omitempty" example:"2.5"`
	SectorPreset       *string        `json:"sectorPreset,omitempty" example:"financial"`
	Attachments        []Attachment   `json:"attachments,omitempty"`
}

// UpdateIncidentRequest represents a request to update an incident
type UpdateIncidentRequest struct {
	Stage              string          `json:"stage" binding:"required" example:"initial,update,final"`
	Significant        bool            `json:"significant"`
	Recurring          bool            `json:"recurring"`
	CauseTag           string          `json:"causeTag" binding:"required" example:"phishing,vuln_exploit,misconfig,malware,other"`
	UsersAffected      *int            `json:"usersAffected,omitempty" example:"100"`
	DowntimeMinutes    *int            `json:"downtimeMinutes,omitempty" example:"30"`
	FinancialImpactPct *float64        `json:"financialImpactPct,omitempty" example:"2.5"`
	SectorPreset       *string         `json:"sectorPreset,omitempty" example:"financial"`
	InitialDetails     *InitialDetails `json:"initialDetails,omitempty"`
	UpdateDetails      *UpdateDetails  `json:"updateDetails,omitempty"`
	FinalDetails       *FinalDetails   `json:"finalDetails,omitempty"`
	Attachments        *[]Attachment   `json:"attachments,omitempty"`
}

// InitialDetails contains the initial incident report details
type InitialDetails struct {
	Title               string `json:"title" binding:"required" example:"Security Incident - Phishing Attack"`
	Summary             string `json:"summary" binding:"required" example:"Multiple users reported suspicious emails"`
	DetectedAt          string `json:"detectedAt" binding:"required" example:"2024-01-15T10:30:00Z"`
	SuspectedIllegal    *bool  `json:"suspectedIllegal,omitempty"`
	PossibleCrossBorder *bool  `json:"possibleCrossBorder,omitempty"`
}

// UpdateDetails contains the update report details
type UpdateDetails struct {
	Gravity     *string  `json:"gravity,omitempty" example:"high"`
	Impact      *string  `json:"impact,omitempty" example:"Email system compromised"`
	IOCs        []string `json:"iocs,omitempty" example:"malicious-domain.com,suspicious-ip-address"`
	Corrections *string  `json:"corrections,omitempty" example:"Blocked malicious domains"`
}

// FinalDetails contains the final report details
type FinalDetails struct {
	RootCause       *string `json:"rootCause,omitempty" example:"Lack of email security awareness"`
	Gravity         *string `json:"gravity,omitempty" example:"high"`
	Impact          *string `json:"impact,omitempty" example:"No data exfiltration occurred"`
	Mitigations     *string `json:"mitigations,omitempty" example:"Enhanced email filtering implemented"`
	CrossBorderDesc *string `json:"crossBorderDesc,omitempty" example:"No cross-border effects identified"`
	Lessons         *string `json:"lessons,omitempty" example:"Need for regular security training"`
}

// Attachment represents a file attachment
type Attachment struct {
	Name string  `json:"name" binding:"required" example:"evidence.pdf"`
	Note *string `json:"note,omitempty" example:"Email headers and logs"`
}

// IncidentResponse represents a complete incident record
type IncidentResponse struct {
	ID                 string          `json:"id" binding:"required"`
	CreatedAt          string          `json:"createdAt" binding:"required"`
	UpdatedAt          string          `json:"updatedAt" binding:"required"`
	Stage              string          `json:"stage" binding:"required" example:"initial,update,final"`
	Significant        bool            `json:"significant"`
	Recurring          bool            `json:"recurring"`
	CauseTag           string          `json:"causeTag" binding:"required"`
	UsersAffected      *int            `json:"usersAffected,omitempty"`
	DowntimeMinutes    *int            `json:"downtimeMinutes,omitempty"`
	FinancialImpactPct *float64        `json:"financialImpactPct,omitempty"`
	SectorPreset       *string         `json:"sectorPreset,omitempty"`
	Details            IncidentDetails `json:"details" binding:"required"`
	Attachments        []Attachment    `json:"attachments,omitempty"`
}

// IncidentDetails holds all stage-specific details
type IncidentDetails struct {
	Initial *InitialDetails `json:"initial,omitempty"`
	Update  *UpdateDetails  `json:"update,omitempty"`
	Final   *FinalDetails   `json:"final,omitempty"`
}

// IncidentSummaryResponse represents a summary view of an incident
type IncidentSummaryResponse struct {
	ID          string `json:"id" binding:"required"`
	Title       string `json:"title" binding:"required"`
	Summary     string `json:"summary" binding:"required"`
	Stage       string `json:"stage" binding:"required"`
	Significant bool   `json:"significant"`
	Recurring   bool   `json:"recurring"`
	CauseTag    string `json:"causeTag" binding:"required"`
	CreatedAt   string `json:"createdAt" binding:"required"`
	UpdatedAt   string `json:"updatedAt" binding:"required"`
}

// ListIncidentsResponse represents the response for listing incidents
type ListIncidentsResponse struct {
	Incidents []IncidentResponse `json:"incidents" binding:"required"`
	Total     int                `json:"total" binding:"required"`
}

// ListIncidentSummariesResponse represents the response for listing incident summaries
type ListIncidentSummariesResponse struct {
	Summaries []IncidentSummaryResponse `json:"summaries" binding:"required"`
	Total     int                       `json:"total" binding:"required"`
}

// IncidentStatsResponse represents statistics about incidents
type IncidentStatsResponse struct {
	TotalIncidents       int            `json:"totalIncidents" binding:"required"`
	SignificantIncidents int            `json:"significantIncidents" binding:"required"`
	RecurringIncidents   int            `json:"recurringIncidents" binding:"required"`
	ByStage              map[string]int `json:"byStage" binding:"required"`
	ByCause              map[string]int `json:"byCause" binding:"required"`
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
