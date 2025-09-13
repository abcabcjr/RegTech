package service

import (
	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"assetscanner/internal/util"
	"context"
	"fmt"
	"sort"
	"time"
)

// IncidentService handles incident business logic
type IncidentService struct {
	storage storage.Storage
}

// NewIncidentService creates a new incident service
func NewIncidentService(storage storage.Storage) *IncidentService {
	return &IncidentService{
		storage: storage,
	}
}

// CreateIncident creates a new incident record
func (s *IncidentService) CreateIncident(ctx context.Context, req *CreateIncidentRequest) (*model.IncidentRecord, error) {
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("invalid request: %w", err)
	}

	now := time.Now()
	incident := &model.IncidentRecord{
		ID:                 util.GenerateID(),
		CreatedAt:          now,
		UpdatedAt:          now,
		Stage:              model.IncidentStageInitial,
		Significant:        req.Significant,
		Recurring:          req.Recurring,
		CauseTag:           req.CauseTag,
		UsersAffected:      req.UsersAffected,
		DowntimeMinutes:    req.DowntimeMinutes,
		FinancialImpactPct: req.FinancialImpactPct,
		SectorPreset:       req.SectorPreset,
		Details: model.IncidentDetails{
			Initial: &req.InitialDetails,
		},
		Attachments: req.Attachments,
	}

	if err := s.storage.CreateIncident(ctx, incident); err != nil {
		return nil, fmt.Errorf("failed to create incident: %w", err)
	}

	return incident, nil
}

// GetIncident retrieves an incident by ID
func (s *IncidentService) GetIncident(ctx context.Context, id string) (*model.IncidentRecord, error) {
	if id == "" {
		return nil, fmt.Errorf("incident ID is required")
	}

	incident, err := s.storage.GetIncident(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get incident: %w", err)
	}

	return incident, nil
}

// UpdateIncident updates an existing incident
func (s *IncidentService) UpdateIncident(ctx context.Context, id string, req *UpdateIncidentRequest) (*model.IncidentRecord, error) {
	if id == "" {
		return nil, fmt.Errorf("incident ID is required")
	}

	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("invalid request: %w", err)
	}

	// Get existing incident
	incident, err := s.storage.GetIncident(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get incident: %w", err)
	}

	// Validate stage transition
	if !incident.ValidateStage(req.Stage) {
		return nil, fmt.Errorf("invalid stage transition from %s to %s", incident.Stage, req.Stage)
	}

	// Update incident fields
	incident.UpdatedAt = time.Now()
	incident.Stage = req.Stage
	incident.Significant = req.Significant
	incident.Recurring = req.Recurring
	incident.CauseTag = req.CauseTag

	if req.UsersAffected != nil {
		incident.UsersAffected = req.UsersAffected
	}
	if req.DowntimeMinutes != nil {
		incident.DowntimeMinutes = req.DowntimeMinutes
	}
	if req.FinancialImpactPct != nil {
		incident.FinancialImpactPct = req.FinancialImpactPct
	}
	if req.SectorPreset != nil {
		incident.SectorPreset = req.SectorPreset
	}

	// Update stage-specific details
	if req.InitialDetails != nil {
		incident.Details.Initial = req.InitialDetails
	}
	if req.UpdateDetails != nil {
		incident.Details.Update = req.UpdateDetails
	}
	if req.FinalDetails != nil {
		incident.Details.Final = req.FinalDetails
	}

	if req.Attachments != nil {
		incident.Attachments = *req.Attachments
	}

	// Save updated incident
	if err := s.storage.UpdateIncident(ctx, incident); err != nil {
		return nil, fmt.Errorf("failed to update incident: %w", err)
	}

	return incident, nil
}

// DeleteIncident deletes an incident
func (s *IncidentService) DeleteIncident(ctx context.Context, id string) error {
	if id == "" {
		return fmt.Errorf("incident ID is required")
	}

	if err := s.storage.DeleteIncident(ctx, id); err != nil {
		return fmt.Errorf("failed to delete incident: %w", err)
	}

	return nil
}

