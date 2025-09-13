package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// AppConfig holds all application configuration
type AppConfig struct {
	Server     ServerConfig     `json:"server"`
	Storage    StorageConfig    `json:"storage"`
	Scanner    ScannerConfig    `json:"scanner"`
	Recontool  RecontoolConfig  `json:"recontool"`
	Monitoring MonitoringConfig `json:"monitoring"`
}

// ServerConfig holds HTTP server configuration
type ServerConfig struct {
	Port                int           `json:"port"`
	Host                string        `json:"host"`
	ReadTimeout         time.Duration `json:"read_timeout"`
	WriteTimeout        time.Duration `json:"write_timeout"`
	EnableSwagger       bool          `json:"enable_swagger"`
	CORSAllowedOrigins  []string      `json:"cors_allowed_origins"`
	EnableRequestLogger bool          `json:"enable_request_logger"`
}

// StorageConfig holds file storage configuration
type StorageConfig struct {
	DataDir         string        `json:"data_dir"`
	AssetsFile      string        `json:"assets_file"`
	JobsFile        string        `json:"jobs_file"`
	ScanResultsFile string        `json:"scan_results_file"`
	BackupEnabled   bool          `json:"backup_enabled"`
	BackupInterval  time.Duration `json:"backup_interval"`
}

// ScannerConfig holds Lua scanner configuration
type ScannerConfig struct {
	ScriptsDir        string        `json:"scripts_dir"`
	MaxConcurrent     int           `json:"max_concurrent"`
	DefaultTimeout    time.Duration `json:"default_timeout"`
	EnableScriptCache bool          `json:"enable_script_cache"`
	WorkerPoolSize    int           `json:"worker_pool_size"`
}

// RecontoolConfig holds integrated recon service configuration
type RecontoolConfig struct {
	DefaultTimeout  time.Duration `json:"default_timeout"`
	EnableScanning  bool          `json:"enable_scanning"`
	EnableStreaming bool          `json:"enable_streaming"`
}

// MonitoringConfig holds monitoring and logging configuration
type MonitoringConfig struct {
	EnableHealthCheck bool   `json:"enable_health_check"`
	LogLevel          string `json:"log_level"`
	EnableMetrics     bool   `json:"enable_metrics"`
	MetricsPort       int    `json:"metrics_port"`
}

// NewConfigFromEnv creates a new configuration from environment variables
func NewConfigFromEnv() (*AppConfig, error) {
	config := &AppConfig{
		Server: ServerConfig{
			Port:                getEnvInt("SERVER_PORT", 8080),
			Host:                getEnvString("SERVER_HOST", "0.0.0.0"),
			ReadTimeout:         getEnvDuration("SERVER_READ_TIMEOUT", 30*time.Second),
			WriteTimeout:        getEnvDuration("SERVER_WRITE_TIMEOUT", 30*time.Second),
			EnableSwagger:       getEnvBool("SERVER_ENABLE_SWAGGER", true),
			CORSAllowedOrigins:  getEnvStringSlice("SERVER_CORS_ORIGINS", []string{"*"}),
			EnableRequestLogger: getEnvBool("SERVER_ENABLE_REQUEST_LOGGER", true),
		},
		Storage: StorageConfig{
			DataDir:         getEnvString("STORAGE_DATA_DIR", "./data"),
			AssetsFile:      getEnvString("STORAGE_ASSETS_FILE", "assets.json"),
			JobsFile:        getEnvString("STORAGE_JOBS_FILE", "jobs.json"),
			ScanResultsFile: getEnvString("STORAGE_SCAN_RESULTS_FILE", "scan_results.json"),
			BackupEnabled:   getEnvBool("STORAGE_BACKUP_ENABLED", true),
			BackupInterval:  getEnvDuration("STORAGE_BACKUP_INTERVAL", 1*time.Hour),
		},
		Scanner: ScannerConfig{
			ScriptsDir:        getEnvString("SCANNER_SCRIPTS_DIR", "../scripts"),
			MaxConcurrent:     getEnvInt("SCANNER_MAX_CONCURRENT", 10),
			DefaultTimeout:    getEnvDuration("SCANNER_DEFAULT_TIMEOUT", 5*time.Minute),
			EnableScriptCache: getEnvBool("SCANNER_ENABLE_SCRIPT_CACHE", true),
			WorkerPoolSize:    getEnvInt("SCANNER_WORKER_POOL_SIZE", 5),
		},
		Recontool: RecontoolConfig{
			DefaultTimeout:  getEnvDuration("RECONTOOL_DEFAULT_TIMEOUT", 10*time.Minute),
			EnableScanning:  getEnvBool("RECONTOOL_ENABLE_SCANNING", true),
			EnableStreaming: getEnvBool("RECONTOOL_ENABLE_STREAMING", true),
		},
		Monitoring: MonitoringConfig{
			EnableHealthCheck: getEnvBool("MONITORING_ENABLE_HEALTH_CHECK", true),
			LogLevel:          getEnvString("MONITORING_LOG_LEVEL", "info"),
			EnableMetrics:     getEnvBool("MONITORING_ENABLE_METRICS", false),
			MetricsPort:       getEnvInt("MONITORING_METRICS_PORT", 9090),
		},
	}

	// Validate configuration
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return config, nil
}

// Validate checks if the configuration is valid
func (c *AppConfig) Validate() error {
	// Validate server configuration
	if c.Server.Port < 1 || c.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", c.Server.Port)
	}

	// Validate storage configuration
	if c.Storage.DataDir == "" {
		return fmt.Errorf("storage data directory cannot be empty")
	}

	// Validate scanner configuration
	if c.Scanner.MaxConcurrent < 1 {
		return fmt.Errorf("scanner max concurrent must be at least 1")
	}

	if c.Scanner.WorkerPoolSize < 1 {
		return fmt.Errorf("scanner worker pool size must be at least 1")
	}

	// Validate recontool configuration
	if c.Recontool.DefaultTimeout <= 0 {
		return fmt.Errorf("recontool default timeout must be positive")
	}

	// Validate monitoring configuration
	validLogLevels := []string{"debug", "info", "warn", "error"}
	if !contains(validLogLevels, c.Monitoring.LogLevel) {
		return fmt.Errorf("invalid log level: %s (must be one of: %s)", c.Monitoring.LogLevel, strings.Join(validLogLevels, ", "))
	}

	return nil
}

// GetServerAddr returns the server address string
func (c *AppConfig) GetServerAddr() string {
	return fmt.Sprintf("%s:%d", c.Server.Host, c.Server.Port)
}

// Helper functions for environment variable parsing

func getEnvString(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}

func getEnvStringSlice(key string, defaultValue []string) []string {
	if value := os.Getenv(key); value != "" {
		return strings.Split(value, ",")
	}
	return defaultValue
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
