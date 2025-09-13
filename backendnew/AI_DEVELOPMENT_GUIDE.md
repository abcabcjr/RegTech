# BackendNew Development Guide for AI Agents

## Project Overview

This is a **Go** backend API for the RegTech compliance and asset management system. It provides REST endpoints for asset discovery, scanning, compliance checklist management, and integrates with Lua scripting for extensible security scanning capabilities.

## Key Technologies

- **Go 1.21+** (Modern Go with generics support)
- **Echo Framework** (HTTP web framework)
- **Swagger/OpenAPI** (API documentation generation)
- **Lua** (Embedded scripting for asset scanning)
- **JSON Storage** (File-based data persistence)
- **Docker** (Containerization support)

## Project Architecture

```
backendnew/
├── cmd/
│   └── scanner/
│       └── main.go              # Application entry point
├── internal/                    # Private application code
│   ├── config/
│   │   └── config.go           # Configuration management
│   ├── errors/
│   │   └── errors.go           # Custom error types
│   ├── handler/                # HTTP request handlers (controllers)
│   │   ├── assets.go           # Asset management endpoints
│   │   ├── health.go           # Health check endpoints
│   │   └── simple_checklist.go # Compliance checklist endpoints
│   ├── middleware/             # HTTP middleware
│   │   ├── cors.go             # CORS handling
│   │   └── error_handler.go    # Global error handling
│   ├── model/                  # Data models and structures
│   │   ├── asset.go            # Asset-related models
│   │   ├── checklist.go        # Checklist models (complex)
│   │   └── simple_checklist.go # Simplified checklist models
│   ├── scanner/                # Lua scripting engine
│   │   ├── lua_scanner.go      # Main Lua execution engine
│   │   ├── lua_netlib.go       # TCP networking library for Lua
│   │   └── lua_httplib.go      # HTTP client library for Lua
│   ├── service/                # Business logic layer
│   │   └── simple_checklist.go # Checklist business logic
│   ├── storage/                # Data persistence layer
│   │   ├── storage.go          # Storage interface definition
│   │   └── json_storage.go     # JSON file-based implementation
│   └── util/
│       └── id.go               # Utility functions
├── api/
│   └── v1/
│       └── types.go            # API request/response types
├── docs/                       # Auto-generated Swagger documentation
│   ├── docs.go                 # Swagger docs
│   ├── swagger.json            # OpenAPI JSON spec
│   └── swagger.yaml            # OpenAPI YAML spec
├── scripts/                    # Lua scanning scripts
│   ├── basic_info.lua          # Basic asset information
│   ├── http_probe.lua          # HTTP service probing
│   ├── banner_grab.lua         # TCP banner grabbing
│   └── http_title.lua          # HTTP title extraction
├── data/                       # Runtime data storage
│   ├── assets.json             # Asset catalogue
│   ├── jobs.json               # Background jobs
│   ├── scan_results.json       # Scan results
│   ├── checklist_templates.json # Checklist templates
│   └── checklist_statuses.json  # Checklist status data
├── build/                      # Build artifacts
├── go.mod                      # Go module definition
├── go.sum                      # Go module checksums
├── Makefile                    # Build automation
├── Dockerfile                  # Docker container definition
└── docker-compose.yml          # Docker compose configuration
```

## Go Project Structure Patterns

### 1. Layered Architecture
```
Handler Layer (HTTP) → Service Layer (Business Logic) → Storage Layer (Data)
```

### 2. Dependency Injection
```go
// main.go - Dependency injection pattern
func main() {
    // Storage layer
    storage := storage.NewJSONStorage(storageConfig)
    
    // Service layer
    checklistService := service.NewSimpleChecklistService(storage)
    
    // Handler layer
    checklistHandler := handler.NewSimpleChecklistHandler(checklistService)
    
    // Route registration
    apiV1.GET("/checklist/templates", checklistHandler.ListTemplates)
}
```

### 3. Interface-Based Design
```go
// Storage interface allows multiple implementations
type Storage interface {
    CreateAsset(ctx context.Context, asset *model.Asset) error
    GetAsset(ctx context.Context, id string) (*model.Asset, error)
    // ... other methods
}

// JSON implementation
type JSONStorage struct {
    // implementation details
}

func (s *JSONStorage) CreateAsset(ctx context.Context, asset *model.Asset) error {
    // JSON-specific implementation
}
```

## Key Components Deep Dive

### 1. Models (`internal/model/`)

