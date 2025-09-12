# Makefile for RegTech Backend

# Variables
BINARY_NAME=backend
SCRIPT_DIR=scripts
BUILD_DIR=build

# Default target
.PHONY: all
all: clean build scripts

# Build the main backend binary
.PHONY: build
build:
	@echo "Building backend binary..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) main.go


# Copy Lua scripts to build directory
.PHONY: scripts
scripts:
	@echo "Copying Lua scripts..."
	@mkdir -p $(BUILD_DIR)/$(SCRIPT_DIR)
	@cp -r $(SCRIPT_DIR)/*.lua $(BUILD_DIR)/$(SCRIPT_DIR)/ 2>/dev/null || true

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)

# Run the backend (assumes recontool is built)
.PHONY: run
run: all
	@echo "Running backend..."
	cd $(BUILD_DIR) && ./$(BINARY_NAME) \
		--recontool ../../recontool/regtech \
		--scripts ./$(SCRIPT_DIR) \
		--verbose \
		example.com

# Run with custom targets
.PHONY: run-targets
run-targets: all
	@echo "Running backend with custom targets..."
	@if [ -z "$(TARGETS)" ]; then \
		echo "Usage: make run-targets TARGETS='domain1.com domain2.com'"; \
		exit 1; \
	fi
	cd $(BUILD_DIR) && ./$(BINARY_NAME) \
		--recontool ../../recontool/regtech \
		--scripts ./$(SCRIPT_DIR) \
		--verbose \
		$(TARGETS)

# Build and test with a simple target
.PHONY: test
test: all
	@echo "Testing backend with google.com..."
	cd $(BUILD_DIR) && timeout 60 ./$(BINARY_NAME) \
		--recontool ../../recontool/regtech \
		--scripts ./$(SCRIPT_DIR) \
		--verbose \
		--output test_results.json \
		google.com || true

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all       - Build everything (default)"
	@echo "  build     - Build the main backend binary"
	@echo "  scripts   - Copy Lua scripts to build directory"
	@echo "  clean     - Remove build artifacts"
	@echo "  run       - Build and run with example.com"
	@echo "  run-targets - Build and run with custom targets (use TARGETS='...')"
	@echo "  test      - Build and run a quick test with google.com"
	@echo "  help      - Show this help message"

# Development targets
.PHONY: dev-watch
dev-watch:
	@echo "Watching for changes..."
	@while true; do \
		inotifywait -r -e modify,create,delete . 2>/dev/null || sleep 2; \
		make all scripts; \
	done
