package model

import "time"

// SimpleChecklistStatus represents a simple status storage
type SimpleChecklistStatus struct {
	Key       string    `json:"key"`    // Format: "global:{itemId}" or "asset:{assetId}:{itemId}"
	Status    string    `json:"status"` // "yes", "no", "na"
	Notes     string    `json:"notes,omitempty"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Helper functions to create keys
func GlobalChecklistKey(itemId string) string {
	return "global:" + itemId
}

func AssetChecklistKey(assetId, itemId string) string {
	return "asset:" + assetId + ":" + itemId
}
