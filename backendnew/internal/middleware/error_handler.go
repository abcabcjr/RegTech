package middleware

import (
	v1 "assetscanner/api/v1"
	"assetscanner/internal/errors"
	"log"
	"net/http"

	"github.com/labstack/echo/v4"
)

// ErrorHandler handles application errors and returns appropriate HTTP responses
func ErrorHandler() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			err := next(c)
			if err == nil {
				return nil
			}

			// Check if it's an ApplicationError
			if appErr, ok := errors.IsApplicationError(err); ok {
				return c.JSON(appErr.Code, v1.ErrorResponse{
					Error:   appErr.Message,
					Code:    appErr.Code,
					Details: appErr.Details,
				})
			}

			// Check if it's an Echo HTTPError
			if httpErr, ok := err.(*echo.HTTPError); ok {
				return c.JSON(httpErr.Code, v1.ErrorResponse{
					Error: httpErr.Message.(string),
					Code:  httpErr.Code,
				})
			}

			// Log unexpected errors
			log.Printf("Unexpected error: %v", err)

			// Return generic internal server error
			return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
				Error: "Internal server error",
				Code:  http.StatusInternalServerError,
			})
		}
	}
}
