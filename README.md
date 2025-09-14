# Mephisto - Compliance & Security Asset Management Platform

A comprehensive platform for regulatory technology compliance, asset discovery, security scanning, and vulnerability management. The system provides automated asset discovery, Lua-powered security scanning, incident management, and compliance reporting through a modern web interface.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │───▶│   Backend       │───▶│ Lua Scripts     │
│   (SvelteKit)   │    │   (Go/Echo)     │    │ (Security)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ JSON Storage    │
                       │ (File-based)    │
                       └─────────────────┘
```

## 🚀 Key Features

### 🔍 **Asset Discovery & Management**
- **Automated Discovery**: Network asset discovery with reconnaissance tools
- **Asset Cataloguing**: Comprehensive asset inventory with metadata
- **Real-time Monitoring**: Continuous asset status tracking
- **Visual Mapping**: Interactive network topology visualization

### 🛡️ **Security Scanning**
- **Lua Scripting Engine**: Extensible security checks with custom scripts  
- **Multi-Protocol Support**: HTTP, HTTPS, DNS, port scanning capabilities
- **Vulnerability Detection**: Automated security vulnerability identification
- **Compliance Mapping**: Security findings mapped to compliance frameworks

### 📋 **Incident Management**
- **3-Stage Workflow**: Initial → Update → Final incident progression
- **Real-time Tracking**: Live incident status and progress monitoring
- **Collaborative Features**: Multi-user incident handling and updates
- **Compliance Integration**: Incidents linked to compliance requirements

### 📊 **Compliance Reporting**
- **Interactive Dashboards**: Real-time compliance status visualization
- **PDF Export**: Professional compliance reports with charts
- **Template System**: Customizable compliance checklist templates
- **Audit Trails**: Complete audit history and evidence collection

### 🎯 **Specialized Security Modules**
- **Shopify Security**: Specialized scanning for e-commerce vulnerabilities
- **DNS Analysis**: Comprehensive DNS record analysis and security checks
- **TLS/SSL Assessment**: Certificate validation and cipher analysis
- **Port Security**: Network service discovery and security assessment

## 📁 Project Structure

```
RegTech/
├── backendnew/                 # Go backend API server
│   ├── api/v1/                 # API contracts and types
│   ├── cmd/scanner/            # Application entry point
│   ├── internal/               # Private application code
│   │   ├── config/             # Environment configuration
│   │   ├── handler/            # HTTP request handlers
│   │   ├── model/              # Domain models
│   │   ├── scanner/            # Lua script execution engine
│   │   ├── service/            # Business logic services
│   │   └── storage/            # JSON file storage
│   ├── scripts/                # Lua security scanning scripts
│   ├── data/                   # JSON storage files
│   ├── docs/                   # Swagger API documentation
│   └── Dockerfile              # Backend container configuration
├── frontendv2/                 # SvelteKit frontend application
│   ├── src/
│   │   ├── lib/
│   │   │   ├── api/            # Generated API client
│   │   │   ├── components/     # Reusable UI components
│   │   │   ├── stores/         # Global state management
│   │   │   └── utils/          # Utility functions
│   │   └── routes/             # SvelteKit file-based routing
│   ├── static/                 # Static assets and guides
│   └── Dockerfile              # Frontend container configuration
├── demo-vulnerabilities/       # Security testing demos
│   └── shopify-vulnerable-theme/  # Shopify security test cases
├── recontool/                  # Asset discovery utilities
└── docker-compose.yml          # Complete system orchestration
```

## 🛠️ Quick Start

### Prerequisites

- **Docker & Docker Compose** (recommended)
- **Go 1.24.1+** (for backend development)
- **Node.js 22+** (for frontend development)
- **Make** (for build automation)

### 🐳 Docker Deployment (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd RegTech

# Start the complete platform
docker-compose up --build -d

# Access the services
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080
# API Documentation: http://localhost:8080/swagger/
```

### 🔧 Development Setup

#### Backend Development
```bash
cd backendnew

# Setup development environment
make dev-setup

# Start development server
make dev

# Run tests
make test

# Build production binary
make build-prod
```

#### Frontend Development
```bash
cd frontendv2

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Generate API client (when backend changes)
npm run schemagen
```

## 🎯 API Overview

