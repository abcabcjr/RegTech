#!/bin/bash

# Script to upload checklist templates from a JSON file
# Usage: ./upload_templates.sh [json_file] [base_url]

# Default values
JSON_FILE=${1:-"checklist_templates_full.json"}
BASE_URL=${2:-"http://localhost:8080/api/v1"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Checklist Templates Upload Script${NC}"
echo "=================================="
echo "JSON file: $JSON_FILE"
echo "Backend URL: $BASE_URL"
echo ""

# Check if JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo -e "${RED}Error: JSON file '$JSON_FILE' not found!${NC}"
    echo "Usage: $0 [json_file] [base_url]"
    echo "Example: $0 checklist_templates_full.json http://localhost:8080/api/v1"
    exit 1
fi

# Validate JSON syntax
if ! jq empty "$JSON_FILE" 2>/dev/null; then
    echo -e "${RED}Error: Invalid JSON syntax in '$JSON_FILE'${NC}"
    exit 1
fi

echo -e "${YELLOW}Validating backend connection...${NC}"

# Count templates in JSON
TEMPLATE_COUNT=$(jq '.templates | length' "$JSON_FILE")
echo -e "${BLUE}Found $TEMPLATE_COUNT templates in JSON file${NC}"

echo ""
echo -e "${YELLOW}Uploading templates...${NC}"

# Upload templates
RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$BASE_URL/checklist/templates/upload" \
    -H "Content-Type: application/json" \
    -d @"$JSON_FILE")

# Extract HTTP status and body
HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
HTTP_BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS:.*//g')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ Templates uploaded successfully!${NC}"
    echo ""
    echo "Response:"
    echo "$HTTP_BODY" | jq .
else
    echo -e "${RED}✗ Upload failed with HTTP status: $HTTP_STATUS${NC}"
    echo "Response:"
    echo "$HTTP_BODY" | jq . 2>/dev/null || echo "$HTTP_BODY"
    exit 1
fi

echo ""
echo -e "${BLUE}Verifying upload...${NC}"

# Verify by listing templates
VERIFY_RESPONSE=$(curl -s "$BASE_URL/checklist/templates")
UPLOADED_COUNT=$(echo "$VERIFY_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")

if [ "$UPLOADED_COUNT" -eq "$TEMPLATE_COUNT" ]; then
    echo -e "${GREEN}✓ Verification successful: $UPLOADED_COUNT templates now available${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Expected $TEMPLATE_COUNT templates, but found $UPLOADED_COUNT${NC}"
fi

echo ""
echo -e "${GREEN}Upload complete!${NC}"
echo "You can now view the templates in the frontend compliance page."