// ListIncidents retrieves all incidents with optional filtering and sorting
func (s *IncidentService) ListIncidents(ctx context.Context, req *ListIncidentsRequest) ([]*model.IncidentRecord, error) {
	incidents, err := s.storage.ListIncidents(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list incidents: %w", err)
	}

	// Apply filters
	if req != nil {
		incidents = s.filterIncidents(incidents, req)
	}

	// Sort incidents (most recent first by default)
	sort.Slice(incidents, func(i, j int) bool {
		return incidents[i].UpdatedAt.After(incidents[j].UpdatedAt)
	})

	return incidents, nil
}

// ListIncidentSummaries retrieves incident summaries
func (s *IncidentService) ListIncidentSummaries(ctx context.Context, req *ListIncidentsRequest) ([]*model.IncidentSummary, error) {
	summaries, err := s.storage.ListIncidentSummaries(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list incident summaries: %w", err)
	}

	// Apply filters if provided
	if req != nil {
		// Convert summaries to full incidents for filtering, then back to summaries
		incidents := make([]*model.IncidentRecord, len(summaries))
		for i, summary := range summaries {
			// Create minimal incident record for filtering
			incidents[i] = &model.IncidentRecord{
				ID:          summary.ID,
				CreatedAt:   summary.CreatedAt,
				UpdatedAt:   summary.UpdatedAt,
				Stage:       summary.Stage,
				Significant: summary.Significant,
				Recurring:   summary.Recurring,
				CauseTag:    summary.CauseTag,
			}
		}

		filteredIncidents := s.filterIncidents(incidents, req)
		summaries = make([]*model.IncidentSummary, len(filteredIncidents))
		for i, incident := range filteredIncidents {
			summaries[i] = incident.ToSummary()
		}
	}

	// Sort summaries (most recent first by default)
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].UpdatedAt.After(summaries[j].UpdatedAt)
	})

	return summaries, nil
}

// GetIncidentStats returns statistics about incidents
func (s *IncidentService) GetIncidentStats(ctx context.Context) (*IncidentStats, error) {
	incidents, err := s.storage.ListIncidents(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get incidents for stats: %w", err)
	}

	stats := &IncidentStats{
		TotalIncidents: len(incidents),
		ByStage:        make(map[model.IncidentStage]int),
		ByCause:        make(map[model.CauseTag]int),
	}

	for _, incident := range incidents {
		stats.ByStage[incident.Stage]++
		stats.ByCause[incident.CauseTag]++

		if incident.Significant {
			stats.SignificantIncidents++
		}
		if incident.Recurring {
			stats.RecurringIncidents++
		}
	}

	return stats, nil
}

// filterIncidents applies filters to a list of incidents
func (s *IncidentService) filterIncidents(incidents []*model.IncidentRecord, req *ListIncidentsRequest) []*model.IncidentRecord {
	var filtered []*model.IncidentRecord

	for _, incident := range incidents {
		// Stage filter
		if len(req.Stages) > 0 {
			stageMatch := false
			for _, stage := range req.Stages {
				if incident.Stage == stage {
					stageMatch = true
					break
				}
			}
			if !stageMatch {
				continue
			}
		}

		// Cause filter
		if len(req.CauseTags) > 0 {
			causeMatch := false
			for _, cause := range req.CauseTags {
				if incident.CauseTag == cause {
					causeMatch = true
					break
				}
			}
			if !causeMatch {
				continue
			}
		}

		// Significant filter
		if req.SignificantOnly != nil && *req.SignificantOnly && !incident.Significant {
			continue
		}

		// Recurring filter
		if req.RecurringOnly != nil && *req.RecurringOnly && !incident.Recurring {
			continue
		}

		// Date range filters
		if req.CreatedAfter != nil && incident.CreatedAt.Before(*req.CreatedAfter) {
			continue
		}
		if req.CreatedBefore != nil && incident.CreatedAt.After(*req.CreatedBefore) {
			continue
		}

		filtered = append(filtered, incident)
	}

	return filtered
}

// Request/Response types