### Asset Management
```bash
# Discover new assets
POST /api/v1/assets/discover
{
  "hosts": ["example.com", "192.168.1.1"]
}

# Get asset catalog
GET /api/v1/assets/catalogue

# Scan specific asset
POST /api/v1/assets/{id}/scan
{
  "scripts": ["basic_info.lua", "security_check.lua"]
}

# Scan all assets
POST /api/v1/assets/scan
{
  "asset_types": ["domain", "ip"],
  "scripts": ["security_check.lua"]
}
```

### Incident Management
```bash
# Create incident
POST /api/v1/incidents
{
  "title": "Security Incident",
  "description": "Description",
  "severity": "high"
}

# Update incident
PUT /api/v1/incidents/{id}
{
  "stage": "update",
  "status": "investigating"
}

# Get incidents
GET /api/v1/incidents
```

### Job Tracking
```bash
# Check job status
GET /api/v1/jobs/{job_id}

# Response
{
  "job_id": "scan_abc123",
  "status": "completed",
  "progress": {
    "total": 10,
    "completed": 8,
    "failed": 2
  }
}
```

## 🔍 Lua Scripting System

### Script Structure
```lua
-- @description Basic asset information gathering
-- @category information
-- @author RegTech Team
-- @version 1.0
-- @asset_types domain,ip,service

log("Processing asset: " .. asset.value)

if asset.type == "domain" then
    -- Perform domain-specific checks
    set_metadata("domain_length", string.len(asset.value))
    
    -- Check for common security headers
    local response = http_get("https://" .. asset.value)
    if response then
        check_security_headers(response.headers)
    end
end
```

### Available Functions
- `log(message)` - Output scan results
- `set_metadata(key, value)` - Store structured data
- `http_get(url)` - Make HTTP requests
- `dns_lookup(domain)` - Perform DNS queries
- `port_scan(ip, port)` - Check port status
- `sleep(seconds)` - Pause execution

### Specialized Security Scripts
- **`shopify_security_check.lua`** - E-commerce platform security analysis
- **`tls_certificate_check.lua`** - SSL/TLS certificate validation
- **`dns_enumerator.lua`** - DNS record enumeration and analysis
- **`port_security_checklist.lua`** - Network port security assessment
- **`vulnerability_check.lua`** - CVE and vulnerability detection

## 🛡️ Security Features

### Asset Types & Discovery
- **Domains**: Root domains with DNS analysis
- **Subdomains**: Subdomain enumeration and analysis
- **IP Addresses**: Network range scanning
- **Services**: Port and service detection
- **Proxied Assets**: Cloudflare and CDN detection

### Vulnerability Detection
- **Hardcoded Secrets**: API keys, tokens, credentials
- **Open Redirects**: URL redirection vulnerabilities
- **Information Disclosure**: Sensitive data exposure
- **Security Headers**: Missing or misconfigured headers
- **TLS/SSL Issues**: Certificate and cipher problems
- **DNS Security**: DNS configuration vulnerabilities

### Compliance Frameworks
- **SOC 2**: System and Organization Controls
- **ISO 27001**: Information Security Management
- **GDPR**: General Data Protection Regulation
- **PCI DSS**: Payment Card Industry standards
- **NIST**: Cybersecurity Framework alignment

## 📊 User Interface Features

### 🎨 Modern SvelteKit Frontend
- **Responsive Design**: Mobile-first, adaptive layouts
- **Interactive Dashboards**: Real-time data visualization
- **Asset Graph View**: Network topology visualization with vis-network
- **Compliance Overview**: Progress tracking and status indicators
- **Incident Wizard**: Step-by-step incident creation and management

### 🔧 Key UI Components
- **Asset Discovery Panel**: Initiate and monitor asset discovery
- **Security Scan Results**: Detailed vulnerability reports
- **Compliance Checklists**: Interactive compliance tracking
- **Incident Management**: Full incident lifecycle management
- **Export Functionality**: PDF reports and data export

## 🎯 Demo & Testing

### Shopify Security Demo
The platform includes a comprehensive Shopify security testing environment:

```bash
cd demo-vulnerabilities

# Setup vulnerable Shopify theme
./setup-shopify-demo.sh

# Run security scan
cd ../backendnew
./build/scanner -target "demo-store.myshopify.com" -script "shopify_security_check.lua"
```

