#!/bin/bash

# RegTech Vulnerable Shopify Theme - ZIP Creation Script
# Creates a properly formatted ZIP file for Shopify theme upload

echo "🎯 RegTech Vulnerable Shopify Theme Packager"
echo "============================================"

THEME_FOLDER="shopify-vulnerable-theme"
ZIP_FILE="vulnerable-shopify-theme.zip"

# Check if theme folder exists
if [ ! -d "$THEME_FOLDER" ]; then
    echo "❌ Error: Theme folder '$THEME_FOLDER' not found!"
    echo "Make sure you're running this from the demo-vulnerabilities directory."
    exit 1
fi

# Remove existing ZIP if it exists
if [ -f "$ZIP_FILE" ]; then
    echo "🗑️  Removing existing ZIP file..."
    rm -f "$ZIP_FILE"
fi

# Create ZIP file excluding README
echo "📦 Creating ZIP file for Shopify upload..."

# Change to theme directory and create ZIP with proper structure
cd "$THEME_FOLDER"

# Create ZIP excluding README.md and any system files
zip -r "../$ZIP_FILE" . \
    -x "README.md" \
    -x "*.DS_Store" \
    -x "*.git*" \
    -x "Thumbs.db" \
    -x "desktop.ini"

# Check if ZIP creation was successful
if [ $? -eq 0 ]; then
    cd ..
    
    echo "✅ Successfully created: $ZIP_FILE"
    
    # Display file info
    ZIP_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
    echo "📊 ZIP file size: $ZIP_SIZE"
    
    # List contents for verification
    echo ""
    echo "📋 ZIP Contents:"
    unzip -l "$ZIP_FILE" | grep -v "Archive:" | grep -v "Length" | grep -v "^-" | tail -n +2 | head -n -2 | while read line; do
        filename=$(echo "$line" | awk '{print $NF}')
        if [ -n "$filename" ]; then
            echo "  📄 $filename"
        fi
    done
    
    # Validate theme structure
    echo ""
    echo "🔍 Validating Shopify theme structure..."
    
    # Check for required files
    REQUIRED_FILES=("layout/theme.liquid" "templates/index.liquid")
    VALID_THEME=true
    
    for file in "${REQUIRED_FILES[@]}"; do
        if unzip -l "$ZIP_FILE" | grep -q "$file"; then
            echo "  ✅ Found required file: $file"
        else
            echo "  ❌ Missing required file: $file"
            VALID_THEME=false
        fi
    done
    
    # Check for recommended files
    RECOMMENDED_FILES=("assets/" "templates/product.liquid" "snippets/")
    
    for file in "${RECOMMENDED_FILES[@]}"; do
        if unzip -l "$ZIP_FILE" | grep -q "$file"; then
            echo "  ✅ Found recommended: $file"
        else
            echo "  ⚠️  Missing recommended: $file"
        fi
    done
    
    if [ "$VALID_THEME" = true ]; then
        echo ""
        echo "✅ Theme structure validation passed!"
        echo ""
        echo "🚀 Next Steps:"
        echo "1. Go to your Shopify Admin → Online Store → Themes"
        echo "2. Click 'Add theme' → 'Upload ZIP file'"
        echo "3. Select '$ZIP_FILE' and upload"
        echo "4. Activate the theme once uploaded"
        echo "5. Run RegTech scanner against your store"
        echo ""
        echo "📋 Test Commands After Upload:"
        echo "# Test hardcoded secrets detection"
        echo "curl -s 'https://your-store.myshopify.com/' | grep -i 'api_key\\|secret'"
        echo ""
        echo "# Test open redirect vulnerability"
        echo "curl -I 'https://your-store.myshopify.com/?redirect=https://evil-site.com'"
        echo ""
        echo "# Test JSON endpoint exposure"
        echo "curl -s 'https://your-store.myshopify.com/products.json' | jq ."
        echo ""
        echo "# Run RegTech security scan"
        echo "./scanner -target 'your-store.myshopify.com' -script 'shopify_security_check.lua'"
        echo ""
        echo "🎯 Expected Scanner Results:"
        echo "- Shopify Store Detection: ✅ YES"
        echo "- Security Score: 🔴 < 30% (CRITICAL)"
        echo "- Hardcoded Secrets: 🔴 15+ detected"
        echo "- Open Redirects: 🟠 6+ vulnerable parameters"
        echo "- Data Exposure: 🟡 Multiple sensitive endpoints"
        echo ""
        echo "⚠️  WARNING: This theme contains intentional vulnerabilities!"
        echo "Only use in development/demo environments!"
        
    else
        echo ""
        echo "❌ Theme structure validation failed!"
        echo "The ZIP file may not upload successfully to Shopify."
    fi
    
else
    echo "❌ Error creating ZIP file"
    exit 1
fi

echo ""
echo "🎯 RegTech vulnerable theme package ready for Shopify demo!"