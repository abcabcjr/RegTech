package errors

import (
	"fmt"
	"net/http"
)

// ApplicationError represents a structured application error
type ApplicationError struct {
	Code     int               `json:"code"`
	Message  string            `json:"message"`
	Details  map[string]string `json:"details,omitempty"`
	Internal error             `json:"-"` // Internal error, not exposed to clients
}

// Error implements the error interface
func (e *ApplicationError) Error() string {
	if e.Internal != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Internal)
	}
	return e.Message
}

// Common error constructors

// NewBadRequest creates a 400 Bad Request error
func NewBadRequest(message string, details map[string]string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusBadRequest,
		Message: message,
		Details: details,
	}
}

// NewValidationError creates a 400 Bad Request error for validation failures
func NewValidationError(details map[string]string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusBadRequest,
		Message: "Validation failed",
		Details: details,
	}
}

// NewNotFound creates a 404 Not Found error
func NewNotFound(resource string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusNotFound,
		Message: fmt.Sprintf("%s not found", resource),
	}
}

// NewConflict creates a 409 Conflict error
func NewConflict(message string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusConflict,
		Message: message,
	}
}

// NewInternalError creates a 500 Internal Server Error
func NewInternalError(message string, internal error) *ApplicationError {
	return &ApplicationError{
		Code:     http.StatusInternalServerError,
		Message:  message,
		Internal: internal,
	}
}

// NewStorageError creates a storage-related error
func NewStorageError(operation string, internal error) *ApplicationError {
	return &ApplicationError{
		Code:     http.StatusInternalServerError,
		Message:  fmt.Sprintf("Storage operation failed: %s", operation),
		Internal: internal,
	}
}

// NewScannerError creates a scanner-related error
func NewScannerError(message string, internal error) *ApplicationError {
	return &ApplicationError{
		Code:     http.StatusInternalServerError,
		Message:  fmt.Sprintf("Scanner error: %s", message),
		Internal: internal,
	}
}

// NewJobError creates a job-related error
func NewJobError(message string, internal error) *ApplicationError {
	return &ApplicationError{
		Code:     http.StatusInternalServerError,
		Message:  fmt.Sprintf("Job error: %s", message),
		Internal: internal,
	}
}

// NewRecontoolError creates a recontool-related error
func NewRecontoolError(message string, internal error) *ApplicationError {
	return &ApplicationError{
		Code:     http.StatusInternalServerError,
		Message:  fmt.Sprintf("Recontool error: %s", message),
		Internal: internal,
	}
}

// NewTimeoutError creates a timeout error
func NewTimeoutError(operation string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusRequestTimeout,
		Message: fmt.Sprintf("Operation timeout: %s", operation),
	}
}

// NewServiceUnavailable creates a 503 Service Unavailable error
func NewServiceUnavailable(service string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusServiceUnavailable,
		Message: fmt.Sprintf("Service unavailable: %s", service),
	}
}

// NewTooManyRequests creates a 429 Too Many Requests error
func NewTooManyRequests(message string) *ApplicationError {
	return &ApplicationError{
		Code:    http.StatusTooManyRequests,
		Message: message,
	}
}

// IsApplicationError checks if an error is an ApplicationError
func IsApplicationError(err error) (*ApplicationError, bool) {
	if appErr, ok := err.(*ApplicationError); ok {
		return appErr, true
	}
	return nil, false
}

// GetHTTPStatus returns the HTTP status code for an error
func GetHTTPStatus(err error) int {
	if appErr, ok := IsApplicationError(err); ok {
		return appErr.Code
	}
	return http.StatusInternalServerError
}
