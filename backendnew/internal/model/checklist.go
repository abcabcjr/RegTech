package model

import "time"

// ChecklistItemTemplate defines a template for a checklist item
type ChecklistItemTemplate struct {
	ID               string         `json:"id"`
	Title            string         `json:"title"`
	Description      string         `json:"description"`
	Category         string         `json:"category"`
	Required         bool           `json:"required"`
	Scope            string         `json:"scope"`                 // "global", "asset", or "business_unit"
	AssetTypes       []string       `json:"asset_types,omitempty"` // Applicable asset types if scope is "asset"
	Recommendation   string         `json:"recommendation,omitempty"`
	EvidenceRules    []EvidenceRule `json:"evidence_rules,omitempty"`    // Rules for auto-derivation
	ScriptControlled bool           `json:"script_controlled,omitempty"` // Can be controlled by Lua scripts

	// Extended metadata fields for rich UI display
	HelpText   string             `json:"help_text,omitempty"`
	WhyMatters string             `json:"why_matters,omitempty"`
	Kind       string             `json:"kind,omitempty"` // "manual" or "auto"
	ReadOnly   bool               `json:"read_only,omitempty"`
	Info       *ChecklistItemInfo `json:"info,omitempty"`
}

// ChecklistItemInfo contains detailed information about a checklist item
type ChecklistItemInfo struct {
	WhatItMeans    string                  `json:"what_it_means,omitempty"`
	WhyItMatters   string                  `json:"why_it_matters,omitempty"`
	LawRefs        []string                `json:"law_refs,omitempty"`
	Priority       string                  `json:"priority,omitempty"`        // "critical", "high", "medium", "low"
	PriorityNumber int                     `json:"priority_number,omitempty"` // Numeric priority (1=critical, 2=high, 3=medium, 4=low)
	Resources      []ChecklistItemResource `json:"resources,omitempty"`
	Risks          *ChecklistItemRisks     `json:"risks,omitempty"`
	Guide          *ChecklistItemGuide     `json:"guide,omitempty"`
	Legal          *ChecklistItemLegal     `json:"legal,omitempty"`
}

// ChecklistItemRisks contains risk-related information
type ChecklistItemRisks struct {
	AttackVectors   []string `json:"attack_vectors,omitempty"`
	PotentialImpact []string `json:"potential_impact,omitempty"`
}

// ChecklistItemGuide contains guide information
type ChecklistItemGuide struct {
	NonTechnicalSteps []string `json:"non_technical_steps,omitempty"`
	ScopeCaveats      string   `json:"scope_caveats,omitempty"`
	AcceptanceSummary string   `json:"acceptance_summary,omitempty"`
	FAQ               []FAQ    `json:"faq,omitempty"`
}

// FAQ represents a frequently asked question
type FAQ struct {
	Q string `json:"q"`
	A string `json:"a"`
}

// ChecklistItemLegal contains legal information
type ChecklistItemLegal struct {
	RequirementSummary string   `json:"requirement_summary,omitempty"`
	ArticleRefs        []string `json:"article_refs,omitempty"`
	Quotes             []Quote  `json:"quotes,omitempty"`
}

// Quote represents a legal quote
type Quote struct {
	Text   string `json:"text"`
	Source string `json:"source"`
}

// ChecklistItemResource represents a helpful resource link
type ChecklistItemResource struct {
	Title string `json:"title"`
	URL   string `json:"url"`
}

// EvidenceRule defines a rule to derive checklist status from scan metadata
type EvidenceRule struct {
	Source string      `json:"source"`          // "scan_metadata"
	Key    string      `json:"key"`             // e.g., "http.title", "last_scanned_at"
	Op     string      `json:"op"`              // "exists", "eq", "regex", "gte_days_since"
	Value  interface{} `json:"value,omitempty"` // Value for "eq", "regex", "gte_days_since"
}

// ChecklistAssignment represents a manual assignment or override of a checklist item status
type ChecklistAssignment struct {
	ID             string    `json:"id"`
	ItemID         string    `json:"item_id"`
	Scope          string    `json:"scope"`                      // "global", "asset", or "business_unit"
	AssetID        *string   `json:"asset_id,omitempty"`         // Null for global and business unit items
	BusinessUnitID *string   `json:"business_unit_id,omitempty"` // Null for global and asset items
	Status         string    `json:"status"`                     // "yes", "no", "na"
	Notes          string    `json:"notes,omitempty"`
	UpdatedAt      time.Time `json:"updated_at"`
	Source         string    `json:"source"` // "manual"
}

// DerivedChecklistItem represents a checklist item with its computed/assigned status
// This is not stored directly but computed on-the-fly for API responses
type DerivedChecklistItem struct {
	ChecklistItemTemplate
	Status         string                 `json:"status"`                    // "yes", "no", "na"
	Source         string                 `json:"source"`                    // "auto" or "manual"
	Evidence       map[string]interface{} `json:"evidence,omitempty"`        // Relevant metadata for auto-derived status
	Notes          string                 `json:"notes,omitempty"`           // From manual assignment
	UpdatedAt      *time.Time             `json:"updated_at,omitempty"`      // From manual assignment
	Attachments    []string               `json:"attachments,omitempty"`     // File attachment IDs
	CoveredAssets  []AssetCoverage        `json:"covered_assets,omitempty"`  // Assets covered by this check
	Priority       string                 `json:"priority,omitempty"`        // "critical", "high", "medium", "low"
	PriorityNumber int                    `json:"priority_number,omitempty"` // Numeric priority (1=critical, 2=high, 3=medium, 4=low)
}

// AssetCoverage represents an asset that is covered by a compliance check
type AssetCoverage struct {
	AssetID    string     `json:"asset_id"`
	AssetType  string     `json:"asset_type"`
	AssetValue string     `json:"asset_value"`
	Status     string     `json:"status"` // "yes", "no" (excludes "na")
	Notes      string     `json:"notes,omitempty"`
	UpdatedAt  *time.Time `json:"updated_at,omitempty"`
}

// Constants for ChecklistItemTemplate Scope
const (
	ChecklistScopeGlobal       = "global"
	ChecklistScopeAsset        = "asset"
	ChecklistScopeBusinessUnit = "business_unit"
)

// Constants for ChecklistItemTemplate Status
const (
	ChecklistStatusYes = "yes"
	ChecklistStatusNo  = "no"
	ChecklistStatusNA  = "na"
)

// Constants for EvidenceRule Op
const (
	EvidenceOpExists       = "exists"
	EvidenceOpEquals       = "eq"
	EvidenceOpRegex        = "regex"
	EvidenceOpGteDaysSince = "gte_days_since"
)

// Constants for ChecklistAssignment Source
const (
	ChecklistSourceAuto   = "auto"
	ChecklistSourceManual = "manual"
)