#### Asset Models (`asset.go`)
```go
// Core asset structure
type Asset struct {
    ID            string                 `json:"id"`
    Type          string                 `json:"type"` // domain, subdomain, ip, service
    Value         string                 `json:"value"`
    DiscoveredAt  time.Time              `json:"discovered_at"`
    LastScannedAt *time.Time             `json:"last_scanned_at,omitempty"`
    ScanCount     int                    `json:"scan_count"`
    Status        string                 `json:"status"`
    Properties    map[string]interface{} `json:"properties,omitempty"`
    ScanResults   []ScanResult           `json:"scan_results,omitempty"`
}

// Scan result from Lua scripts
type ScanResult struct {
    ID         string                 `json:"id"`
    ScriptName string                 `json:"script_name"`
    ExecutedAt time.Time              `json:"executed_at"`
    Success    bool                   `json:"success"`
    Output     []string               `json:"output,omitempty"`
    Error      string                 `json:"error,omitempty"`
    Duration   string                 `json:"duration"`
    Metadata   map[string]interface{} `json:"metadata,omitempty"`
    Decision   string                 `json:"decision"` // pass, reject, na
}

// Background job tracking
type Job struct {
    ID          string      `json:"id"`
    Type        string      `json:"type"` // discover, scan
    Status      string      `json:"status"` // pending, running, completed, failed
    StartedAt   time.Time   `json:"started_at"`
    CompletedAt *time.Time  `json:"completed_at,omitempty"`
    Progress    JobProgress `json:"progress"`
    Error       string      `json:"error,omitempty"`
    Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// Lua script metadata
type Script struct {
    Name           string   `json:"name"`
    Title          string   `json:"title"`
    Description    string   `json:"description,omitempty"`
    Category       string   `json:"category,omitempty"`
    Author         string   `json:"author,omitempty"`
    Version        string   `json:"version,omitempty"`
    AssetTypes     []string `json:"asset_types,omitempty"`
    RequiresPassed []string `json:"requires_passed,omitempty"` // Conditional execution
}
```

#### Checklist Models (`simple_checklist.go`)
```go
// Simplified checklist status storage
type SimpleChecklistStatus struct {
    Key       string    `json:"key"`        // Format: "global:{itemId}" or "asset:{assetId}:{itemId}"
    Status    string    `json:"status"`     // "yes", "no", "na"
    Notes     string    `json:"notes,omitempty"`
    UpdatedAt time.Time `json:"updated_at"`
}

// Helper functions for key generation
func GlobalChecklistKey(itemId string) string {
    return "global:" + itemId
}

func AssetChecklistKey(assetId, itemId string) string {
    return "asset:" + assetId + ":" + itemId
}
```

### 2. Handlers (`internal/handler/`)

#### Handler Pattern
```go
// Handler struct with dependencies
type SimpleChecklistHandler struct {
    checklistService *service.SimpleChecklistService
}

// Constructor with dependency injection
func NewSimpleChecklistHandler(checklistService *service.SimpleChecklistService) *SimpleChecklistHandler {
    return &SimpleChecklistHandler{
        checklistService: checklistService,
    }
}

// HTTP handler method with Swagger documentation
// @Summary Get global checklist items
// @Description Retrieve all global checklist items with their current status
// @Tags checklist
// @Accept json
// @Produce json
// @Success 200 {array} model.DerivedChecklistItem
// @Failure 500 {object} v1.ErrorResponse
// @Router /checklist/global [get]
func (h *SimpleChecklistHandler) GetGlobalChecklist(c echo.Context) error {
    items, err := h.checklistService.GetGlobalChecklist(c.Request().Context())
    if err != nil {
        return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
            Error:   "Failed to get global checklist",
            Code:    http.StatusInternalServerError,
            Details: map[string]string{"error": err.Error()},
        })
    }

    return c.JSON(http.StatusOK, items)
}
```

#### Error Handling Pattern
```go
// Consistent error response structure
type ErrorResponse struct {
    Error   string            `json:"error"`
    Code    int               `json:"code"`
    Details map[string]string `json:"details,omitempty"`
}

// Usage in handlers
if err != nil {
    return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
        Error:   "Operation failed",
        Code:    http.StatusInternalServerError,
        Details: map[string]string{"error": err.Error()},
    })
}
```

### 3. Services (`internal/service/`)

#### Service Layer Pattern
```go
type SimpleChecklistService struct {
    storage storage.Storage
}

func NewSimpleChecklistService(storage storage.Storage) *SimpleChecklistService {
    return &SimpleChecklistService{
        storage: storage,
    }
}

// Business logic method
func (s *SimpleChecklistService) GetGlobalChecklist(ctx context.Context) ([]*model.DerivedChecklistItem, error) {
    // Get templates
    templates, err := s.storage.ListChecklistTemplates(ctx)
    if err != nil {
        return nil, fmt.Errorf("failed to get checklist templates: %w", err)
    }

    // Get statuses
    statuses, err := s.storage.ListChecklistStatuses(ctx)
    if err != nil {
        return nil, fmt.Errorf("failed to get checklist statuses: %w", err)
    }

    // Business logic to combine templates and statuses
    var globalItems []*model.DerivedChecklistItem
    for _, template := range templates {
        if template.Scope == model.ChecklistScopeGlobal {
            derived := &model.DerivedChecklistItem{
                ChecklistItemTemplate: *template,
                Status:                model.ChecklistStatusNA,
                Source:                model.ChecklistSourceManual,
            }

            // Apply status if exists
            key := model.GlobalChecklistKey(template.ID)
            if status, exists := statuses[key]; exists {
                derived.Status = status.Status
                derived.Notes = status.Notes
                derived.UpdatedAt = &status.UpdatedAt
            }

            globalItems = append(globalItems, derived)
        }
    }

    // Ensure deterministic ordering
    sort.Slice(globalItems, func(i, j int) bool {
        return globalItems[i].ID < globalItems[j].ID
    })

    return globalItems, nil
}
```

