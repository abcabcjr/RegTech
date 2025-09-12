#!/bin/bash

# API Testing Script for Asset Scanner Backend
# This script tests the main API endpoints

set -e

BASE_URL="http://localhost:8080"
CONTENT_TYPE="Content-Type: application/json"

echo "=== Asset Scanner Backend API Test ==="
echo

# Check if server is running
echo "1. Testing health check..."
curl -s "$BASE_URL/health" | jq . || echo "Server not running or jq not installed"
echo

# Test asset discovery
echo "2. Testing asset discovery..."
DISCOVERY_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/assets/discover" \
  -H "$CONTENT_TYPE" \
  -d '{"hosts": [""]}')

echo "$DISCOVERY_RESPONSE" | jq . 2>/dev/null || echo "$DISCOVERY_RESPONSE"
JOB_ID=$(echo "$DISCOVERY_RESPONSE" | jq -r '.job_id' 2>/dev/null || echo "")
echo

# Monitor discovery progress
if [ ! -z "$JOB_ID" ] && [ "$JOB_ID" != "null" ]; then
    echo "3. Monitoring discovery progress for job: $JOB_ID"
    echo "   Polling asset catalogue every second until discovery completes..."
    echo
    
    DISCOVERY_COMPLETE=false
    POLL_COUNT=0
    MAX_POLLS=60  # Maximum 60 seconds
    
    while [ "$DISCOVERY_COMPLETE" = false ] && [ $POLL_COUNT -lt $MAX_POLLS ]; do
        POLL_COUNT=$((POLL_COUNT + 1))
        
        # Check job status
        JOB_STATUS=$(curl -s "$BASE_URL/api/v1/jobs/$JOB_ID" | jq -r '.status' 2>/dev/null || echo "unknown")
        
        # Get current asset count
        ASSET_COUNT=$(curl -s "$BASE_URL/api/v1/assets/catalogue" | jq -r '.total' 2>/dev/null || echo "0")
        
        echo "   Poll $POLL_COUNT: Job=$JOB_STATUS, Assets=$ASSET_COUNT"
        
        if [ "$JOB_STATUS" = "completed" ] || [ "$JOB_STATUS" = "failed" ] || [ "$JOB_STATUS" = "cancelled" ]; then
            DISCOVERY_COMPLETE=true
            echo "   Discovery completed with status: $JOB_STATUS"
        else
            sleep 1
        fi
    done
    
    if [ $POLL_COUNT -ge $MAX_POLLS ]; then
        echo "   Warning: Stopped polling after $MAX_POLLS seconds"
    fi
    
    echo
    
    echo "4. Final job status:"
    curl -s "$BASE_URL/api/v1/jobs/$JOB_ID" | jq . 2>/dev/null || echo "Job status check failed"
    echo
else
    echo "3. No job ID returned, skipping discovery monitoring"
    echo
fi

# Get final asset catalogue
echo "5. Getting final asset catalogue..."
CATALOGUE_RESPONSE=$(curl -s "$BASE_URL/api/v1/assets/catalogue")
echo "$CATALOGUE_RESPONSE" | jq . 2>/dev/null || echo "$CATALOGUE_RESPONSE"

# Extract first asset ID for testing
ASSET_ID=$(echo "$CATALOGUE_RESPONSE" | jq -r '.assets[0].id' 2>/dev/null || echo "")
echo

# Test asset details if we have an asset
if [ ! -z "$ASSET_ID" ] && [ "$ASSET_ID" != "null" ]; then
    echo "6. Getting asset details for: $ASSET_ID"
    curl -s "$BASE_URL/api/v1/assets/$ASSET_ID" | jq . 2>/dev/null || echo "Asset details failed"
    echo

    echo "7. Starting asset scan for: $ASSET_ID"
    SCAN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/assets/$ASSET_ID/scan" \
      -H "$CONTENT_TYPE" \
      -d '{"scripts": ["basic_info.lua"]}')
    echo "$SCAN_RESPONSE" | jq . 2>/dev/null || echo "$SCAN_RESPONSE"
    echo
else
    echo "6. No assets found to test individual asset endpoints"
    echo
fi

# Test concurrent discovery (should fail)
echo "8. Testing concurrent discovery (should return 409 Conflict)..."
CONCURRENT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/assets/discover" \
  -H "$CONTENT_TYPE" \
  -d '{"hosts": ["test.com"]}')
echo "$CONCURRENT_RESPONSE" | jq . 2>/dev/null || echo "$CONCURRENT_RESPONSE"
echo

# Test scan all assets
echo "9. Testing scan all assets..."
curl -s -X POST "$BASE_URL/api/v1/assets/scan" \
  -H "$CONTENT_TYPE" \
  -d '{"asset_types": ["domain"], "scripts": ["basic_info.lua"]}' | jq . 2>/dev/null || echo "Scan all failed"
echo

# Test script listing
echo "9. Listing available scripts..."
curl -s "$BASE_URL/api/v1/scripts" | jq . 2>/dev/null || echo "Script listing failed"
echo

# Test storage stats
echo "10. Getting storage statistics..."
curl -s "$BASE_URL/api/v1/stats" | jq . 2>/dev/null || echo "Storage stats failed"
echo

# Test version info
echo "11. Getting version information..."
curl -s "$BASE_URL/version" | jq . 2>/dev/null || echo "Version info failed"
echo

echo "=== API Test Completed ==="
echo
echo "To run this test:"
echo "1. Start the server: make dev"
echo "2. In another terminal: chmod +x test_api.sh && ./test_api.sh"
echo
echo "For better output, install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)"
