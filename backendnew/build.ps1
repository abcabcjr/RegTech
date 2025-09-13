param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Target,
    [switch]$Prod
)

# ------------------------------
# Variables
# ------------------------------
$binaryName = "scanner.exe"
$mainPath   = "./cmd/scanner"
$buildDir   = "build"
$dataDir    = "data"
$scriptsDir = "scripts"

# Version Info
$version = (git describe --tags --always --dirty 2>$null) -join ""
if (-not $version) { $version = "dev" }

$commit = (git rev-parse --short HEAD 2>$null) -join ""
if (-not $commit) { $commit = "unknown" }

$date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Build Flags
$ldflags = "-ldflags `" -X main.version=$version -X main.commit=$commit -X main.date=$date `""


# ------------------------------
# Utility Functions
# ------------------------------
function Build {
    Write-Host "Building $binaryName..."
    if (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    }
    if ($Prod) {
        Write-Host "Building production binary..."
        $env:CGO_ENABLED = "0"
        go build -a -installsuffix cgo -o "$buildDir\$binaryName" $mainPath
    } else {
        go build -o "$buildDir\$binaryName" $mainPath
    }
}

function Run {
    SetupDirs
    Build
    Write-Host "Starting Asset Scanner..."
    Start-Process -NoNewWindow -Wait -WorkingDirectory $buildDir ".\$binaryName"
}

function Dev {
    SetupDirs
    Write-Host "Starting development server..."
    go run "$mainPath/main.go"
}

function SetupDirs {
    foreach ($d in @($dataDir, $scriptsDir)) {
        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d | Out-Null
            Write-Host "Created $d"
        }
    }
}

function Clean {
    Write-Host "Cleaning build artifacts..."
    Remove-Item -Recurse -Force $buildDir -ErrorAction SilentlyContinue
}

function Deps {
    Write-Host "Installing dependencies..."
    go mod download
    go mod tidy
}

function Test {
    Write-Host "Running tests..."
    go test -v ./...
}

function Fmt {
    Write-Host "Formatting code..."
    go fmt ./...
}

function DockerBuild {
    Write-Host "Building Docker image..."
    docker build -t "asset-scanner:$version" .
}

function DevSetup {
    Deps
    SetupDirs
    Write-Host "Development environment set up successfully!"
    Write-Host "Run '.\build.ps1 dev' to start the development server"
}

function Help {
    @"
Available targets:
  build          - Build the binary
  build -Prod    - Build optimized binary for production
  run            - Build and run the application
  dev            - Run in development mode
  setup-dirs     - Set up required directories
  clean          - Remove build artifacts
  deps           - Install dependencies
  test           - Run tests
  fmt            - Format code
  docker-build   - Build Docker image
  dev-setup      - Prepare dev environment (deps + dirs)
  help           - Show this help message
"@ | Write-Host
}

# ------------------------------
# Dispatcher
# ------------------------------
switch ($Target.ToLower()) {
    "build"        { Build }
    "run"          { Run }
    "dev"          { Dev }
    "setup-dirs"   { SetupDirs }
    "clean"        { Clean }
    "deps"         { Deps }
    "test"         { Test }
    "fmt"          { Fmt }
    "docker-build" { DockerBuild }
    "dev-setup"    { DevSetup }
    "help"         { Help }
    default        { Write-Host "Unknown target: $Target"; Help }
}