### 4. Storage Layer (`internal/storage/`)

#### Storage Interface
```go
type Storage interface {
    // Asset operations
    CreateAsset(ctx context.Context, asset *model.Asset) error
    GetAsset(ctx context.Context, id string) (*model.Asset, error)
    UpdateAsset(ctx context.Context, asset *model.Asset) error
    DeleteAsset(ctx context.Context, id string) error
    ListAssets(ctx context.Context, filters map[string]string) ([]*model.Asset, error)
    
    // Checklist operations
    CreateChecklistTemplate(ctx context.Context, template *model.ChecklistItemTemplate) error
    GetChecklistTemplate(ctx context.Context, id string) (*model.ChecklistItemTemplate, error)
    ListChecklistTemplates(ctx context.Context) ([]*model.ChecklistItemTemplate, error)
    
    // Simple checklist status operations
    SetChecklistStatus(ctx context.Context, key string, status *model.SimpleChecklistStatus) error
    GetChecklistStatus(ctx context.Context, key string) (*model.SimpleChecklistStatus, error)
    ListChecklistStatuses(ctx context.Context) (map[string]*model.SimpleChecklistStatus, error)
    
    // Utility operations
    Close() error
    Backup() error
}
```

#### JSON Storage Implementation
```go
type JSONStorage struct {
    config               *config.StorageConfig
    mu                   sync.RWMutex
    assets               map[string]*model.Asset
    jobs                 map[string]*model.Job
    scanResults          map[string]*model.ScanResult
    checklistTemplates   map[string]*model.ChecklistItemTemplate
    checklistStatuses    map[string]*model.SimpleChecklistStatus
}

func (s *JSONStorage) CreateAsset(ctx context.Context, asset *model.Asset) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if _, exists := s.assets[asset.ID]; exists {
        return errors.NewConflict(fmt.Sprintf("Asset with ID %s already exists", asset.ID))
    }

    s.assets[asset.ID] = asset
    return s.saveAssets()
}

// Thread-safe file operations
func (s *JSONStorage) saveAssets() error {
    filePath := filepath.Join(s.config.DataDir, s.config.AssetsFile)
    return s.saveJSONFile(filePath, s.assets)
}

func (s *JSONStorage) saveJSONFile(filePath string, data interface{}) error {
    jsonData, err := json.MarshalIndent(data, "", "  ")
    if err != nil {
        return fmt.Errorf("failed to marshal JSON: %w", err)
    }

    return os.WriteFile(filePath, jsonData, 0644)
}
```

### 5. Lua Scripting Engine (`internal/scanner/`)

#### Lua Scanner Core
```go
type LuaScanner struct {
    scripts    map[string]*model.Script
    scriptsMu  sync.RWMutex
    scriptsDir string
}

// Execute Lua script on asset
func (ls *LuaScanner) ExecuteScript(ctx context.Context, asset *model.Asset, scriptName string) (*model.ScanResult, error) {
    script := ls.getScript(scriptName)
    if script == nil {
        return nil, fmt.Errorf("script %s not found", scriptName)
    }

    // Check if asset type is supported
    if !ls.scriptSupportsAssetType(script, asset.Type) {
        return nil, fmt.Errorf("script %s does not support asset type %s", scriptName, asset.Type)
    }

    startTime := time.Now()
    result := &model.ScanResult{
        ID:         util.GenerateID(),
        ScriptName: scriptName,
        ExecutedAt: startTime,
        Success:    false,
        Output:     []string{},
        Metadata:   make(map[string]interface{}),
        Decision:   "na", // Default decision
    }

    // Execute Lua script
    L := lua.NewState()
    defer L.Close()

    // Register Lua functions
    ls.registerLuaFunctions(L, asset, result)
    ls.registerLuaNet(L)    // TCP networking
    ls.registerLuaHTTP(L)   // HTTP client

    // Load and execute script
    if err := L.DoFile(filepath.Join(ls.scriptsDir, scriptName)); err != nil {
        result.Error = err.Error()
        result.Duration = time.Since(startTime).String()
        return result, nil
    }

    result.Success = true
    result.Duration = time.Since(startTime).String()
    return result, nil
}

// Register Lua functions
func (ls *LuaScanner) registerLuaFunctions(L *lua.LState, asset *model.Asset, result *model.ScanResult) {
    // Asset information
    L.SetGlobal("asset_id", lua.LString(asset.ID))
    L.SetGlobal("asset_type", lua.LString(asset.Type))
    L.SetGlobal("asset_value", lua.LString(asset.Value))

    // Output function
    L.SetGlobal("output", L.NewFunction(func(L *lua.LState) int {
        msg := L.ToString(1)
        result.Output = append(result.Output, msg)
        return 0
    }))

    // Metadata function
    L.SetGlobal("set_metadata", L.NewFunction(func(L *lua.LState) int {
        key := L.ToString(1)
        value := L.Get(2)
        
        var goValue interface{}
        switch value.Type() {
        case lua.LTString:
            goValue = lua.LVAsString(value)
        case lua.LTNumber:
            goValue = lua.LVAsNumber(value)
        case lua.LTBool:
            goValue = lua.LVAsBool(value)
        default:
            goValue = value.String()
        }
        
        result.Metadata[key] = goValue
        
        // Log metadata setting for debugging
        log.Printf("Script %s set metadata for asset %s: %s = %v", 
            result.ScriptName, asset.ID, key, goValue)
        
        return 0
    }))

    // Decision functions
    L.SetGlobal("pass", L.NewFunction(func(L *lua.LState) int {
        result.Decision = "pass"
        return 0
    }))

    L.SetGlobal("reject", L.NewFunction(func(L *lua.LState) int {
        reason := L.ToString(1)
        result.Decision = "reject"
        if reason != "" {
            result.Output = append(result.Output, "Rejected: "+reason)
        }
        return 0
    }))
}
```

