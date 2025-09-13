param(
    [string]$JsonFile = "checklist_templates_full.json",
    [string]$BaseUrl = "http://localhost:8080/api/v1",
    [switch]$Help
)

# Script to upload checklist templates from a JSON file to RegTech backend
# Author: AI Assistant
# Version: 1.1

# Show help if requested
if ($Help) {
    Write-Host "Checklist Templates Upload Script" -ForegroundColor Blue
    Write-Host "==================================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "    Uploads checklist templates from a JSON file to the RegTech backend API"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "    .\upload_templates.ps1 [-JsonFile <path>] [-BaseUrl <url>] [-Help]"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "    -JsonFile    Path to the JSON file containing templates (default: checklist_templates_full.json)"
    Write-Host "    -BaseUrl     Backend API base URL (default: http://localhost:8080/api/v1)"
    Write-Host "    -Help        Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "    .\upload_templates.ps1"
    Write-Host "    .\upload_templates.ps1 -JsonFile 'my_templates.json'"
    Write-Host "    .\upload_templates.ps1 -BaseUrl 'https://api.example.com/v1'"
    Write-Host "    .\upload_templates.ps1 -JsonFile 'templates.json' -BaseUrl 'http://localhost:9000/api/v1'"
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "    - PowerShell 5.0 or later"
    Write-Host "    - Network access to the backend API"
    Write-Host "    - Valid JSON file with checklist templates"
    Write-Host ""
    exit 0
}

# Validate parameters
if ([string]::IsNullOrWhiteSpace($JsonFile)) {
    Write-Host "Error: JsonFile parameter cannot be empty" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    Write-Host "Error: BaseUrl parameter cannot be empty" -ForegroundColor Red
    exit 1
}

Write-Host "Checklist Templates Upload Script" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue
Write-Host "JSON file: $JsonFile"
Write-Host "Backend URL: $BaseUrl"
Write-Host ""

# Get the full path to the JSON file (check current directory and parent directory)
$fullJsonPath = $null
if (Test-Path $JsonFile) {
    $fullJsonPath = $JsonFile
} elseif (Test-Path "../$JsonFile") {
    $fullJsonPath = "../$JsonFile"
    Write-Host "Found JSON file in parent directory: $fullJsonPath" -ForegroundColor Yellow
} else {
    Write-Host "Error: JSON file '$JsonFile' not found!" -ForegroundColor Red
    Write-Host "Searched in current directory and parent directory." -ForegroundColor Red
    Write-Host "Usage: .\upload_templates.ps1 [-JsonFile ""file.json""] [-BaseUrl ""http://localhost:8080/api/v1""]"
    Write-Host "Example: .\upload_templates.ps1 -JsonFile ""checklist_templates_full.json"""
    exit 1
}

# Validate JSON syntax
try {
    $jsonContent = Get-Content $fullJsonPath -Raw | ConvertFrom-Json
    $templateCount = $jsonContent.templates.Count
    Write-Host "✓ JSON file validation successful" -ForegroundColor Green
} catch {
    Write-Host "Error: Invalid JSON syntax in '$fullJsonPath'" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test backend connection first
Write-Host "Testing backend connection..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 5
    Write-Host "✓ Backend connection successful" -ForegroundColor Green
} catch {
    Write-Host "⚠ Backend health check failed, but continuing..." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Found $templateCount templates in JSON file" -ForegroundColor Blue
Write-Host ""
Write-Host "Uploading templates..." -ForegroundColor Yellow

# Upload templates
try {
    $jsonData = Get-Content $fullJsonPath -Raw
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    Write-Host "Sending POST request to: $BaseUrl/checklist/templates/upload" -ForegroundColor Cyan
    Write-Host "Payload size: $($jsonData.Length) characters" -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri "$BaseUrl/checklist/templates/upload" -Method Post -Body $jsonData -Headers $headers -TimeoutSec 60
    
    Write-Host "✓ Templates uploaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Blue
    if ($response) {
        $response | ConvertTo-Json -Depth 10
    } else {
        Write-Host "No response body returned" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "✗ Upload failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Enhanced error handling for PowerShell Web exceptions
    if ($_.Exception -is [System.Net.WebException]) {
        $webException = $_.Exception
        if ($webException.Response) {
            $statusCode = $webException.Response.StatusCode
            $statusDescription = $webException.Response.StatusDescription
            Write-Host "HTTP Status: $statusCode - $statusDescription" -ForegroundColor Red
            
            try {
                $errorStream = $webException.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                $reader.Close()
                Write-Host "Response body: $errorBody" -ForegroundColor Red
            } catch {
                Write-Host "Could not read error response body" -ForegroundColor Red
            }
        }
    } elseif ($_.Exception.Response) {
        # Handle other HTTP exceptions
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "HTTP Status: $statusCode" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure the backend server is running on $BaseUrl" -ForegroundColor Yellow
    Write-Host "2. Check if the endpoint /checklist/templates/upload exists" -ForegroundColor Yellow
    Write-Host "3. Verify the JSON format matches the expected schema" -ForegroundColor Yellow
    Write-Host "4. Check server logs for detailed error information" -ForegroundColor Yellow
    
    exit 1
}

Write-Host ""
Write-Host "Verifying upload..." -ForegroundColor Blue

# Verify by listing templates
try {
    $verifyResponse = Invoke-RestMethod -Uri "$BaseUrl/checklist/templates" -Method Get -TimeoutSec 10
    
    # Handle different response formats
    $uploadedCount = 0
    if ($verifyResponse -is [Array]) {
        $uploadedCount = $verifyResponse.Count
    } elseif ($verifyResponse.templates) {
        $uploadedCount = $verifyResponse.templates.Count
    } elseif ($verifyResponse.data) {
        $uploadedCount = $verifyResponse.data.Count
    } elseif ($verifyResponse.Count) {
        $uploadedCount = $verifyResponse.Count
    } else {
        $uploadedCount = 1  # Single template response
    }
    
    if ($uploadedCount -eq $templateCount) {
        Write-Host "✓ Verification successful: $uploadedCount templates now available" -ForegroundColor Green
    } else {
        Write-Host "⚠ Template count mismatch: Expected $templateCount, found $uploadedCount" -ForegroundColor Yellow
        Write-Host "This might be normal if templates were merged or already existed" -ForegroundColor Gray
    }
    
    Write-Host "✓ Upload verification completed" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not verify upload (this does not mean upload failed)" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You can manually check the backend logs or frontend to verify templates" -ForegroundColor Gray
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Blue
Write-Host "Upload process completed!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Check the backend logs for any warnings" -ForegroundColor White
Write-Host "2. Visit the frontend compliance page to verify templates" -ForegroundColor White
Write-Host "3. Test the checklist functionality" -ForegroundColor White
Write-Host ""
Write-Host "If you encounter issues:" -ForegroundColor Yellow
Write-Host "- Check that the backend server is running" -ForegroundColor White
Write-Host "- Verify the API endpoints are accessible" -ForegroundColor White
Write-Host "- Review the JSON file format" -ForegroundColor White
Write-Host ""