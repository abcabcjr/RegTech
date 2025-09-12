package handler

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/storage"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

// HealthHandler handles health check endpoints
type HealthHandler struct {
	storage storage.Storage
	version string
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(storage storage.Storage, version string) *HealthHandler {
	return &HealthHandler{
		storage: storage,
		version: version,
	}
}

// HealthCheck returns the health status of the service
// @Summary Health check
// @Description Check if the service is healthy
// @Tags health
// @Produce json
// @Success 200 {object} v1.HealthResponse
// @Router /health [get]
func (h *HealthHandler) HealthCheck(c echo.Context) error {
	services := make(map[string]string)
	status := "healthy"

	// Check storage health
	if _, err := h.storage.GetStats(); err != nil {
		services["storage"] = "unhealthy"
		status = "unhealthy"
	} else {
		services["storage"] = "healthy"
	}

	response := v1.HealthResponse{
		Status:    status,
		Timestamp: time.Now(),
		Services:  services,
		Version:   h.version,
	}

	if status == "healthy" {
		return c.JSON(http.StatusOK, response)
	} else {
		return c.JSON(http.StatusServiceUnavailable, response)
	}
}