#### Lua Networking Libraries

##### TCP Library (`lua_netlib.go`)
```go
func (ls *LuaScanner) registerLuaNet(L *lua.LState) {
    netTable := L.NewTable()
    
    // tcp.connect(host, port, timeout_sec?)
    netTable.RawSetString("connect", L.NewFunction(func(L *lua.LState) int {
        host := L.ToString(1)
        port := L.ToInt(2)
        timeoutSec := L.OptInt(3, 10)
        
        conn, err := net.DialTimeout("tcp", 
            fmt.Sprintf("%s:%d", host, port), 
            time.Duration(timeoutSec)*time.Second)
        if err != nil {
            L.Push(lua.LNil)
            L.Push(lua.LString(err.Error()))
            return 2
        }
        
        // Store connection with unique ID
        fd := ls.storeConnection(conn)
        L.Push(lua.LNumber(fd))
        L.Push(lua.LNil)
        return 2
    }))
    
    // tcp.send(fd, data)
    netTable.RawSetString("send", L.NewFunction(func(L *lua.LState) int {
        // Implementation for sending data
    }))
    
    L.SetGlobal("tcp", netTable)
}
```

##### HTTP Library (`lua_httplib.go`)
```go
func (ls *LuaScanner) registerLuaHTTP(L *lua.LState) {
    httpTable := L.NewTable()
    
    // http.get(url, headers?, timeout_sec?)
    httpTable.RawSetString("get", L.NewFunction(func(L *lua.LState) int {
        url := L.ToString(1)
        headers := L.OptTable(2, L.NewTable())
        timeoutSec := L.OptInt(3, 30)
        
        client := &http.Client{
            Timeout: time.Duration(timeoutSec) * time.Second,
        }
        
        req, err := http.NewRequest("GET", url, nil)
        if err != nil {
            L.Push(lua.LNil)
            L.Push(lua.LString(err.Error()))
            return 2
        }
        
        // Add headers from Lua table
        headers.ForEach(func(k, v lua.LValue) {
            req.Header.Set(k.String(), v.String())
        })
        
        resp, err := client.Do(req)
        if err != nil {
            L.Push(lua.LNil)
            L.Push(lua.LString(err.Error()))
            return 2
        }
        defer resp.Body.Close()
        
        // Create response table
        respTable := L.NewTable()
        respTable.RawSetString("status_code", lua.LNumber(resp.StatusCode))
        respTable.RawSetString("status", lua.LString(resp.Status))
        
        // Read body
        body, err := io.ReadAll(resp.Body)
        if err != nil {
            respTable.RawSetString("body", lua.LString(""))
        } else {
            respTable.RawSetString("body", lua.LString(string(body)))
        }
        
        // Add headers
        headersTable := L.NewTable()
        for key, values := range resp.Header {
            if len(values) > 0 {
                headersTable.RawSetString(key, lua.LString(values[0]))
            }
        }
        respTable.RawSetString("headers", headersTable)
        
        L.Push(respTable)
        L.Push(lua.LNil)
        return 2
    }))
    
    L.SetGlobal("http", httpTable)
}
```

### 6. Lua Script Examples

