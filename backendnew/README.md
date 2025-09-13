# Asset Scanner Backend

A production-ready Go backend for asset discovery and scanning with Lua scripting support. This backend includes integrated reconnaissance capabilities for asset discovery and provides a comprehensive API for managing and scanning network assets.

## 🚀 Features

- **Asset Discovery**: Integrated reconnaissance service for comprehensive asset discovery
- **Lua Scripting**: Extensible scanning with custom Lua scripts
- **RESTful API**: Clean, versioned API following production best practices
- **JSON Storage**: File-based storage with automatic backups
- **Background Jobs**: Asynchronous processing of discovery and scanning tasks
- **Health Monitoring**: Built-in health checks and metrics
- **Docker Support**: Container-ready with multi-stage builds
- **Swagger Documentation**: Auto-generated API documentation

## 📁 Project Structure

```
backendnew/
├── api/v1/                     # API types and contracts
├── cmd/scanner/                # Application entry point
├── internal/                   # Private application code
│   ├── config/                 # Configuration management
│   ├── errors/                 # Custom error handling
│   ├── handler/                # HTTP request handlers
│   ├── middleware/             # HTTP middleware
│   ├── model/                  # Domain models
│   ├── scanner/                # Lua script execution
│   ├── storage/                # JSON file storage
│   └── util/                   # Utility functions
├── scripts/                    # Lua scanning scripts
├── data/                       # JSON data files
├── docs/                       # Swagger documentation
├── Dockerfile                  # Container configuration
├── docker-compose.yml          # Docker Compose setup
├── Makefile                    # Build automation
└── README.md                   # This file
```

## 🛠 Quick Start

### Prerequisites

- Go 1.24.1 or later
- Make (optional, for build automation)
- Docker (optional, for containerized deployment)
- Nmap (for port scanning, optional)

### 1. Development Setup

```bash
# Clone and setup
cd backendnew
make dev-setup

# Start development server
make dev
```

### 2. Production Build

```bash
# Build optimized binary
make build-prod

# Create release archive
make release
```

### 3. Docker Deployment

```bash
# Build and run with Docker
make docker-run

# Or use Docker Compose
docker-compose up -d
```

## 📚 API Endpoints

### Asset Discovery
- `POST /api/v1/assets/discover` - Start asset discovery for hosts
- `GET /api/v1/assets/catalogue` - Get all discovered assets
- `GET /api/v1/assets/{id}` - Get detailed asset information

### Asset Scanning
- `POST /api/v1/assets/{id}/scan` - Scan specific asset
- `POST /api/v1/assets/scan` - Scan all assets

### Job Management
- `GET /api/v1/jobs/{id}` - Get job status and progress

### Utilities
- `GET /health` - Health check endpoint
- `GET /api/v1/scripts` - List available Lua scripts
- `POST /api/v1/scripts/reload` - Reload scripts from disk
- `GET /api/v1/stats` - Storage statistics
- `GET /swagger/*` - API documentation

## 🔧 Configuration

Configuration is managed through environment variables. Copy `.env.example` to `.env` and customize:

```bash
# Server
SERVER_PORT=8080
SERVER_HOST=0.0.0.0

# Storage
STORAGE_DATA_DIR=./data
STORAGE_BACKUP_ENABLED=true

# Scanner
SCANNER_SCRIPTS_DIR=./scripts
SCANNER_MAX_CONCURRENT=10

# Recontool Integration
# RECONTOOL_BINARY_PATH is no longer needed - functionality is integrated
RECONTOOL_ENABLE_SUDO=true
```

### Configuration Sections

- **Server**: HTTP server settings, CORS, timeouts
- **Storage**: File paths, backup settings
- **Scanner**: Lua script execution settings
- **Recon Service**: Integrated reconnaissance and asset discovery
- **Monitoring**: Health checks, logging, metrics

## 🎯 API Usage Examples

### 1. Discover Assets

```bash
curl -X POST http://localhost:8080/api/v1/assets/discover \
  -H "Content-Type: application/json" \
  -d '{"hosts": ["example.com", "192.168.1.1"]}'
```

Response:
```json
{
  "message": "Asset discovery started",
  "job_id": "discovery_abc123",
  "host_count": 2,
  "started_at": "2024-01-15T10:30:00Z"
}
```

### 2. Get Asset Catalogue

