# RegTech Vulnerable Shopify Theme - ZIP Creation Script
# Creates a properly formatted ZIP file for Shopify theme upload

Write-Host "🎯 RegTech Vulnerable Shopify Theme Packager" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$ThemeFolder = "shopify-vulnerable-theme"
$ZipFile = "vulnerable-shopify-theme.zip"

# Check if theme folder exists
if (!(Test-Path $ThemeFolder)) {
    Write-Host "❌ Error: Theme folder '$ThemeFolder' not found!" -ForegroundColor Red
    Write-Host "Make sure you're running this from the demo-vulnerabilities directory." -ForegroundColor Yellow
    exit 1
}

# Remove existing ZIP if it exists
if (Test-Path $ZipFile) {
    Write-Host "🗑️  Removing existing ZIP file..." -ForegroundColor Yellow
    Remove-Item $ZipFile -Force
}

# Create ZIP file excluding README
Write-Host "📦 Creating ZIP file for Shopify upload..." -ForegroundColor Green

try {
    # Get all files except README.md
    $filesToZip = Get-ChildItem -Path $ThemeFolder -Recurse | Where-Object { 
        $_.Name -ne "README.md" -and 
        !$_.PSIsContainer
    }
    
    # Create ZIP using .NET compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::Open($ZipFile, 'Create')
    
    foreach ($file in $filesToZip) {
        # Get relative path from theme folder
        $relativePath = $file.FullName.Substring((Resolve-Path $ThemeFolder).Path.Length + 1)
        
        # Add file to ZIP
        $entry = $zip.CreateEntry($relativePath)
        $entryStream = $entry.Open()
        $fileStream = [System.IO.File]::OpenRead($file.FullName)
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
        
        Write-Host "  ✅ Added: $relativePath" -ForegroundColor Gray
    }
    
    $zip.Dispose()
    
    Write-Host "✅ Successfully created: $ZipFile" -ForegroundColor Green
    
    # Display file info
    $zipInfo = Get-Item $ZipFile
    Write-Host "📊 ZIP file size: $([math]::Round($zipInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    
    # List contents for verification
    Write-Host "`n📋 ZIP Contents:" -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipFile)
    foreach ($entry in $archive.Entries | Sort-Object FullName) {
        Write-Host "  📄 $($entry.FullName)" -ForegroundColor Gray
    }
    $archive.Dispose()
    
    Write-Host "`n🚀 Next Steps:" -ForegroundColor Green
    Write-Host "1. Go to your Shopify Admin → Online Store → Themes" -ForegroundColor White
    Write-Host "2. Click 'Add theme' → 'Upload ZIP file'" -ForegroundColor White  
    Write-Host "3. Select '$ZipFile' and upload" -ForegroundColor White
    Write-Host "4. Activate the theme once uploaded" -ForegroundColor White
    Write-Host "5. Run RegTech scanner against your store" -ForegroundColor White
    
    Write-Host "`n⚠️  WARNING: This theme contains intentional vulnerabilities!" -ForegroundColor Yellow
    Write-Host "Only use in development/demo environments!" -ForegroundColor Yellow

} catch {
    Write-Host "❌ Error creating ZIP file: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 RegTech theme package ready for demo!" -ForegroundColor Cyan