#### Basic Info Script (`scripts/basic_info.lua`)
```lua
-- @title Basic Asset Information
-- @description Collects basic information about the asset
-- @category Information Gathering
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types domain,subdomain,ip,service

output("Collecting basic information for " .. asset_type .. ": " .. asset_value)

-- Set basic metadata
set_metadata("asset_type", asset_type)
set_metadata("asset_value", asset_value)
set_metadata("scanned_at", os.date("%Y-%m-%d %H:%M:%S"))

if asset_type == "domain" or asset_type == "subdomain" then
    set_metadata("domain_length", string.len(asset_value))
    output("Domain/subdomain length: " .. string.len(asset_value))
elseif asset_type == "ip" then
    set_metadata("ip_version", string.find(asset_value, ":") and "ipv6" or "ipv4")
    output("IP version: " .. (string.find(asset_value, ":") and "IPv6" or "IPv4"))
elseif asset_type == "service" then
    local host, port = string.match(asset_value, "([^:]+):(%d+)")
    if host and port then
        set_metadata("service_host", host)
        set_metadata("service_port", tonumber(port))
        output("Service host: " .. host .. ", port: " .. port)
    end
end

-- Mark as passed (informational script always passes)
pass()
```

#### HTTP Probe Script (`scripts/http_probe.lua`)
```lua
-- @title HTTP Service Probe
-- @description Probes HTTP services to check availability and gather basic information
-- @category Web Security
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed basic_info

-- Only run on service assets
if asset_type ~= "service" then
    output("Skipping HTTP probe - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset_value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    output("Could not parse service format: " .. asset_value)
    reject("Invalid service format")
    return
end

-- Only probe HTTP-like services
port = tonumber(port)
if port ~= 80 and port ~= 443 and port ~= 8080 and port ~= 8443 then
    output("Skipping non-HTTP port: " .. port)
    return
end

-- Determine URL scheme
local scheme = (port == 443 or port == 8443) and "https" or "http"
local url = scheme .. "://" .. host .. ":" .. port

output("Probing HTTP service: " .. url)

-- Make HTTP request
local response, err = http.get(url, {["User-Agent"] = "RegTech-Scanner/1.0"}, 10)

if err then
    output("HTTP probe failed: " .. err)
    set_metadata("http.error", err)
    reject("HTTP probe failed")
    return
end

-- Process response
set_metadata("http.status_code", response.status_code)
set_metadata("http.status", response.status)
set_metadata("http.response_size", string.len(response.body))

output("HTTP Status: " .. response.status)
output("Response size: " .. string.len(response.body) .. " bytes")

-- Extract title if HTML
local title = string.match(response.body, "<title[^>]*>([^<]+)</title>")
if title then
    set_metadata("http.title", title)
    output("Page title: " .. title)
end

-- Check for common security headers
local security_headers = {}
if response.headers["Strict-Transport-Security"] then
    security_headers.hsts = response.headers["Strict-Transport-Security"]
end
if response.headers["Content-Security-Policy"] then
    security_headers.csp = response.headers["Content-Security-Policy"]
end
if response.headers["X-Frame-Options"] then
    security_headers.x_frame_options = response.headers["X-Frame-Options"]
end

if next(security_headers) then
    set_metadata("http.security_headers", security_headers)
    output("Found security headers: " .. table.concat(security_headers, ", "))
end

-- Success criteria
if response.status_code >= 200 and response.status_code < 400 then
    pass()
else
    reject("HTTP service returned error status: " .. response.status)
end
```

## API Documentation with Swagger

### Swagger Comments Pattern
```go
// @Summary Short description
// @Description Detailed description
// @Tags tag-name
// @Accept json
// @Produce json
// @Param paramName path string true "Parameter description"
// @Param request body RequestType true "Request body description"
// @Success 200 {object} ResponseType
// @Success 201 {object} ResponseType
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /endpoint/path [method]
func (h *Handler) EndpointMethod(c echo.Context) error {
    // Implementation
}
```

### API Types (`api/v1/types.go`)
```go
// Request/Response structures for API endpoints
type DiscoverAssetsRequest struct {
    Hosts []string `json:"hosts" binding:"required" example:"example.com,192.168.1.1"`
}

type AssetCatalogueResponse struct {
    Assets []AssetSummary `json:"assets" binding:"required"`
    Total  int            `json:"total" binding:"required"`
}

type ErrorResponse struct {
    Error   string            `json:"error" binding:"required"`
    Code    int               `json:"code" binding:"required"`
    Details map[string]string `json:"details,omitempty"`
}
```

## Configuration Management

### Config Structure (`internal/config/config.go`)
```go
type Config struct {
    Server   ServerConfig   `yaml:"server"`
    Storage  StorageConfig  `yaml:"storage"`
    Recontool RecontoolConfig `yaml:"recontool"`
    Lua      LuaConfig      `yaml:"lua"`
}

type ServerConfig struct {
    Host         string        `yaml:"host" env:"SERVER_HOST" env-default:"0.0.0.0"`
    Port         int           `yaml:"port" env:"SERVER_PORT" env-default:"8080"`
    ReadTimeout  time.Duration `yaml:"read_timeout" env-default:"30s"`
    WriteTimeout time.Duration `yaml:"write_timeout" env-default:"30s"`
}

// Load configuration from environment and files
func LoadConfig() (*Config, error) {
    cfg := &Config{}
    
    // Load from environment variables
    if err := cleanenv.ReadEnv(cfg); err != nil {
        return nil, fmt.Errorf("failed to read config from environment: %w", err)
    }
    
    return cfg, nil
}
```

