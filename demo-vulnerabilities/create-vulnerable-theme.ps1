# RegTech Vulnerable Shopify Theme Packager for Windows
# Creates a ZIP file ready for Shopify upload

Write-Host "🔴 Creating Vulnerable Shopify Theme Package" -ForegroundColor Red
Write-Host "This theme contains intentional security vulnerabilities for testing" -ForegroundColor Yellow

$ThemeDir = "shopify-vulnerable-theme"
$ZipName = "vulnerable-shopify-theme-$(Get-Date -Format 'yyyyMMdd').zip"

# Check if theme directory exists
if (-not (Test-Path $ThemeDir)) {
    Write-Host "❌ Error: Theme directory '$ThemeDir' not found" -ForegroundColor Red
    exit 1
}

# Remove old zip files
Get-ChildItem -Path . -Filter "vulnerable-shopify-theme-*.zip" | Remove-Item -Force

# Create the ZIP package
Write-Host "📦 Packaging theme files..." -ForegroundColor Cyan

try {
    # Use .NET compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($ThemeDir, $ZipName)
    
    Write-Host "✅ Theme package created: $ZipName" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 UPLOAD INSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "1. Go to your Shopify admin: https://yourstore.myshopify.com/admin/themes"
    Write-Host "2. Click 'Upload theme'" 
    Write-Host "3. Select file: $ZipName"
    Write-Host "4. Once uploaded, click 'Actions > Preview' to activate"
    Write-Host ""
    Write-Host "🎯 TESTING INSTRUCTIONS:" -ForegroundColor Magenta
    Write-Host "After upload, test with RegTech scanner:"
    Write-Host ".\scanner.exe --target yourstore.myshopify.com --script shopify_security_check.lua"
    Write-Host ""
    Write-Host "🔴 EXPECTED VULNERABILITIES TO BE DETECTED:" -ForegroundColor Red
    Write-Host "- 20+ hardcoded API keys and secrets (CRITICAL)"
    Write-Host "- 8+ open redirect vulnerabilities (HIGH)" 
    Write-Host "- Customer PII exposure via JSON endpoints (CRITICAL)"
    Write-Host "- Business intelligence data leakage (HIGH)"
    Write-Host "- Development configuration in production (MEDIUM)"
    Write-Host "- CSRF and postMessage vulnerabilities (HIGH)"
    Write-Host "- Information disclosure in HTML comments (MEDIUM)"
    Write-Host "- Sensitive data in JavaScript console logs (LOW)"
    Write-Host ""
    Write-Host "📊 EXPECTED SCANNER RESULTS:" -ForegroundColor Yellow
    Write-Host "Security Score: 10-30% (CRITICAL ISSUES DETECTED)"
    Write-Host "Risk Level: CRITICAL"
    Write-Host "Compliance Status: FAIL"
    Write-Host ""
    Write-Host "⚠️  WARNING: This theme is intentionally vulnerable!" -ForegroundColor Red
    Write-Host "    Only use in development/testing environments" -ForegroundColor Red
    Write-Host "    Do not use with real customer data" -ForegroundColor Red
    Write-Host ""
    
    # Display file size
    $FileSize = (Get-Item $ZipName).Length
    $FileSizeKB = [math]::Round($FileSize / 1KB, 2)
    Write-Host "📁 Package size: $FileSizeKB KB" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Error creating ZIP package: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}