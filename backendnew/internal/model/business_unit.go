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
	
	// Legal Entity Information
	LegalEntityName     string `json:"legal_entity_name,omitempty"`
	RegistrationCode    string `json:"registration_code,omitempty"`    // IDNO/VAT
	InternalCode        string `json:"internal_code,omitempty"`
	
	// Business Information
	Sector              string `json:"sector,omitempty"`
	Subsector           string `json:"subsector,omitempty"`
	CompanySizeBand     string `json:"company_size_band,omitempty"`    // micro/small/medium/large
	HeadcountRange      string `json:"headcount_range,omitempty"`
	
	// Location Information
	Country             string `json:"country,omitempty"`
	Address             string `json:"address,omitempty"`
	Timezone            string `json:"timezone,omitempty"`
	
	// Domain Information
	PrimaryDomain       string `json:"primary_domain,omitempty"`
	OtherDomainsCount   int    `json:"other_domains_count,omitempty"`
	
	// Legal Compliance
	FurnizorServicii    *bool  `json:"furnizor_servicii,omitempty"`    // Law 48/2023
	FurnizorDate        string `json:"furnizor_date,omitempty"`         // Date/reference for Law 48/2023
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

// NewBusinessUnitWithDetails creates a new business unit with all details
func NewBusinessUnitWithDetails(name, legalEntityName, registrationCode, internalCode, sector, subsector, companySizeBand, headcountRange, country, address, timezone, primaryDomain string, otherDomainsCount int, furnizorServicii *bool, furnizorDate string) *BusinessUnit {
	now := time.Now()
	return &BusinessUnit{
		ID:                  util.GenerateID(),
		Name:                name,
		CreatedAt:           now,
		UpdatedAt:           now,
		LegalEntityName:     legalEntityName,
		RegistrationCode:    registrationCode,
		InternalCode:        internalCode,
		Sector:              sector,
		Subsector:           subsector,
		CompanySizeBand:     companySizeBand,
		HeadcountRange:      headcountRange,
		Country:             country,
		Address:             address,
		Timezone:            timezone,
		PrimaryDomain:       primaryDomain,
		OtherDomainsCount:   otherDomainsCount,
		FurnizorServicii:    furnizorServicii,
		FurnizorDate:        furnizorDate,
	}
}

// Update updates the business unit name and timestamp
func (bu *BusinessUnit) Update(name string) {
	bu.Name = name
	bu.UpdatedAt = time.Now()
}

// UpdateWithDetails updates the business unit with all details
func (bu *BusinessUnit) UpdateWithDetails(name, legalEntityName, registrationCode, internalCode, sector, subsector, companySizeBand, headcountRange, country, address, timezone, primaryDomain string, otherDomainsCount int, furnizorServicii *bool, furnizorDate string) {
	bu.Name = name
	bu.LegalEntityName = legalEntityName
	bu.RegistrationCode = registrationCode
	bu.InternalCode = internalCode
	bu.Sector = sector
	bu.Subsector = subsector
	bu.CompanySizeBand = companySizeBand
	bu.HeadcountRange = headcountRange
	bu.Country = country
	bu.Address = address
	bu.Timezone = timezone
	bu.PrimaryDomain = primaryDomain
	bu.OtherDomainsCount = otherDomainsCount
	bu.FurnizorServicii = furnizorServicii
	bu.FurnizorDate = furnizorDate
	bu.UpdatedAt = time.Now()
}