**Expected Findings:**
- 🔴 **CRITICAL**: 8+ hardcoded secrets detected
- 🟠 **HIGH**: 4+ open redirect vulnerabilities  
- 🟡 **MEDIUM**: 3+ JSON endpoints with sensitive data

### Testing Scripts
```bash
# Backend API tests
cd backendnew
./test_api.sh
./test_incidents_api.sh

# Asset discovery tests
./test_streaming_discovery.sh
```

## 🚀 Deployment Options

### Production Deployment
```bash
# Build optimized containers
docker-compose -f docker-compose.prod.yml up -d

# Or deploy individual services
cd backendnew && make build-prod
cd frontendv2 && npm run build
```

### Environment Configuration
```bash
# Backend (.env)
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
STORAGE_DATA_DIR=./data
SCANNER_SCRIPTS_DIR=./scripts
SCANNER_MAX_CONCURRENT=10

# Frontend environment variables
PUBLIC_API_HOST=http://localhost:8080
```

### Health Monitoring
```bash
# Backend health check
curl http://localhost:8080/health

# Storage statistics  
curl http://localhost:8080/api/v1/stats

# Frontend health (nginx)
curl http://localhost:3000/
```

## 📈 Performance & Scalability

### Backend Performance
- **Concurrent Processing**: Configurable worker pools for scanning
- **Background Jobs**: Asynchronous asset discovery and scanning
- **File-based Storage**: Fast JSON operations with automatic backups
- **Request Timeouts**: Configurable timeouts prevent hanging operations

### Frontend Optimization
- **Static Site Generation**: Pre-built pages for faster loading
- **Code Splitting**: Lazy loading of components and routes
- **Asset Optimization**: Minified CSS/JS with cache headers
- **Real-time Updates**: Efficient state management with Svelte stores

## 🔧 Development Guidelines

### Backend Development (Go)
- **Clean Architecture**: Layered design with dependency injection
- **Error Handling**: Structured errors with HTTP status codes
- **Testing**: Unit and integration tests with table-driven patterns
- **Documentation**: Swagger/OpenAPI specifications

### Frontend Development (Svelte 5)
- **Runes Syntax**: Modern Svelte 5 reactivity with `$state()`, `$derived()`
- **TypeScript**: Strict typing with generated API clients
- **Component Design**: Reusable UI components with shadcn-svelte
- **State Management**: Centralized stores with reactive updates

### Security Best Practices
- **Input Validation**: All user inputs validated and sanitized
- **CORS Configuration**: Proper cross-origin request handling
- **Container Security**: Non-root users in Docker containers
- **Secret Management**: Environment-based configuration

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes and test**: `make test` (backend) or `npm test` (frontend)
4. **Commit changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Create Pull Request**

### Development Workflow
- **Backend changes**: Update API, run tests, update Swagger docs
- **Frontend changes**: Update components, test UI, regenerate API client
- **Full-stack features**: Coordinate backend API with frontend integration

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Backend**: Built with [Echo](https://echo.labstack.com/) web framework
- **Frontend**: Powered by [SvelteKit](https://kit.svelte.dev/) and [Svelte 5](https://svelte.dev/)
- **Scripting**: Lua integration via [gopher-lua](https://github.com/yuin/gopher-lua)
- **UI Components**: [shadcn-svelte](https://www.shadcn-svelte.com/) component library
- **Visualization**: [vis-network](https://visjs.github.io/vis-network/) for graph rendering

---

## 🎉 Success Metrics

✅ **Production-Ready Platform**: Complete full-stack application with Docker deployment  
✅ **Comprehensive Security Scanning**: 20+ Lua scripts for vulnerability detection  
✅ **Modern Web Interface**: Responsive SvelteKit frontend with real-time updates  
✅ **API-First Design**: RESTful API with Swagger documentation  
✅ **Compliance Integration**: Multiple framework support with reporting  
✅ **Incident Management**: Complete incident lifecycle management  
✅ **Asset Discovery**: Automated network asset discovery and cataloging  
✅ **Extensible Architecture**: Plugin-based scanning with custom Lua scripts  

**RegTech is ready for enterprise deployment with comprehensive security scanning, compliance management, and modern web interface capabilities.**
