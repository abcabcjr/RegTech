#!/bin/bash

# Test script for Incident Management API
# Run this after starting the backend server

BASE_URL="http://localhost:8080/api/v1"

echo "Testing Incident Management API..."
echo "=================================="

# Test 1: Create a new incident
echo "1. Creating a new incident..."
INCIDENT_ID=$(curl -s -X POST "$BASE_URL/incidents" \
  -H "Content-Type: application/json" \
  -d '{
    "initialDetails": {
      "title": "Test Security Incident",
      "summary": "This is a test incident for API validation",
      "detectedAt": "2024-01-15T10:30:00Z",
      "suspectedIllegal": false,
      "possibleCrossBorder": false
    },
    "significant": true,
    "recurring": false,
    "causeTag": "phishing",
    "usersAffected": 50,
    "downtimeMinutes": 30,
    "financialImpactPct": 2.5,
    "sectorPreset": "financial",
    "attachments": [
      {
        "name": "incident-log.txt",
        "note": "System logs during incident"
      }
    ]
  }' | jq -r '.id // empty')

if [ -n "$INCIDENT_ID" ]; then
  echo "✓ Incident created with ID: $INCIDENT_ID"
else
  echo "✗ Failed to create incident"
  exit 1
fi

echo ""

# Test 2: Get the created incident
echo "2. Retrieving the created incident..."
curl -s -X GET "$BASE_URL/incidents/$INCIDENT_ID" | jq '.'
echo ""

# Test 3: Update the incident to 'update' stage
echo "3. Updating incident to 'update' stage..."
curl -s -X PUT "$BASE_URL/incidents/$INCIDENT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "stage": "update",
    "significant": true,
    "recurring": false,
    "causeTag": "phishing",
    "usersAffected": 75,
    "downtimeMinutes": 45,
    "financialImpactPct": 3.2,
    "updateDetails": {
      "gravity": "high",
      "impact": "Email system compromised, user credentials at risk",
      "iocs": ["malicious-domain.com", "192.168.1.100"],
      "corrections": "Blocked malicious domains and reset affected passwords"
    }
  }' | jq '.'
echo ""

# Test 4: List all incidents
echo "4. Listing all incidents..."
curl -s -X GET "$BASE_URL/incidents" | jq '.'
echo ""

# Test 5: List incident summaries
echo "5. Listing incident summaries..."
curl -s -X GET "$BASE_URL/incidents/summaries" | jq '.'
echo ""

# Test 6: Get incident statistics
echo "6. Getting incident statistics..."
curl -s -X GET "$BASE_URL/incidents/stats" | jq '.'
echo ""

# Test 7: Update to final stage
echo "7. Updating incident to 'final' stage..."
curl -s -X PUT "$BASE_URL/incidents/$INCIDENT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "stage": "final",
    "significant": true,
    "recurring": false,
    "causeTag": "phishing",
    "finalDetails": {
      "rootCause": "Lack of email security awareness training",
      "gravity": "high",
      "impact": "No data exfiltration occurred, but user credentials were compromised",
      "mitigations": "Enhanced email filtering implemented, mandatory security training scheduled",
      "crossBorderDesc": "No cross-border effects identified",
      "lessons": "Need for regular security awareness training and improved email filtering"
    }
  }' | jq '.'
echo ""

# Test 8: Test filtering (significant incidents only)
echo "8. Filtering significant incidents only..."
curl -s -X GET "$BASE_URL/incidents?significant=true" | jq '.'
echo ""

# Test 9: Delete the incident (cleanup)
echo "9. Deleting the test incident..."
curl -s -X DELETE "$BASE_URL/incidents/$INCIDENT_ID" | jq '.'
echo ""

echo "API testing completed!"
