package model

import (
	"time"
)

// IncidentStage represents the stage of an incident report
type IncidentStage string

const (
	IncidentStageInitial IncidentStage = "initial"
	IncidentStageUpdate  IncidentStage = "update"
	IncidentStageFinal   IncidentStage = "final"
)

// CauseTag represents the cause category of an incident
type CauseTag string

const (
	CauseTagPhishing    CauseTag = "phishing"
	CauseTagVulnExploit CauseTag = "vuln_exploit"
	CauseTagMisconfig   CauseTag = "misconfig"
	CauseTagMalware     CauseTag = "malware"
	CauseTagOther       CauseTag = "other"
)

// GravityLevel represents the severity level of an incident
type GravityLevel string

const (
	GravityLow      GravityLevel = "low"
	GravityMedium   GravityLevel = "medium"
	GravityHigh     GravityLevel = "high"
	GravityCritical GravityLevel = "critical"
)

// InitialDetails contains the initial incident report details
type InitialDetails struct {
	Title               string `json:"title"`
	Summary             string `json:"summary"`
	DetectedAt          string `json:"detectedAt"`
	SuspectedIllegal    *bool  `json:"suspectedIllegal,omitempty"`
	PossibleCrossBorder *bool  `json:"possibleCrossBorder,omitempty"`
}

// UpdateDetails contains the update report details
type UpdateDetails struct {
	Gravity     *string  `json:"gravity,omitempty"`
	Impact      *string  `json:"impact,omitempty"`
	IOCs        []string `json:"iocs,omitempty"`
	Corrections *string  `json:"corrections,omitempty"`
}

// FinalDetails contains the final report details
type FinalDetails struct {
	RootCause       *string `json:"rootCause,omitempty"`
	Gravity         *string `json:"gravity,omitempty"`
	Impact          *string `json:"impact,omitempty"`
	Mitigations     *string `json:"mitigations,omitempty"`
	CrossBorderDesc *string `json:"crossBorderDesc,omitempty"`
	Lessons         *string `json:"lessons,omitempty"`
}

// Attachment represents a file attachment
type Attachment struct {
	Name string  `json:"name"`
	Note *string `json:"note,omitempty"`
}

// IncidentDetails holds all stage-specific details
type IncidentDetails struct {
	Initial *InitialDetails `json:"initial,omitempty"`
	Update  *UpdateDetails  `json:"update,omitempty"`
	Final   *FinalDetails   `json:"final,omitempty"`
}

// IncidentRecord represents a complete incident record
type IncidentRecord struct {
	ID                 string          `json:"id"`
	CreatedAt          time.Time       `json:"createdAt"`
	UpdatedAt          time.Time       `json:"updatedAt"`
	Stage              IncidentStage   `json:"stage"`
	Significant        bool            `json:"significant"`
	Recurring          bool            `json:"recurring"`
	CauseTag           CauseTag        `json:"causeTag"`
	UsersAffected      *int            `json:"usersAffected,omitempty"`
	DowntimeMinutes    *int            `json:"downtimeMinutes,omitempty"`
	FinancialImpactPct *float64        `json:"financialImpactPct,omitempty"`
	SectorPreset       *string         `json:"sectorPreset,omitempty"`
	Details            IncidentDetails `json:"details"`
	Attachments        []Attachment    `json:"attachments,omitempty"`
}

// IncidentSummary represents a summary view of an incident
type IncidentSummary struct {
	ID          string        `json:"id"`
	Title       string        `json:"title"`
	Summary     string        `json:"summary"`
	Stage       IncidentStage `json:"stage"`
	Significant bool          `json:"significant"`
	Recurring   bool          `json:"recurring"`
	CauseTag    CauseTag      `json:"causeTag"`
	CreatedAt   time.Time     `json:"createdAt"`
	UpdatedAt   time.Time     `json:"updatedAt"`
}

// ToSummary converts an IncidentRecord to an IncidentSummary
func (i *IncidentRecord) ToSummary() *IncidentSummary {
	var title, summary string

	if i.Details.Initial != nil {
		title = i.Details.Initial.Title
		summary = i.Details.Initial.Summary
	}

	return &IncidentSummary{
		ID:          i.ID,
		Title:       title,
		Summary:     summary,
		Stage:       i.Stage,
		Significant: i.Significant,
		Recurring:   i.Recurring,
		CauseTag:    i.CauseTag,
		CreatedAt:   i.CreatedAt,
		UpdatedAt:   i.UpdatedAt,
	}
}

// ValidateStage checks if the stage transition is valid
func (i *IncidentRecord) ValidateStage(newStage IncidentStage) bool {
	switch i.Stage {
	case IncidentStageInitial:
		return newStage == IncidentStageUpdate || newStage == IncidentStageInitial
	case IncidentStageUpdate:
		return newStage == IncidentStageFinal || newStage == IncidentStageUpdate
	case IncidentStageFinal:
		return newStage == IncidentStageFinal // Can only stay final or edit final
	default:
		return false
	}
}

// GetTitle returns the incident title, with fallback
func (i *IncidentRecord) GetTitle() string {
	if i.Details.Initial != nil && i.Details.Initial.Title != "" {
		return i.Details.Initial.Title
	}
	return "Untitled Incident"
}

// GetSummary returns the incident summary, with fallback
func (i *IncidentRecord) GetSummary() string {
	if i.Details.Initial != nil && i.Details.Initial.Summary != "" {
		return i.Details.Initial.Summary
	}
	return "No summary available"
}