## Development Patterns

### 1. Adding a New API Endpoint

#### Step 1: Define Models
```go
// internal/model/newfeature.go
type NewFeature struct {
    ID          string    `json:"id"`
    Name        string    `json:"name"`
    Description string    `json:"description"`
    CreatedAt   time.Time `json:"created_at"`
}
```

#### Step 2: Add Storage Interface
```go
// internal/storage/storage.go
type Storage interface {
    // ... existing methods
    CreateNewFeature(ctx context.Context, feature *model.NewFeature) error
    GetNewFeature(ctx context.Context, id string) (*model.NewFeature, error)
    ListNewFeatures(ctx context.Context) ([]*model.NewFeature, error)
}
```

#### Step 3: Implement Storage
```go
// internal/storage/json_storage.go
func (s *JSONStorage) CreateNewFeature(ctx context.Context, feature *model.NewFeature) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if _, exists := s.newFeatures[feature.ID]; exists {
        return errors.NewConflict(fmt.Sprintf("Feature with ID %s already exists", feature.ID))
    }

    s.newFeatures[feature.ID] = feature
    return s.saveNewFeatures()
}
```

#### Step 4: Create Service
```go
// internal/service/newfeature.go
type NewFeatureService struct {
    storage storage.Storage
}

func NewNewFeatureService(storage storage.Storage) *NewFeatureService {
    return &NewFeatureService{storage: storage}
}

func (s *NewFeatureService) CreateFeature(ctx context.Context, name, description string) (*model.NewFeature, error) {
    feature := &model.NewFeature{
        ID:          util.GenerateID(),
        Name:        name,
        Description: description,
        CreatedAt:   time.Now(),
    }

    if err := s.storage.CreateNewFeature(ctx, feature); err != nil {
        return nil, fmt.Errorf("failed to create feature: %w", err)
    }

    return feature, nil
}
```

#### Step 5: Create Handler
```go
// internal/handler/newfeature.go
type NewFeatureHandler struct {
    service *service.NewFeatureService
}

func NewNewFeatureHandler(service *service.NewFeatureService) *NewFeatureHandler {
    return &NewFeatureHandler{service: service}
}

// @Summary Create new feature
// @Description Create a new feature with name and description
// @Tags features
// @Accept json
// @Produce json
// @Param request body CreateFeatureRequest true "Feature creation request"
// @Success 201 {object} model.NewFeature
// @Failure 400 {object} v1.ErrorResponse
// @Failure 500 {object} v1.ErrorResponse
// @Router /features [post]
func (h *NewFeatureHandler) CreateFeature(c echo.Context) error {
    var req CreateFeatureRequest
    if err := c.Bind(&req); err != nil {
        return c.JSON(http.StatusBadRequest, v1.ErrorResponse{
            Error:   "Invalid request body",
            Code:    http.StatusBadRequest,
            Details: map[string]string{"error": err.Error()},
        })
    }

    feature, err := h.service.CreateFeature(c.Request().Context(), req.Name, req.Description)
    if err != nil {
        return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
            Error:   "Failed to create feature",
            Code:    http.StatusInternalServerError,
            Details: map[string]string{"error": err.Error()},
        })
    }

    return c.JSON(http.StatusCreated, feature)
}

type CreateFeatureRequest struct {
    Name        string `json:"name" example:"Feature Name"`
    Description string `json:"description" example:"Feature description"`
}
```

#### Step 6: Register Routes
```go
// cmd/scanner/main.go
func main() {
    // ... existing setup
    
    // Initialize service and handler
    newFeatureService := service.NewNewFeatureService(store)
    newFeatureHandler := handler.NewNewFeatureHandler(newFeatureService)
    
    // Register routes
    apiV1.POST("/features", newFeatureHandler.CreateFeature)
    apiV1.GET("/features", newFeatureHandler.ListFeatures)
    apiV1.GET("/features/:id", newFeatureHandler.GetFeature)
}
```

### 2. Adding a New Lua Script

#### Script Structure
```lua
-- Metadata comments (parsed by Go scanner)
-- @title Script Title
-- @description Detailed description of what the script does
-- @category Category Name
-- @author Author Name
-- @version 1.0
-- @asset_types domain,subdomain,ip,service
-- @requires_passed script1,script2  # Optional: only run if these scripts passed

-- Script logic
output("Starting script execution for " .. asset_type .. ": " .. asset_value)

-- Conditional logic based on asset type
if asset_type == "service" then
    local host, port = string.match(asset_value, "([^:]+):(%d+)")
    if host and port then
        -- Service-specific logic
        local response, err = http.get("http://" .. host .. ":" .. port)
        if response and response.status_code == 200 then
            set_metadata("http.accessible", true)
            pass()
        else
            reject("Service not accessible")
        end
    else
        reject("Invalid service format")
    end
elseif asset_type == "domain" then
    -- Domain-specific logic
    set_metadata("domain_length", string.len(asset_value))
    pass()
else
    -- Not applicable to this asset type
    output("Script not applicable to asset type: " .. asset_type)
end
```

