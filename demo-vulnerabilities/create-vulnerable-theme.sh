#!/bin/bash

# RegTech Vulnerable Shopify Theme Packager
# Creates a ZIP file ready for Shopify upload

echo "🔴 Creating Vulnerable Shopify Theme Package"
echo "This theme contains intentional security vulnerabilities for testing"

THEME_DIR="shopify-vulnerable-theme"
ZIP_NAME="vulnerable-shopify-theme-$(date +%Y%m%d).zip"

# Check if theme directory exists
if [ ! -d "$THEME_DIR" ]; then
    echo "❌ Error: Theme directory '$THEME_DIR' not found"
    exit 1
fi

# Remove old zip files
rm -f vulnerable-shopify-theme-*.zip

# Create the ZIP package
echo "📦 Packaging theme files..."
cd "$THEME_DIR"

zip -r "../$ZIP_NAME" . \
    -x "*.DS_Store" "*.git*" "*.md" \
    2>/dev/null

cd ..

if [ -f "$ZIP_NAME" ]; then
    echo "✅ Theme package created: $ZIP_NAME"
    echo ""
    echo "📋 UPLOAD INSTRUCTIONS:"
    echo "1. Go to your Shopify admin: https://yourstore.myshopify.com/admin/themes"
    echo "2. Click 'Upload theme'"
    echo "3. Select file: $ZIP_NAME"
    echo "4. Once uploaded, click 'Actions > Preview' to activate"
    echo ""
    echo "🎯 TESTING INSTRUCTIONS:"
    echo "After upload, test with RegTech scanner:"
    echo "./scanner --target yourstore.myshopify.com --script shopify_security_check.lua"
    echo ""
    echo "🔴 EXPECTED VULNERABILITIES TO BE DETECTED:"
    echo "- 15+ hardcoded API keys and secrets"
    echo "- 6+ open redirect vulnerabilities" 
    echo "- Customer PII exposure via JSON endpoints"
    echo "- Business intelligence data leakage"
    echo "- Development configuration in production"
    echo "- CSRF and postMessage vulnerabilities"
    echo ""
    echo "⚠️  WARNING: This theme is intentionally vulnerable!"
    echo "    Only use in development/testing environments"
    echo "    Do not use with real customer data"
else
    echo "❌ Error creating ZIP package"
    exit 1
fi