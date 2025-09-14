package model

import (
	"assetscanner/internal/util"
	"time"
)

// BusinessUnit represents a business unit tag that can be assigned to assets
type BusinessUnit struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// NewBusinessUnit creates a new business unit with default values
func NewBusinessUnit(name string) *BusinessUnit {
	now := time.Now()
	return &BusinessUnit{
		ID:        util.GenerateID(),
		Name:      name,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

// Update updates the business unit name and timestamp
func (bu *BusinessUnit) Update(name string) {
	bu.Name = name
	bu.UpdatedAt = time.Now()
}