#### Available Lua Functions
```lua
-- Asset information (global variables)
asset_id     -- Asset ID
asset_type   -- Asset type (domain, subdomain, ip, service)
asset_value  -- Asset value

-- Output functions
output(message)                    -- Add message to scan output
set_metadata(key, value)          -- Set metadata key-value pair

-- Decision functions
pass()                            -- Mark script as passed
reject(reason)                    -- Mark script as rejected with reason
-- (no call = not applicable)

-- Networking functions
-- TCP
local fd, err = tcp.connect(host, port, timeout_sec)
local bytes_sent, err = tcp.send(fd, data)
local data, err = tcp.recv(fd, max_bytes, timeout_sec)
tcp.close(fd)

-- HTTP
local response, err = http.get(url, headers_table, timeout_sec)
local response, err = http.post(url, body, headers_table, timeout_sec)
local response, err = http.request(method, url, body, headers_table, timeout_sec)

-- Response structure:
-- response.status_code  -- HTTP status code
-- response.status       -- HTTP status text
-- response.body         -- Response body
-- response.headers      -- Headers table
```

### 3. Error Handling Patterns

#### Custom Error Types
```go
// internal/errors/errors.go
type AppError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
    Err     error  `json:"-"`
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

func NewBadRequest(message string, err error) *AppError {
    return &AppError{
        Code:    http.StatusBadRequest,
        Message: message,
        Err:     err,
    }
}

func NewNotFound(resource string) *AppError {
    return &AppError{
        Code:    http.StatusNotFound,
        Message: fmt.Sprintf("%s not found", resource),
    }
}
```

#### Error Middleware
```go
// internal/middleware/error_handler.go
func ErrorHandler() echo.MiddlewareFunc {
    return func(next echo.HandlerFunc) echo.HandlerFunc {
        return func(c echo.Context) error {
            err := next(c)
            if err != nil {
                var appErr *errors.AppError
                if errors.As(err, &appErr) {
                    return c.JSON(appErr.Code, v1.ErrorResponse{
                        Error:   appErr.Message,
                        Code:    appErr.Code,
                        Details: map[string]string{"error": appErr.Error()},
                    })
                }

                // Default error handling
                return c.JSON(http.StatusInternalServerError, v1.ErrorResponse{
                    Error:   "Internal server error",
                    Code:    http.StatusInternalServerError,
                    Details: map[string]string{"error": err.Error()},
                })
            }
            return nil
        }
    }
}
```

## Testing Patterns

### Unit Testing
```go
// internal/service/newfeature_test.go
func TestNewFeatureService_CreateFeature(t *testing.T) {
    // Setup
    storage := &mockStorage{}
    service := NewNewFeatureService(storage)
    
    // Test
    feature, err := service.CreateFeature(context.Background(), "Test Feature", "Description")
    
    // Assertions
    assert.NoError(t, err)
    assert.NotNil(t, feature)
    assert.Equal(t, "Test Feature", feature.Name)
    assert.NotEmpty(t, feature.ID)
}

type mockStorage struct{}

func (m *mockStorage) CreateNewFeature(ctx context.Context, feature *model.NewFeature) error {
    return nil
}
```

### Integration Testing
```go
// Test with real HTTP server
func TestNewFeatureHandler_CreateFeature(t *testing.T) {
    // Setup Echo server
    e := echo.New()
    storage := storage.NewJSONStorage(&config.StorageConfig{DataDir: "/tmp/test"})
    service := service.NewNewFeatureService(storage)
    handler := handler.NewNewFeatureHandler(service)
    
    e.POST("/features", handler.CreateFeature)
    
    // Test request
    req := httptest.NewRequest(http.MethodPost, "/features", 
        strings.NewReader(`{"name":"Test","description":"Test desc"}`))
    req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
    rec := httptest.NewRecorder()
    
    e.ServeHTTP(rec, req)
    
    // Assertions
    assert.Equal(t, http.StatusCreated, rec.Code)
}
```

## Build and Deployment

### Makefile
```makefile
# Build targets
.PHONY: build clean test run

build:
	go build -o build/scanner ./cmd/scanner

clean:
	rm -rf build/

test:
	go test ./...

run: build
	./build/scanner

# Docker targets
docker-build:
	docker build -t regtech-scanner .

docker-run:
	docker-compose up -d

# Documentation
docs:
	swag init -g cmd/scanner/main.go -o docs
```

### Docker Configuration
```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o scanner ./cmd/scanner

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/scanner .
COPY --from=builder /app/scripts ./scripts

EXPOSE 8080
CMD ["./scanner"]
```

## Performance Considerations

