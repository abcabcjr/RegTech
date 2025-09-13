#!/bin/bash

# Start MinIO for testing file upload functionality
echo "Starting MinIO for compliance file storage..."

# Stop any existing MinIO container
docker-compose -f docker-compose.minio.yml down

# Start MinIO
docker-compose -f docker-compose.minio.yml up -d

# Wait for MinIO to be ready
echo "Waiting for MinIO to start..."
sleep 10

# Check if MinIO is running
if curl -f http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    echo "✅ MinIO is running successfully!"
    echo "📊 MinIO Console: http://localhost:9001"
    echo "🔑 Username: minioadmin"
    echo "🔑 Password: minioadmin"
    echo ""
    echo "You can now start your Go application with:"
    echo "  go run ./cmd/scanner"
    echo ""
    echo "The bucket 'compliance-evidence' will be created automatically."
else
    echo "❌ MinIO failed to start properly"
    echo "Check the logs with: docker-compose -f docker-compose.minio.yml logs"
fi