```bash
curl http://localhost:8080/api/v1/assets/catalogue
```

Response:
```json
{
  "assets": [
    {
      "id": "domain_xyz789",
      "type": "domain",
      "value": "example.com",
      "discovered_at": "2024-01-15T10:30:15Z",
      "scan_count": 0,
      "status": "discovered"
    }
  ],
  "total": 1
}
```

### 3. Scan Asset

```bash
curl -X POST http://localhost:8080/api/v1/assets/domain_xyz789/scan \
  -H "Content-Type: application/json" \
  -d '{"scripts": ["basic_info.lua", "security_check.lua"]}'
```

### 4. Check Job Status

```bash
curl http://localhost:8080/api/v1/jobs/scan_asset_def456
```

Response:
```json
{
  "job_id": "scan_asset_def456",
  "status": "completed",
  "started_at": "2024-01-15T10:35:00Z",
  "completed_at": "2024-01-15T10:35:30Z",
  "progress": {
    "total": 1,
    "completed": 1,
    "failed": 0
  }
}
```

## 🔍 Lua Scripting

### Script Structure

Lua scripts are automatically loaded from the `scripts/` directory:

```lua
-- @description Script description
-- @category security
-- @author Your Name
-- @version 1.0
-- @asset_types domain,ip,service

log("Processing asset: " .. asset.value)

-- Access asset properties
if asset.type == "domain" then
    log("Domain: " .. asset.value)
    set_metadata("domain_length", string.len(asset.value))
end

-- Built-in functions:
-- log(message) - Log output
-- set_metadata(key, value) - Set result metadata
-- sleep(seconds) - Sleep for specified time
```

### Asset Object

The `asset` global table contains:

```lua
asset = {
    id = "unique_asset_id",
    type = "domain|subdomain|ip|service", 
    value = "example.com",
    status = "discovered|scanning|scanned|error",
    scan_count = 0,
    properties = { ... }  -- Additional properties
}
```

### Example Scripts

The system includes example scripts:
- `basic_info.lua` - Basic asset information gathering
- `security_check.lua` - Security-focused analysis

## 🏗 Build & Deployment

### Make Targets

```bash
make help                 # Show all available targets
make dev-setup           # Set up development environment
make build               # Build binary
make build-prod          # Build optimized for production
make test                # Run tests
make docker-build        # Build Docker image
make release             # Create release archive
```

### Docker Deployment

```bash
# Simple deployment
docker-compose up -d

# With reverse proxy
docker-compose --profile with-proxy up -d
```

### Production Deployment

1. Build release: `make release`
2. Extract: `tar -xzf build/asset-scanner-*.tar.gz`
3. Configure: Copy and edit `.env.example`
4. Run: `./scanner`

## 🔒 Security Considerations

- **Sudo Access**: Recontool integration requires sudo for port scanning
- **Script Execution**: Lua scripts run with application privileges
- **File Storage**: JSON files contain discovered asset information
- **Network Access**: Application makes network requests during discovery

## 📊 Monitoring & Health

### Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:40:00Z",
  "services": {
    "storage": "healthy"
  },
  "version": "1.0.0"
}
```

### Storage Statistics

```bash
curl http://localhost:8080/api/v1/stats
```

## 🐛 Troubleshooting

### Common Issues

1. **Nmap not found**: Install nmap for port scanning functionality
2. **Permission denied**: Ensure proper permissions for nmap (if using port scanning)
3. **Script loading errors**: Check script syntax and file permissions
4. **Storage errors**: Verify data directory permissions

### Debug Mode

Enable verbose logging:
```bash
MONITORING_LOG_LEVEL=debug ./scanner
```

### Logs

The application provides structured logging for:
- HTTP requests and responses
- Asset discovery progress
- Lua script execution
- Storage operations
- Error conditions

## 🚀 Performance

- **Concurrent Processing**: Configurable worker pools
- **Background Jobs**: Non-blocking API responses  
- **File-based Storage**: Fast JSON operations
- **Script Caching**: Lua script compilation caching
- **Request Timeouts**: Configurable timeouts prevent hanging

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test: `make test`
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Echo](https://echo.labstack.com/) web framework
- Lua scripting powered by [gopher-lua](https://github.com/yuin/gopher-lua)
- Includes integrated reconnaissance service for asset discovery
- Inspired by production Go backend patterns
