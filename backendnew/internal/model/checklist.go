package model

import "time"

// ChecklistItemTemplate defines a template for a checklist item
type ChecklistItemTemplate struct {
	ID               string         `json:"id"`
	Title            string         `json:"title"`
	Description      string         `json:"description"`
	Category         string         `json:"category"`
	Required         bool           `json:"required"`
	Scope            string         `json:"scope"`                 // "global" or "asset"
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
	WhatItMeans  string                  `json:"what_it_means,omitempty"`
	WhyItMatters string                  `json:"why_it_matters,omitempty"`
	LawRefs      []string                `json:"law_refs,omitempty"`
	Priority     string                  `json:"priority,omitempty"` // "must", "should", "may"
	Resources    []ChecklistItemResource `json:"resources,omitempty"`
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
	ID        string    `json:"id"`
	ItemID    string    `json:"item_id"`
	Scope     string    `json:"scope"`              // "global" or "asset"
	AssetID   *string   `json:"asset_id,omitempty"` // Null for global items
	Status    string    `json:"status"`             // "yes", "no", "na"
	Notes     string    `json:"notes,omitempty"`
	UpdatedAt time.Time `json:"updated_at"`
	Source    string    `json:"source"` // "manual"
}

// DerivedChecklistItem represents a checklist item with its computed/assigned status
// This is not stored directly but computed on-the-fly for API responses
type DerivedChecklistItem struct {
	ChecklistItemTemplate
	Status        string                 `json:"status"`                   // "yes", "no", "na"
	Source        string                 `json:"source"`                   // "auto" or "manual"
	Evidence      map[string]interface{} `json:"evidence,omitempty"`       // Relevant metadata for auto-derived status
	Notes         string                 `json:"notes,omitempty"`          // From manual assignment
	UpdatedAt     *time.Time             `json:"updated_at,omitempty"`     // From manual assignment
	Attachments   []string               `json:"attachments,omitempty"`    // File attachment IDs
	CoveredAssets []AssetCoverage        `json:"covered_assets,omitempty"` // Assets covered by this check
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
	ChecklistScopeGlobal = "global"
	ChecklistScopeAsset  = "asset"
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
