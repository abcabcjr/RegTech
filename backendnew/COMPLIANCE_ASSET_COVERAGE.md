# Compliance Asset Coverage Feature

This document describes the new asset coverage feature for compliance checklists, which shows which assets are covered by each compliance check.

## Overview

The compliance system now includes information about which assets have been evaluated for each compliance check. This helps users understand:

- Which assets are actively being monitored for compliance
- Which assets have passed or failed specific checks
- Coverage gaps where assets might need attention

## API Changes

### Enhanced Checklist Responses

All checklist API responses now include a `covered_assets` array showing assets with YES/NO compliance status:

#### GET `/api/v1/checklist/global`

```json
{
  "id": "security-policy-review",
  "title": "Security Policy Review",
  "description": "Review and approve security policies",
  "status": "yes",
  "source": "manual",
  "notes": "Policy reviewed and approved",
  "attachments": ["file_123"],
  "covered_assets": [
    {
      "asset_id": "asset_456",
      "asset_type": "domain",
      "asset_value": "example.com",
      "status": "yes",
      "notes": "Policy applies to this domain",
      "updated_at": "2025-01-13T14:30:00Z"
    },
    {
      "asset_id": "asset_789",
      "asset_type": "ip",
      "asset_value": "192.168.1.100",
      "status": "no",
      "notes": "Policy violation detected",
      "updated_at": "2025-01-13T14:25:00Z"
    }
  ]
}
```

#### GET `/api/v1/checklist/asset/{id}`

Similar structure, showing all compliance checks for a specific asset with coverage information.

### New Coverage Summary Endpoint

#### GET `/api/v1/checklist/coverage/summary`

Returns a comprehensive summary of compliance coverage across all assets:

```json
{
  "total_assets": 15,
  "total_compliance_checks": 8,
  "assets_with_compliance_data": 12,
  "coverage_by_asset_type": {
    "domain": {
      "yes_count": 5,
      "no_count": 2,
      "total_checks": 7
    },
    "ip": {
      "yes_count": 8,
      "no_count": 3,
      "total_checks": 11
    },
    "service": {
      "yes_count": 4,
      "no_count": 1,
      "total_checks": 5
    }
  },
  "coverage_by_check": {
    "security-policy-review": {
      "yes_count": 10,
      "no_count": 2,
      "total_applicable": 12
    },
    "ssl-certificate-check": {
      "yes_count": 8,
      "no_count": 4,
      "total_applicable": 12
    }
  }
}
```

## Data Model Changes

### AssetCoverage Model

New model representing an asset covered by a compliance check:

```go
type AssetCoverage struct {
    AssetID   string     `json:"asset_id"`
    AssetType string     `json:"asset_type"`
    AssetValue string    `json:"asset_value"`
    Status    string     `json:"status"`     // "yes" or "no" only
    Notes     string     `json:"notes,omitempty"`
    UpdatedAt *time.Time `json:"updated_at,omitempty"`
}
```

### Enhanced DerivedChecklistItem

The `DerivedChecklistItem` model now includes:

```go
type DerivedChecklistItem struct {
    // ... existing fields
    CoveredAssets []AssetCoverage `json:"covered_assets,omitempty"`
}
```

## How Coverage is Determined

### Global Compliance Checks

For global compliance checks (scope: "global"):
- Shows assets that have specific status overrides for that global check
- Only includes assets with "YES" or "NO" status (excludes "N/A")

### Asset-Specific Compliance Checks

For asset-specific compliance checks (scope: "asset"):
- Shows all compatible assets based on `asset_types` in the template
- Includes manually set statuses and script-controlled results
- Only includes assets with "YES" or "NO" status (excludes "N/A")

### Script-Controlled Results

Assets with script-controlled compliance results are automatically included when scripts set YES/NO status.

## Usage Examples

### 1. Get Global Compliance with Coverage

```bash
curl http://localhost:8080/api/v1/checklist/global
```

This will show all global compliance checks with their asset coverage.

### 2. Get Asset-Specific Compliance with Coverage

```bash
curl http://localhost:8080/api/v1/checklist/asset/asset_123
```

This will show all applicable compliance checks for the specific asset, including coverage from other assets for comparison.

### 3. Get Coverage Summary

```bash
curl http://localhost:8080/api/v1/checklist/coverage/summary
```

This provides a high-level overview of compliance coverage across your entire asset inventory.

### 4. Filter Assets by Compliance Status

You can use the coverage data to identify:

- **Compliant Assets**: Assets with `status: "yes"`
- **Non-Compliant Assets**: Assets with `status: "no"`
- **Uncovered Assets**: Assets not appearing in any `covered_assets` arrays

## Frontend Integration

The frontend can now display:

1. **Coverage Indicators**: Show how many assets are covered by each check
2. **Asset Lists**: Display which specific assets are compliant/non-compliant
3. **Coverage Gaps**: Identify assets that haven't been evaluated
4. **Compliance Dashboard**: Summary statistics and coverage metrics

### Example Frontend Display

```
Security Policy Review ✓ YES
├── Covered Assets: 12 of 15
├── ✅ example.com (domain) - Compliant
├── ✅ api.example.com (subdomain) - Compliant  
├── ❌ 192.168.1.100 (ip) - Policy violation
└── ❌ test.example.com (subdomain) - Needs review
```

## Performance Considerations

- Coverage data is calculated on-demand for each API request
- Large asset inventories may see slower response times
- Consider caching coverage summaries for frequently accessed data
- Coverage calculation is optimized with proper indexing by asset type

## Migration Notes

- Existing API responses are enhanced but remain backward compatible
- The `covered_assets` field is optional and won't break existing clients
- No database schema changes required (uses existing checklist status data)

This feature provides comprehensive visibility into compliance coverage without requiring changes to the underlying data structure or breaking existing functionality.
