param(
    [string]$JsonFile = "checklist_templates_full.json",
    [string]$BaseUrl = "http://localhost:8080/api/v1"
)

# Script to upload checklist templates from a JSON file
# Usage: .\upload_templates.ps1 [-JsonFile "file.json"] [-BaseUrl "http://localhost:8080/api/v1"]

Write-Host "Checklist Templates Upload Script" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue
Write-Host "JSON file: $JsonFile"
Write-Host "Backend URL: $BaseUrl"
Write-Host ""

# Check if JSON file exists
if (-not (Test-Path $JsonFile)) {
    Write-Host "Error: JSON file '$JsonFile' not found!" -ForegroundColor Red
    Write-Host "Usage: .\upload_templates.ps1 [-JsonFile `"file.json`"] [-BaseUrl `"http://localhost:8080/api/v1`"]"
    Write-Host "Example: .\upload_templates.ps1 -JsonFile `"checklist_templates_full.json`""
    exit 1
}

# Validate JSON syntax
try {
    $jsonContent = Get-Content $JsonFile -Raw | ConvertFrom-Json
    $templateCount = $jsonContent.templates.Count
} catch {
    Write-Host "Error: Invalid JSON syntax in '$JsonFile'" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "Validating backend connection..." -ForegroundColor Yellow
Write-Host "Found $templateCount templates in JSON file" -ForegroundColor Blue
Write-Host ""
Write-Host "Uploading templates..." -ForegroundColor Yellow

# Upload templates
try {
    $jsonData = Get-Content $JsonFile -Raw
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/checklist/templates/upload" -Method Post -Body $jsonData -Headers $headers -TimeoutSec 30
    
    Write-Host "✓ Templates uploaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Blue
    $response | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "✗ Upload failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status: $statusCode" -ForegroundColor Red
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Response body: $errorBody" -ForegroundColor Red
        } catch {
            Write-Host "Could not read error response body" -ForegroundColor Red
        }
    }
    exit 1
}

Write-Host ""
Write-Host "Verifying upload..." -ForegroundColor Blue

# Verify by listing templates
try {
    $verifyResponse = Invoke-RestMethod -Uri "$BaseUrl/checklist/templates" -Method Get -TimeoutSec 10
    $uploadedCount = $verifyResponse.Count
    
    if ($uploadedCount -eq $templateCount) {
        Write-Host "✓ Verification successful: $uploadedCount templates now available" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: Expected $templateCount templates, but found $uploadedCount" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not verify upload" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Upload complete!" -ForegroundColor Green
Write-Host "You can now view the templates in the frontend compliance page."
