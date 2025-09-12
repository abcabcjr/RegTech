#!/bin/bash

# Build and Run Script for RegTech Go Project

echo "Building the RegTech CLI tool..."
go build -o regtech main.go

if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # If arguments provided, run with them
    if [ $# -gt 0 ]; then
        echo "Running: ./regtech $@"
        echo "----------------------------------------"
        ./regtech "$@"
        echo "----------------------------------------"
    else
        echo "Usage: ./build_and_run.sh [options] <domains/subdomains/ips...>"
        echo ""
        echo "Examples:"
        echo "  ./build_and_run.sh example.com"
        echo "  ./build_and_run.sh -v example.com google.com"
        echo "  ./build_and_run.sh -o results.json example.com"
        echo ""
        echo "Options:"
        echo "  -v, --verbose    Enable verbose output"
        echo "  -o, --output     Output file for JSON results"
        echo ""
        echo "To see full help: ./regtech --help"
    fi
else
    echo "Build failed!"
    exit 1
fi
