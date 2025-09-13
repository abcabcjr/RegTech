#!/bin/bash

# Simple script to create ZIP file ready for Shopify upload
# This creates a properly formatted theme ZIP from the vulnerable theme folder

echo "🎯 Creating Shopify Theme ZIP"
echo "============================="

THEME_FOLDER="shopify-vulnerable-theme"
ZIP_FILE="vulnerable-shopify-theme.zip"

# Check if theme folder exists
if [ ! -d "$THEME_FOLDER" ]; then
    echo "❌ Error: Theme folder '$THEME_FOLDER' not found!"
    echo "Make sure you're in the demo-vulnerabilities directory"
    exit 1
fi

# Check if zip command is available
if ! command -v zip &> /dev/null; then
    echo "❌ Error: 'zip' command not found"
    echo "Please install zip utility:"
    echo "  Ubuntu/Debian: sudo apt-get install zip"
    echo "  CentOS/RHEL: sudo yum install zip" 
    echo "  macOS: zip should be available by default"
    exit 1
fi

# Remove existing ZIP file
if [ -f "$ZIP_FILE" ]; then
    echo "🗑️  Removing existing ZIP file..."
    rm -f "$ZIP_FILE"
fi

echo "📦 Creating ZIP file for Shopify upload..."

# Create ZIP file excluding README and system files
cd "$THEME_FOLDER" || exit 1

zip -r "../$ZIP_FILE" . \
    -x "README.md" \
    -x ".*" \
    -x "*~" \
    -x "*.DS_Store" \
    -x "__pycache__/*" || {
    echo "❌ Error creating ZIP file"
    cd .. || exit 1
    exit 1
}

cd .. || exit 1

# Verify ZIP file was created
if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ ZIP file was not created"
    exit 1
fi

# Show file info
FILE_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
echo "✅ Successfully created: $ZIP_FILE ($FILE_SIZE)"

# List ZIP contents
echo ""
echo "📋 Theme files included:"
unzip -l "$ZIP_FILE" | grep -v "Archive:\|Length\|----\|files" | grep -E '\.(liquid|js|css|json)$' | \
    awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | \
    sed 's/^/  📄 /' | sort

echo ""
echo "🚀 Upload Instructions:"
echo "1. Go to Shopify Admin → Online Store → Themes"
echo "2. Click 'Add theme' → 'Upload ZIP file'"
echo "3. Select '$ZIP_FILE'"
echo "4. Click 'Upload' and wait for processing"
echo "5. Click 'Actions' → 'Publish' to activate the theme"

echo ""
echo "⚠️  WARNING: This theme contains intentional security vulnerabilities!"
echo "Only use in development or demo environments!"

echo ""
echo "🎯 Ready for Shopify upload!"