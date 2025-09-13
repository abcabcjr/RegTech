# Incident Management Backend Implementation

This document describes the complete backend implementation for incident management functionality, designed to support the frontend UI mockup shown in `frontendv2/src/routes/incidents/+page.svelte`.

## Overview

The incident management system supports a 3-stage workflow:
1. **Initial Report** - Basic incident details and initial assessment
2. **Update Report** - Impact analysis and interim actions
3. **Final Report** - Root cause analysis and mitigation details

## Architecture

The implementation follows the established layered architecture pattern:

```
Handler Layer (HTTP) → Service Layer (Business Logic) → Storage Layer (Data)
```

## Components Implemented

### 1. Data Models (`internal/model/incident.go`)

**Core Types:**
- `IncidentRecord` - Complete incident data structure
- `IncidentSummary` - Lightweight summary for listings
- `InitialDetails` - Initial report stage data
- `UpdateDetails` - Update report stage data  
- `FinalDetails` - Final report stage data
- `Attachment` - File attachment metadata

**Enums:**
- `IncidentStage`: `initial`, `update`, `final`
- `CauseTag`: `phishing`, `vuln_exploit`, `misconfig`, `malware`, `other`
- `GravityLevel`: `low`, `medium`, `high`, `critical`

**Key Features:**
- Stage transition validation
- Helper methods for titles and summaries
- JSON serialization support

### 2. Storage Interface (`internal/storage/storage.go`)

**New Methods Added:**
```go
CreateIncident(ctx context.Context, incident *model.IncidentRecord) error
GetIncident(ctx context.Context, id string) (*model.IncidentRecord, error)
UpdateIncident(ctx context.Context, incident *model.IncidentRecord) error
DeleteIncident(ctx context.Context, id string) error
ListIncidents(ctx context.Context) ([]*model.IncidentRecord, error)
ListIncidentSummaries(ctx context.Context) ([]*model.IncidentSummary, error)
```

### 3. JSON Storage Implementation (`internal/storage/json_storage.go`)

**Features:**
- Thread-safe operations with mutex locking
- Automatic JSON file persistence (`incidents.json`)
- Integration with existing backup system
- Statistics tracking

**File Structure:**
```
data/
├── incidents.json          # Incident records
├── assets.json            # Existing assets
├── jobs.json              # Existing jobs
└── ...                    # Other data files
```

### 4. Business Logic Service (`internal/service/incident.go`)

**Core Operations:**
- `CreateIncident` - Create new incident with validation
- `GetIncident` - Retrieve incident by ID
- `UpdateIncident` - Update with stage transition validation
- `DeleteIncident` - Remove incident
- `ListIncidents` - List with filtering and sorting
- `ListIncidentSummaries` - Lightweight listing
- `GetIncidentStats` - Statistics and analytics

**Advanced Features:**
- Stage transition validation (initial → update → final)
- Comprehensive filtering (by stage, cause, significance, etc.)
- Date range filtering
- Automatic sorting by update time
- Statistics aggregation

**Request/Response Types:**
- `CreateIncidentRequest` - Creation payload with validation
- `UpdateIncidentRequest` - Update payload with validation
- `ListIncidentsRequest` - Filtering parameters
- `IncidentStats` - Statistics response

### 5. HTTP Handlers (`internal/handler/incident.go`)

**REST Endpoints:**
- `POST /api/v1/incidents` - Create incident
- `GET /api/v1/incidents/{id}` - Get specific incident
- `PUT /api/v1/incidents/{id}` - Update incident
- `DELETE /api/v1/incidents/{id}` - Delete incident
- `GET /api/v1/incidents` - List incidents with filtering
- `GET /api/v1/incidents/summaries` - List summaries
- `GET /api/v1/incidents/stats` - Get statistics

**Query Parameters for Listing:**
- `stages` - Filter by stages (comma-separated)
- `causeTags` - Filter by cause tags (comma-separated)
- `significant` - Filter significant incidents only
- `recurring` - Filter recurring incidents only
- `createdAfter` - Date range filter (RFC3339 format)
- `createdBefore` - Date range filter (RFC3339 format)

**Features:**
- Comprehensive error handling
- Input validation
- Swagger documentation annotations
- Proper HTTP status codes

### 6. API Types (`api/v1/types.go`)

**Request Types:**
- `CreateIncidentRequest` - Incident creation
- `UpdateIncidentRequest` - Incident updates
- `InitialDetails`, `UpdateDetails`, `FinalDetails` - Stage-specific data

**Response Types:**
- `IncidentResponse` - Complete incident data
- `IncidentSummaryResponse` - Summary data
- `ListIncidentsResponse` - Collection responses
- `IncidentStatsResponse` - Statistics data

