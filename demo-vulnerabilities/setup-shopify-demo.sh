#!/bin/bash

# RegTech Shopify Security Demo - Complete Setup Script
# Creates vulnerable theme and tests our scanner against Shopify stores

echo "🎯 RegTech Shopify Security Demo Setup"
echo "====================================="

THEME_FOLDER="shopify-vulnerable-theme"
ZIP_FILE="vulnerable-shopify-theme.zip"

# Configuration
DEMO_STORE_URL=${1:-"regtech-security-demo.myshopify.com"}
SCANNER_PATH="../backendnew/build/scanner"

echo "Demo Store URL: https://$DEMO_STORE_URL"
echo "Scanner Path: $SCANNER_PATH"
echo ""

# Function to create ZIP for Shopify upload
create_shopify_zip() {
    echo "📦 Creating Shopify theme ZIP..."
    
    if [ ! -d "$THEME_FOLDER" ]; then
        echo "❌ Error: Theme folder '$THEME_FOLDER' not found!"
        return 1
    fi

    # Remove existing ZIP
    [ -f "$ZIP_FILE" ] && rm -f "$ZIP_FILE"

    # Create ZIP excluding README and system files
    cd "$THEME_FOLDER"
    zip -r "../$ZIP_FILE" . \
        -x "README.md" \
        -x ".*" \
        -x "*~" \
        -x "*.DS_Store" || {
        echo "❌ Error creating ZIP file"
        cd ..
        return 1
    }
    cd ..

    if [ -f "$ZIP_FILE" ]; then
        FILE_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
        echo "✅ Created $ZIP_FILE ($FILE_SIZE)"
        return 0
    else
        echo "❌ Failed to create ZIP file"
        return 1
    fi
}

# Test 1: Hardcoded Secrets Detection
test_hardcoded_secrets() {
    echo "🔍 Test 1: Hardcoded Secrets Detection"
    echo "Testing endpoints for exposed API keys..."

    if command -v curl &> /dev/null; then
        curl -s "https://$DEMO_STORE_URL/" | grep -i "api_key\|secret\|token" && echo "✅ Secrets found in homepage" || echo "❌ No secrets detected"
        curl -s "https://$DEMO_STORE_URL/pages/demo-vulnerable-page" | grep -i "shopify.*api" && echo "✅ Shopify API references found" || echo "❌ No API references"
    else
        echo "⚠️  curl not available, skipping manual test"
    fi
}

# Test 2: JSON Endpoint Exposure
test_json_endpoints() {
    echo ""
    echo "🔍 Test 2: JSON Endpoint Information Disclosure"
    echo "Testing JSON endpoints for sensitive data exposure..."

    if ! command -v curl &> /dev/null; then
        echo "⚠️  curl not available, skipping JSON endpoint tests"
        return
    fi

    # Test products.json
    PRODUCTS_RESPONSE=$(curl -s "https://$DEMO_STORE_URL/products.json")
    if echo "$PRODUCTS_RESPONSE" | grep -qi "email\|phone\|internal\|admin\|api"; then
        echo "✅ Sensitive data found in products.json"
        if command -v jq &> /dev/null; then
            echo "$PRODUCTS_RESPONSE" | jq -r '.products[] | select(.body_html | test("email|phone|internal|admin"; "i")) | .title' 2>/dev/null
        else
            echo "$PRODUCTS_RESPONSE" | grep -i "email\|phone\|internal\|admin" | head -2
        fi
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
}

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
run_scanner() {
    echo ""
    echo "🔍 Test 4: Running RegTech Security Scanner"
    echo "Scanning $DEMO_STORE_URL with our Lua plugin..."

    if [ ! -f "$SCANNER_PATH" ]; then
        echo "⚠️  Scanner not found at $SCANNER_PATH"
        echo "Trying to build scanner..."
        
        if [ -d "../backendnew" ]; then
            cd ../backendnew
            if [ -f "go.mod" ]; then
                echo "Building scanner with Go..."
                go build -o build/scanner ./cmd/scanner
                cd - > /dev/null
                
                if [ -f "$SCANNER_PATH" ]; then
                    echo "✅ Scanner built successfully"
                else
                    echo "❌ Failed to build scanner"
                    return 1
                fi
            else
                echo "❌ No go.mod found in backendnew directory"
                cd - > /dev/null
                return 1
            fi
        else
            echo "❌ backendnew directory not found"
            return 1
        fi
    fi

    echo "Running scanner command:"
    echo "$SCANNER_PATH -target \"$DEMO_STORE_URL\" -script \"shopify_security_check.lua\""
    echo ""
    
    # Run the scanner directly
    if [ -f "$SCANNER_PATH" ]; then
        "$SCANNER_PATH" -target "$DEMO_STORE_URL" -script "shopify_security_check.lua" -verbose
        SCANNER_EXIT_CODE=$?
        
        if [ $SCANNER_EXIT_CODE -eq 0 ]; then
            echo "✅ Scanner completed successfully"
        else
            echo "⚠️  Scanner exited with code $SCANNER_EXIT_CODE"
        fi
    else
        echo "❌ Scanner executable not found"
        return 1
    fi
}

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

# Main execution
main() {
    echo "Starting complete Shopify security demo setup..."
    echo ""
    
    # Step 1: Create Shopify theme ZIP
    if create_shopify_zip; then
        echo ""
        echo "📋 ZIP Contents:"
        unzip -l "$ZIP_FILE" | grep -E '\.(liquid|js|css|json)$' | awk '{print "  📄 " $4}' | sort
    else
        echo "❌ Failed to create theme package"
        exit 1
    fi
    
    # Step 2-4: Run tests
    test_hardcoded_secrets
    test_json_endpoints
    
    # Run scanner if requested
    if [ "$2" = "--run-scanner" ] || [ "$2" = "-s" ]; then
        run_scanner
    else
        echo ""
        echo "ℹ️  To run the RegTech scanner, use:"
        echo "   $0 $DEMO_STORE_URL --run-scanner"
    fi
    
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Upload $ZIP_FILE to Shopify Admin → Themes"
    echo "2. Activate the vulnerable theme"
    echo "3. Run manual tests or RegTech scanner"
    echo "4. Present security findings to audience"
    
    echo ""
    echo "🏁 Demo setup verification complete!"
    echo "Your intentionally vulnerable Shopify store is ready for security testing."
}

# Help function
show_help() {
    echo "Usage: $0 [SHOPIFY_STORE_URL] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  SHOPIFY_STORE_URL    Target Shopify store (default: regtech-security-demo.myshopify.com)"
    echo ""
    echo "Options:"
    echo "  --run-scanner, -s    Automatically run RegTech scanner after setup"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Use default store, create ZIP only"
    echo "  $0 my-demo.myshopify.com                    # Custom store URL"
    echo "  $0 my-demo.myshopify.com --run-scanner     # Run scanner automatically"
}

# Parse arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Make script executable and run main function
chmod +x "$0" 2>/dev/null || true
main "$@"