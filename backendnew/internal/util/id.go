package util

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"
)

// GenerateID generates a unique ID for assets, jobs, etc.
func GenerateID() string {
	// Generate 8 random bytes
	bytes := make([]byte, 8)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based ID if random fails
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return hex.EncodeToString(bytes)
}

// GenerateJobID generates a job ID with a prefix
func GenerateJobID(jobType string) string {
	return fmt.Sprintf("%s_%s", jobType, GenerateID())
}

// GenerateAssetID generates an asset ID based on type and value
func GenerateAssetID(assetType, value string) string {
	return fmt.Sprintf("%s_%s", assetType, GenerateID())
}