### 1. Concurrency Patterns
```go
// Background job processing
func (h *AssetsHandler) processDiscoveryJob(ctx context.Context, hosts []string, jobID string) {
    go func() {
        defer func() {
            if r := recover(); r != nil {
                log.Printf("Discovery job %s panicked: %v", jobID, r)
            }
        }()
        
        // Process hosts concurrently
        var wg sync.WaitGroup
        semaphore := make(chan struct{}, 10) // Limit concurrent operations
        
        for _, host := range hosts {
            wg.Add(1)
            go func(host string) {
                defer wg.Done()
                semaphore <- struct{}{}        // Acquire
                defer func() { <-semaphore }() // Release
                
                // Process single host
                h.processHost(ctx, host)
            }(host)
        }
        
        wg.Wait()
        // Update job status
        h.updateJobStatus(jobID, "completed")
    }()
}
```

### 2. Memory Management
```go
// Efficient JSON handling for large datasets
func (s *JSONStorage) loadLargeDataset() error {
    file, err := os.Open(s.dataFile)
    if err != nil {
        return err
    }
    defer file.Close()
    
    decoder := json.NewDecoder(file)
    
    // Stream processing for large files
    for decoder.More() {
        var item DataItem
        if err := decoder.Decode(&item); err != nil {
            return err
        }
        
        // Process item without loading entire file into memory
        s.processItem(&item)
    }
    
    return nil
}
```

### 3. Database Connection Pooling (Future)
```go
// Pattern for when migrating from JSON to database
type DatabaseStorage struct {
    db   *sql.DB
    pool *sql.DB
}

func NewDatabaseStorage(dsn string) (*DatabaseStorage, error) {
    db, err := sql.Open("postgres", dsn)
    if err != nil {
        return nil, err
    }
    
    // Configure connection pool
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    db.SetConnMaxLifetime(5 * time.Minute)
    
    return &DatabaseStorage{db: db}, nil
}
```

## Security Considerations

### 1. Input Validation
```go
// Validate and sanitize inputs
func validateAssetValue(assetType, value string) error {
    switch assetType {
    case "domain", "subdomain":
        if !isValidDomain(value) {
            return errors.NewBadRequest("Invalid domain format", nil)
        }
    case "ip":
        if net.ParseIP(value) == nil {
            return errors.NewBadRequest("Invalid IP address format", nil)
        }
    case "service":
        if !isValidServiceFormat(value) {
            return errors.NewBadRequest("Invalid service format", nil)
        }
    default:
        return errors.NewBadRequest("Invalid asset type", nil)
    }
    return nil
}
```

### 2. Rate Limiting
```go
// Rate limiting middleware
func RateLimitMiddleware() echo.MiddlewareFunc {
    limiter := rate.NewLimiter(rate.Every(time.Second), 100) // 100 requests per second
    
    return func(next echo.HandlerFunc) echo.HandlerFunc {
        return func(c echo.Context) error {
            if !limiter.Allow() {
                return c.JSON(http.StatusTooManyRequests, v1.ErrorResponse{
                    Error: "Rate limit exceeded",
                    Code:  http.StatusTooManyRequests,
                })
            }
            return next(c)
        }
    }
}
```

### 3. Lua Script Security
```go
// Secure Lua execution with timeouts and limits
func (ls *LuaScanner) executeScriptSafely(script string, timeout time.Duration) error {
    L := lua.NewState()
    defer L.Close()
    
    // Set instruction limit to prevent infinite loops
    L.SetMx(1000000) // 1M instructions max
    
    // Execute with timeout
    done := make(chan error, 1)
    go func() {
        done <- L.DoString(script)
    }()
    
    select {
    case err := <-done:
        return err
    case <-time.After(timeout):
        return fmt.Errorf("script execution timeout")
    }
}
```

## Monitoring and Logging

### Structured Logging
```go
import "github.com/sirupsen/logrus"

// Setup structured logging
func setupLogging() {
    logrus.SetFormatter(&logrus.JSONFormatter{})
    logrus.SetLevel(logrus.InfoLevel)
}

// Usage in handlers
func (h *Handler) SomeEndpoint(c echo.Context) error {
    logger := logrus.WithFields(logrus.Fields{
        "endpoint": "some_endpoint",
        "method":   c.Request().Method,
        "ip":       c.RealIP(),
    })
    
    logger.Info("Processing request")
    
    // ... handler logic
    
    logger.WithField("duration", time.Since(start)).Info("Request completed")
    return nil
}
```

## Key Files to Understand

1. **`cmd/scanner/main.go`** - Application entry point, dependency injection, route registration
2. **`internal/model/asset.go`** - Core data models for assets, jobs, scan results
3. **`internal/storage/json_storage.go`** - Data persistence implementation
4. **`internal/scanner/lua_scanner.go`** - Lua scripting engine core
5. **`internal/handler/assets.go`** - Asset management HTTP handlers
6. **`internal/handler/simple_checklist.go`** - Compliance checklist HTTP handlers
7. **`api/v1/types.go`** - API request/response type definitions
8. **`scripts/`** - Example Lua scanning scripts

This guide provides a comprehensive understanding of the backendnew Go project structure and development patterns for AI agents working on this codebase.
