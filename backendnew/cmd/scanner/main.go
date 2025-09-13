package main

import (
	"assetscanner/internal/config"
	"assetscanner/internal/handler"
	"assetscanner/internal/middleware"
	"assetscanner/internal/recon"
	"assetscanner/internal/scanner"
	"assetscanner/internal/service"
	"assetscanner/internal/storage"
	"log"
	"net/http"

	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	echomw "github.com/labstack/echo/v4/middleware"
	echoSwagger "github.com/swaggo/echo-swagger"

	_ "assetscanner/docs" // Import docs for swagger
)

// Version information (set via ldflags during build)
var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

// @title Asset Scanner API
// @version 1.0
// @description A powerful asset discovery and scanning API with Lua script support
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.example.com/support
// @contact.email support@example.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Load configuration
	cfg, err := config.NewConfigFromEnv()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize storage
	store, err := storage.NewJSONStorage(&cfg.Storage)
	if err != nil {
		log.Fatalf("Failed to initialize storage: %v", err)
	}
	defer store.Close()

	// Initialize Lua scanner
	luaScanner, err := scanner.NewLuaScanner(&cfg.Scanner)
	if err != nil {
		log.Fatalf("Failed to initialize Lua scanner: %v", err)
	}
	defer luaScanner.Close()

	// Initialize recon service
	reconConfig := &recon.ReconConfig{
		EnableScanning:  cfg.Recontool.EnableScanning,
		EnableStreaming: cfg.Recontool.EnableStreaming,
		DefaultTimeout:  cfg.Recontool.DefaultTimeout,
		Verbose:         false, // Can be made configurable
	}
	reconService := recon.NewReconService(reconConfig)

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	if cfg.Server.EnableRequestLogger {
		e.Use(echomw.Logger())
	}
	e.Use(echomw.Recover())
	e.Use(echomw.Secure())
	e.Use(middleware.ErrorHandler())
	e.Use(middleware.CORS(cfg.Server.CORSAllowedOrigins))

	// Request timeout middleware
	e.Use(echomw.TimeoutWithConfig(echomw.TimeoutConfig{
		Timeout: cfg.Server.ReadTimeout,
	}))

	// Initialize services
	simpleChecklistService := service.NewSimpleChecklistService(store)

	// Initialize file service (non-fatal if MinIO is unavailable)
	fileService, err := service.NewFileService(&cfg.MinIO, store)
	if err != nil {
		log.Printf("Warning: Failed to initialize file service: %v", err)
		log.Printf("File upload functionality will be unavailable until MinIO is accessible")
	}

	// Initialize handlers
	healthHandler := handler.NewHealthHandler(store, version)
	assetsHandler := handler.NewAssetsHandler(
		store,
		luaScanner,
		reconService,
		simpleChecklistService,
		cfg.Recontool.EnableScanning,
		cfg.Recontool.EnableStreaming,
	)
	simpleChecklistHandler := handler.NewSimpleChecklistHandler(simpleChecklistService)
	filesHandler := handler.NewFilesHandler(fileService)

	// Health check endpoint
	e.GET("/health", healthHandler.HealthCheck)

	// Swagger documentation
	if cfg.Server.EnableSwagger {
		e.GET("/swagger/*", echoSwagger.WrapHandler)
	}

	// API v1 routes
	apiV1 := e.Group("/api/v1")

	// Asset routes
	apiV1.POST("/assets/discover", assetsHandler.DiscoverAssets)
	apiV1.GET("/assets/catalogue", assetsHandler.GetAssetCatalogue)
	apiV1.GET("/assets/:id", assetsHandler.GetAssetDetails)
	apiV1.POST("/assets/:id/scan", assetsHandler.StartAssetScan)
	apiV1.POST("/assets/scan", assetsHandler.StartAllAssetsScan)

	// Job routes
	apiV1.GET("/jobs/:id", assetsHandler.GetJobStatus)

	// Simple Checklist routes
	apiV1.GET("/checklist/global", simpleChecklistHandler.GetGlobalChecklist)
	apiV1.GET("/checklist/asset/:id", simpleChecklistHandler.GetAssetChecklist)
	apiV1.POST("/checklist/status", simpleChecklistHandler.SetStatus)
	apiV1.GET("/checklist/templates", simpleChecklistHandler.ListTemplates)
	apiV1.POST("/checklist/templates/upload", simpleChecklistHandler.UploadTemplates)
	apiV1.GET("/checklist/coverage/summary", simpleChecklistHandler.GetComplianceCoverageSummary)

	// File upload/download routes
	apiV1.POST("/files/upload/initiate", filesHandler.InitiateUpload)
	apiV1.POST("/files/:fileId/confirm", filesHandler.ConfirmUpload)
	apiV1.GET("/files/:fileId/download", filesHandler.GenerateDownloadURL)
	apiV1.GET("/files/:fileId", filesHandler.GetFileInfo)
	apiV1.GET("/files", filesHandler.ListFileAttachments)
	apiV1.DELETE("/files/:fileId", filesHandler.DeleteFile)
	apiV1.GET("/files/supported-types", filesHandler.GetSupportedContentTypes)
	apiV1.GET("/files/limits", filesHandler.GetUploadLimits)
	apiV1.GET("/files/status", filesHandler.GetServiceStatus)

	// Script management routes (bonus endpoints)
	apiV1.GET("/scripts", func(c echo.Context) error {
		scripts := luaScanner.ListScripts()
		scriptInfos := make([]map[string]interface{}, len(scripts))
		for i, script := range scripts {
			scriptInfos[i] = map[string]interface{}{
				"name":        script.Name,
				"description": script.Description,
				"category":    script.Category,
				"author":      script.Author,
				"version":     script.Version,
				"asset_types": script.AssetTypes,
			}
		}
		return c.JSON(http.StatusOK, map[string]interface{}{
			"scripts": scriptInfos,
			"total":   len(scriptInfos),
		})
	})

	apiV1.POST("/scripts/reload", func(c echo.Context) error {
		if err := luaScanner.ReloadScripts(); err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{
				"error": "Failed to reload scripts",
			})
		}
		return c.JSON(http.StatusOK, map[string]string{
			"message": "Scripts reloaded successfully",
		})
	})

	// Storage stats endpoint
	apiV1.GET("/stats", func(c echo.Context) error {
		stats, err := store.GetStats()
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{
				"error": "Failed to get storage stats",
			})
		}
		return c.JSON(http.StatusOK, stats)
	})

	// Version endpoint
	e.GET("/version", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{
			"version": version,
			"commit":  commit,
			"date":    date,
		})
	})

	// Start server
	log.Printf("Starting Asset Scanner API server on %s", cfg.GetServerAddr())
	log.Printf("Version: %s, Commit: %s, Date: %s", version, commit, date)
	log.Printf("Swagger UI available at: http://%s/swagger/", cfg.GetServerAddr())

	// Configure server timeouts
	e.Server.ReadTimeout = cfg.Server.ReadTimeout
	e.Server.WriteTimeout = cfg.Server.WriteTimeout

	if err := e.Start(cfg.GetServerAddr()); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server failed to start: %v", err)
	}
}