// CreateIncidentRequest represents a request to create an incident
type CreateIncidentRequest struct {
	InitialDetails     model.InitialDetails `json:"initialDetails"`
	Significant        bool                 `json:"significant"`
	Recurring          bool                 `json:"recurring"`
	CauseTag           model.CauseTag       `json:"causeTag"`
	UsersAffected      *int                 `json:"usersAffected,omitempty"`
	DowntimeMinutes    *int                 `json:"downtimeMinutes,omitempty"`
	FinancialImpactPct *float64             `json:"financialImpactPct,omitempty"`
	SectorPreset       *string              `json:"sectorPreset,omitempty"`
	Attachments        []model.Attachment   `json:"attachments,omitempty"`
}

// Validate validates the create incident request
func (r *CreateIncidentRequest) Validate() error {
	if r.InitialDetails.Title == "" {
		return fmt.Errorf("title is required")
	}
	if r.InitialDetails.Summary == "" {
		return fmt.Errorf("summary is required")
	}
	if r.InitialDetails.DetectedAt == "" {
		return fmt.Errorf("detectedAt is required")
	}

	// Validate cause tag
	switch r.CauseTag {
	case model.CauseTagPhishing, model.CauseTagVulnExploit, model.CauseTagMisconfig, model.CauseTagMalware, model.CauseTagOther:
		// Valid
	default:
		return fmt.Errorf("invalid cause tag: %s", r.CauseTag)
	}

	return nil
}

// UpdateIncidentRequest represents a request to update an incident
type UpdateIncidentRequest struct {
	Stage              model.IncidentStage   `json:"stage"`
	Significant        bool                  `json:"significant"`
	Recurring          bool                  `json:"recurring"`
	CauseTag           model.CauseTag        `json:"causeTag"`
	UsersAffected      *int                  `json:"usersAffected,omitempty"`
	DowntimeMinutes    *int                  `json:"downtimeMinutes,omitempty"`
	FinancialImpactPct *float64              `json:"financialImpactPct,omitempty"`
	SectorPreset       *string               `json:"sectorPreset,omitempty"`
	InitialDetails     *model.InitialDetails `json:"initialDetails,omitempty"`
	UpdateDetails      *model.UpdateDetails  `json:"updateDetails,omitempty"`
	FinalDetails       *model.FinalDetails   `json:"finalDetails,omitempty"`
	Attachments        *[]model.Attachment   `json:"attachments,omitempty"`
}

// Validate validates the update incident request
func (r *UpdateIncidentRequest) Validate() error {
	// Validate stage
	switch r.Stage {
	case model.IncidentStageInitial, model.IncidentStageUpdate, model.IncidentStageFinal:
		// Valid
	default:
		return fmt.Errorf("invalid stage: %s", r.Stage)
	}

	// Validate cause tag
	switch r.CauseTag {
	case model.CauseTagPhishing, model.CauseTagVulnExploit, model.CauseTagMisconfig, model.CauseTagMalware, model.CauseTagOther:
		// Valid
	default:
		return fmt.Errorf("invalid cause tag: %s", r.CauseTag)
	}

	// Validate stage-specific requirements
	if r.Stage == model.IncidentStageUpdate && r.UpdateDetails == nil {
		return fmt.Errorf("updateDetails is required for update stage")
	}
	if r.Stage == model.IncidentStageFinal && r.FinalDetails == nil {
		return fmt.Errorf("finalDetails is required for final stage")
	}

	return nil
}

// ListIncidentsRequest represents a request to list incidents with filters
type ListIncidentsRequest struct {
	Stages          []model.IncidentStage `json:"stages,omitempty"`
	CauseTags       []model.CauseTag      `json:"causeTags,omitempty"`
	SignificantOnly *bool                 `json:"significantOnly,omitempty"`
	RecurringOnly   *bool                 `json:"recurringOnly,omitempty"`
	CreatedAfter    *time.Time            `json:"createdAfter,omitempty"`
	CreatedBefore   *time.Time            `json:"createdBefore,omitempty"`
}

// IncidentStats represents statistics about incidents
type IncidentStats struct {
	TotalIncidents       int                         `json:"totalIncidents"`
	SignificantIncidents int                         `json:"significantIncidents"`
	RecurringIncidents   int                         `json:"recurringIncidents"`
	ByStage              map[model.IncidentStage]int `json:"byStage"`
	ByCause              map[model.CauseTag]int      `json:"byCause"`
}
