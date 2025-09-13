#!/bin/bash

# Script to initialize some sample checklist templates
# Run this after starting the backend server

BASE_URL="http://localhost:8080/api/v1"

echo "Creating sample checklist templates..."

# Global template - Security Policy
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "security-policy-documented",
    "title": "Security Policy Documented",
    "description": "Organization has a documented information security policy",
    "category": "Policy & Governance",
    "required": true,
    "scope": "global",
    "recommendation": "Ensure your organization has a comprehensive security policy document that covers data protection, access controls, and incident response procedures."
  }'

# Asset template - HTTP Security Headers
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "http-security-headers",
    "title": "HTTP Security Headers Present",
    "description": "Web services should implement proper security headers",
    "category": "Web Security",
    "required": true,
    "scope": "asset",
    "asset_types": ["service"],
    "recommendation": "Implement security headers like Content-Security-Policy, X-Frame-Options, and Strict-Transport-Security.",
    "evidence_rules": [
      {
        "source": "scan_metadata",
        "key": "http.headers",
        "op": "exists"
      }
    ]
  }'

# Asset template - Recent Scan
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "recent-scan",
    "title": "Recently Scanned",
    "description": "Asset has been scanned within the last 30 days",
    "category": "Monitoring",
    "required": false,
    "scope": "asset",
    "asset_types": ["domain", "subdomain", "ip", "service"],
    "recommendation": "Ensure regular scanning of all assets to maintain security posture.",
    "evidence_rules": [
      {
        "source": "scan_metadata",
        "key": "last_scanned_at",
        "op": "gte_days_since",
        "value": 30
      }
    ]
  }'

# Asset template - HTTP Title Available
curl -X POST "$BASE_URL/checklist/templates" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "http-title-available",
    "title": "HTTP Title Available",
    "description": "Web service returns a proper HTTP title",
    "category": "Web Security",
    "required": false,
    "scope": "asset",
    "asset_types": ["service"],
    "recommendation": "Ensure web services return descriptive titles and avoid exposing sensitive information.",
    "evidence_rules": [
      {
        "source": "scan_metadata",
        "key": "http.title",
        "op": "exists"
      }
    ]
  }'

echo "Sample checklist templates created!"
