# Makefile for Asset Scanner Backend

# Variables
BINARY_NAME=scanner
MAIN_PATH=./cmd/scanner
BUILD_DIR=build
SCRIPTS_DIR=scripts
DATA_DIR=data

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LDFLAGS=-ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)"

# Default target
.PHONY: all
all: clean build

# Build the main binary
.PHONY: build
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# Build for production (optimized)
.PHONY: build-prod
build-prod:
	@echo "Building $(BINARY_NAME) for production..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 go build $(LDFLAGS) -a -installsuffix cgo -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# Install dependencies
.PHONY: deps
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# Run the application
.PHONY: run
run: build setup-dirs
	@echo "Starting Asset Scanner..."
	cd $(BUILD_DIR) && ./$(BINARY_NAME)

# Run in development mode
.PHONY: dev
dev: setup-dirs
	@echo "Starting development server..."
	go run $(MAIN_PATH)/main.go

# Set up required directories
.PHONY: setup-dirs
setup-dirs:
	@mkdir -p $(DATA_DIR) $(SCRIPTS_DIR)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)

# Run tests
.PHONY: test
test:
	@echo "Running tests..."
	go test -v ./...

# Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Build Docker image
.PHONY: docker-build
docker-build:
	@echo "Building Docker image..."
	docker build -t asset-scanner:$(VERSION) .

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all              - Clean and build (default)"
	@echo "  build            - Build the binary"
	@echo "  build-prod       - Build optimized binary for production"
	@echo "  deps             - Install dependencies"
	@echo "  run              - Build and run the application"
	@echo "  dev              - Run in development mode"
	@echo "  setup-dirs       - Set up required directories"
	@echo "  clean            - Remove build artifacts"
	@echo "  test             - Run tests"
	@echo "  fmt              - Format code"
	@echo "  docker-build     - Build Docker image"
	@echo "  help             - Show this help message"

# Development setup
.PHONY: dev-setup
dev-setup: deps setup-dirs
	@echo "Development environment set up successfully!"
	@echo "Run 'make dev' to start the development server"