**Features:**
- JSON binding tags
- Swagger example annotations
- Comprehensive field documentation

### 7. Route Registration (`cmd/scanner/main.go`)

**Integration Points:**
- Service initialization with dependency injection
- Handler initialization
- Route registration in API v1 group
- Proper ordering with existing routes

## API Examples

### Create Incident
```bash
curl -X POST http://localhost:8080/api/v1/incidents \
  -H "Content-Type: application/json" \
  -d '{
    "initialDetails": {
      "title": "Security Incident - Phishing Attack",
      "summary": "Multiple users reported suspicious emails",
      "detectedAt": "2024-01-15T10:30:00Z",
      "suspectedIllegal": false,
      "possibleCrossBorder": false
    },
    "significant": true,
    "recurring": false,
    "causeTag": "phishing",
    "usersAffected": 50,
    "downtimeMinutes": 30,
    "financialImpactPct": 2.5
  }'
```

### Update to Final Stage
```bash
curl -X PUT http://localhost:8080/api/v1/incidents/{id} \
  -H "Content-Type: application/json" \
  -d '{
    "stage": "final",
    "significant": true,
    "recurring": false,
    "causeTag": "phishing",
    "finalDetails": {
      "rootCause": "Lack of email security awareness",
      "mitigations": "Enhanced email filtering implemented",
      "lessons": "Need for regular security training"
    }
  }'
```

### List with Filtering
```bash
curl "http://localhost:8080/api/v1/incidents?significant=true&stages=final&causeTags=phishing"
```

## Data Flow

1. **Frontend Request** → HTTP Handler
2. **Handler** → Service Layer (business logic & validation)
3. **Service** → Storage Layer (data persistence)
4. **Storage** → JSON File System
5. **Response** flows back through the layers

## Validation & Error Handling

**Input Validation:**
- Required fields validation
- Enum value validation
- Stage transition validation
- Business rule enforcement

**Error Responses:**
- Consistent error format
- Appropriate HTTP status codes
- Detailed error messages
- Request validation feedback

## Security Considerations

**Implemented:**
- Input validation and sanitization
- SQL injection prevention (N/A for JSON storage)
- Proper error handling without information leakage

**Future Considerations:**
- Authentication/authorization
- Rate limiting
- Audit logging
- Data encryption at rest

## Testing

A comprehensive test script is provided: `test_incidents_api.sh`

**Test Coverage:**
- Complete CRUD operations
- Stage transitions
- Filtering capabilities  
- Error scenarios
- Data validation

**Usage:**
```bash
# Start the backend server first
./test_incidents_api.sh
```

## Integration with Frontend

The backend API is designed to match the frontend data structures exactly:

**Frontend Types** → **Backend Types**
- `IncidentRecord` → `model.IncidentRecord`
- `InitialDetails` → `model.InitialDetails`
- `UpdateDetails` → `model.UpdateDetails`
- `FinalDetails` → `model.FinalDetails`
- `IncidentStage` → `model.IncidentStage`
- `CauseTag` → `model.CauseTag`

## File Structure

```
backendnew/
├── internal/
│   ├── model/
│   │   └── incident.go              # Data models
│   ├── storage/
│   │   ├── storage.go               # Interface (updated)
│   │   └── json_storage.go          # Implementation (updated)
│   ├── service/
│   │   └── incident.go              # Business logic
│   └── handler/
│       └── incident.go              # HTTP handlers
├── api/
│   └── v1/
│       └── types.go                 # API types (updated)
├── cmd/
│   └── scanner/
│       └── main.go                  # Route registration (updated)
├── data/
│   └── incidents.json               # Runtime data file
└── test_incidents_api.sh            # Test script
```

## Deployment Notes

**Requirements:**
- Go 1.21+
- Write permissions to data directory
- Network access for HTTP server

**Configuration:**
- Uses existing configuration system
- Inherits CORS, timeout, and other middleware
- Integrates with existing backup system

**Monitoring:**
- Incidents included in storage statistics
- Standard HTTP access logging
- Error logging through existing system

## Future Enhancements

**Potential Improvements:**
1. **Database Migration** - Move from JSON to PostgreSQL/MySQL
2. **File Attachments** - Integrate with existing file upload system
3. **Notifications** - Email/webhook notifications for incidents
4. **Workflows** - Automated stage transitions based on criteria
5. **Templates** - Incident report templates
6. **Analytics** - Advanced reporting and dashboards
7. **Integration** - SIEM/monitoring system integration
8. **Compliance** - Regulatory reporting features

The implementation provides a solid foundation that can be extended as requirements evolve.
