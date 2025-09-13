#!/bin/bash

# REGTECH SHOPIFY VULNERABILITY DEMO SETUP
# This script sets up a complete vulnerable Shopify store for security testing

echo "🎯 RegTech Shopify Security Demo Setup"
echo "======================================"

# Configuration
DEMO_STORE_URL="regtech-security-demo.myshopify.com"
SCANNER_HOST="localhost"
SCANNER_PORT="8080"

echo "Demo Store URL: https://$DEMO_STORE_URL"
echo "Scanner API: http://$SCANNER_HOST:$SCANNER_PORT"
echo ""

# Test 1: Hardcoded Secrets Detection
echo "🔍 Test 1: Hardcoded Secrets Detection"
echo "Testing endpoints for exposed API keys..."

curl -s "https://$DEMO_STORE_URL/" | grep -i "api_key\|secret\|token" && echo "✅ Secrets found in homepage" || echo "❌ No secrets detected"
curl -s "https://$DEMO_STORE_URL/pages/demo-vulnerable-page" | grep -i "shopify.*api" && echo "✅ Shopify API references found" || echo "❌ No API references"

# Test 2: JSON Endpoint Exposure
echo ""
echo "🔍 Test 2: JSON Endpoint Information Disclosure"
echo "Testing JSON endpoints for sensitive data exposure..."

# Test products.json
PRODUCTS_RESPONSE=$(curl -s "https://$DEMO_STORE_URL/products.json")
if echo "$PRODUCTS_RESPONSE" | grep -qi "email\|phone\|internal\|admin\|api"; then
    echo "✅ Sensitive data found in products.json"
    echo "$PRODUCTS_RESPONSE" | jq -r '.products[] | select(.body_html | test("email|phone|internal|admin"; "i")) | .title' 2>/dev/null
else
    echo "❌ No sensitive data in products.json"
fi

# Test collections.json  
COLLECTIONS_RESPONSE=$(curl -s "https://$DEMO_STORE_URL/collections.json")
if echo "$COLLECTIONS_RESPONSE" | grep -qi "internal\|admin\|private"; then
    echo "✅ Internal collections found"
else
    echo "❌ No internal collections detected"
fi

# Test 3: Open Redirect Vulnerabilities
echo ""
echo "🔍 Test 3: Open Redirect Vulnerability Testing"
echo "Testing redirect parameters..."

# Test various redirect parameters
REDIRECT_URLS=(
    "https://$DEMO_STORE_URL/?redirect=https://evil-site.com"
    "https://$DEMO_STORE_URL/?return_to=http://malicious.com" 
    "https://$DEMO_STORE_URL/?next=//attacker.com"
    "https://$DEMO_STORE_URL/?callback=javascript:alert(1)"
)

for url in "${REDIRECT_URLS[@]}"; do
    RESPONSE=$(curl -s -I "$url")
    if echo "$RESPONSE" | grep -i "Location:.*evil\|Location:.*malicious\|Location:.*attacker"; then
        echo "✅ Open redirect vulnerability confirmed: $url"
    else
        echo "⚠️  Testing redirect: $url"
    fi
done

# Test 4: Run Our Security Scanner
echo ""
echo "🔍 Test 4: Running RegTech Security Scanner"
echo "Scanning $DEMO_STORE_URL with our Lua plugin..."

# Prepare scan request
SCAN_REQUEST=$(cat <<EOF
{
    "assets": [
        {
            "type": "domain", 
            "value": "$DEMO_STORE_URL"
        }
    ],
    "scripts": ["shopify_security_check.lua"]
}
EOF
)

# Run scan via API
SCAN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$SCAN_REQUEST" \
    "http://$SCANNER_HOST:$SCANNER_PORT/api/scan")

if [ $? -eq 0 ]; then
    echo "✅ Scan initiated successfully"
    echo "Response: $SCAN_RESPONSE"
    
    # Parse results if JSON
    echo "$SCAN_RESPONSE" | jq . 2>/dev/null || echo "Raw response: $SCAN_RESPONSE"
else
    echo "❌ Failed to connect to scanner API"
    echo "Make sure the RegTech scanner is running on $SCANNER_HOST:$SCANNER_PORT"
fi

# Test 5: Manual Plugin Testing
echo ""
echo "🔍 Test 5: Manual Lua Plugin Verification"
echo "You can manually test the plugin with:"
echo ""
echo "cd /path/to/regtech/backendnew"
echo "./build/scanner -target $DEMO_STORE_URL -script shopify_security_check.lua"
echo ""

# Expected Results Summary
echo ""
echo "📊 Expected Detection Results:"
echo "=============================="
echo "✅ Shopify Store Detection: Should identify as Shopify store"
echo "🔴 Hardcoded Secrets: 5+ API keys/tokens in theme files"
echo "🟡 JSON Exposure: 3+ products with sensitive data"
echo "🟠 Open Redirects: 4+ vulnerable redirect parameters"
echo "📈 Security Score: Should be < 50% (CRITICAL risk)"
echo ""

# Demo Commands for Presentation
echo "🎤 Demo Commands for Presentation:"
echo "=================================="
echo ""
echo "# 1. Show vulnerable endpoints"
echo "curl -s 'https://$DEMO_STORE_URL/products.json' | jq ."
echo ""
echo "# 2. Test open redirect"
echo "curl -I 'https://$DEMO_STORE_URL/?redirect=https://evil-site.com'"
echo ""
echo "# 3. Run security scan"
echo "./scanner -target $DEMO_STORE_URL -script shopify_security_check.lua"
echo ""
echo "# 4. Check specific vulnerabilities"
echo "curl -s 'https://$DEMO_STORE_URL/' | grep -i 'api_key\\|secret'"
echo ""

echo "🏁 Demo setup verification complete!"
echo "Your intentionally vulnerable Shopify store is ready for security testing."