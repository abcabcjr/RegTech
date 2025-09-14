package service

import (
	"assetscanner/internal/model"
	"assetscanner/internal/storage"
	"context"
	"fmt"
	"sort"
	"strings"
)

// BusinessUnitService handles business logic for business units
type BusinessUnitService struct {
	storage storage.Storage
}

// NewBusinessUnitService creates a new business unit service
func NewBusinessUnitService(storage storage.Storage) *BusinessUnitService {
	return &BusinessUnitService{
		storage: storage,
	}
}

// CreateBusinessUnit creates a new business unit
func (s *BusinessUnitService) CreateBusinessUnit(ctx context.Context, name string) (*model.BusinessUnit, error) {
	// Validate name
	name = strings.TrimSpace(name)
	if name == "" {
		return nil, fmt.Errorf("business unit name cannot be empty")
	}

	// Check if a business unit with this name already exists
	existingUnits, err := s.storage.ListBusinessUnits(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing business units: %w", err)
	}

	for _, unit := range existingUnits {
		if strings.EqualFold(unit.Name, name) {
			return nil, fmt.Errorf("business unit with name '%s' already exists", name)
		}
	}

	// Create new business unit
	businessUnit := model.NewBusinessUnit(name)

	if err := s.storage.CreateBusinessUnit(ctx, businessUnit); err != nil {
		return nil, fmt.Errorf("failed to create business unit: %w", err)
	}

	return businessUnit, nil
}

// GetBusinessUnit retrieves a business unit by ID
func (s *BusinessUnitService) GetBusinessUnit(ctx context.Context, id string) (*model.BusinessUnit, error) {
	businessUnit, err := s.storage.GetBusinessUnit(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get business unit: %w", err)
	}

	return businessUnit, nil
}

// UpdateBusinessUnit updates a business unit's name
func (s *BusinessUnitService) UpdateBusinessUnit(ctx context.Context, id, name string) (*model.BusinessUnit, error) {
	// Validate name
	name = strings.TrimSpace(name)
	if name == "" {
		return nil, fmt.Errorf("business unit name cannot be empty")
	}

	// Get existing business unit
	businessUnit, err := s.storage.GetBusinessUnit(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get business unit: %w", err)
	}

	// Check if another business unit with this name already exists
	existingUnits, err := s.storage.ListBusinessUnits(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing business units: %w", err)
	}

	for _, unit := range existingUnits {
		if unit.ID != id && strings.EqualFold(unit.Name, name) {
			return nil, fmt.Errorf("business unit with name '%s' already exists", name)
		}
	}

	// Update business unit
	businessUnit.Update(name)

	if err := s.storage.UpdateBusinessUnit(ctx, businessUnit); err != nil {
		return nil, fmt.Errorf("failed to update business unit: %w", err)
	}

	return businessUnit, nil
}

// DeleteBusinessUnit deletes a business unit
func (s *BusinessUnitService) DeleteBusinessUnit(ctx context.Context, id string) error {
	// Check if business unit exists
	_, err := s.storage.GetBusinessUnit(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get business unit: %w", err)
	}

	if err := s.storage.DeleteBusinessUnit(ctx, id); err != nil {
		return fmt.Errorf("failed to delete business unit: %w", err)
	}

	return nil
}

// ListBusinessUnits retrieves all business units, sorted by name
// Auto-creates a default "Organization" business unit if none exist
func (s *BusinessUnitService) ListBusinessUnits(ctx context.Context) ([]*model.BusinessUnit, error) {
	businessUnits, err := s.storage.ListBusinessUnits(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list business units: %w", err)
	}

	// Auto-create default "Organization" business unit if none exist
	if len(businessUnits) == 0 {
		fmt.Println("No business units found, creating default 'Organization' business unit")

		defaultBusinessUnit := model.NewBusinessUnit("Organization")
		if err := s.storage.CreateBusinessUnit(ctx, defaultBusinessUnit); err != nil {
			return nil, fmt.Errorf("failed to create default business unit: %w", err)
		}

		businessUnits = []*model.BusinessUnit{defaultBusinessUnit}
		fmt.Printf("Created default business unit with ID: %s\n", defaultBusinessUnit.ID)
	}

	// Sort by name for consistent ordering
	sort.Slice(businessUnits, func(i, j int) bool {
		return strings.ToLower(businessUnits[i].Name) < strings.ToLower(businessUnits[j].Name)
	})

	return businessUnits, nil
}
