# File Upload Quick Start Guide

This guide shows how to quickly test the MinIO-based file upload functionality for compliance evidence.

## 1. Start MinIO

Run the provided script to start MinIO:

```bash
./start-minio.sh
```

Or manually with docker-compose:

```bash
docker-compose -f docker-compose.minio.yml up -d
```

MinIO will be available at:
- **API**: http://localhost:9000
- **Console**: http://localhost:9001
- **Username**: minioadmin
- **Password**: minioadmin

## 2. Start the Backend

```bash
go run ./cmd/scanner
```

The application will automatically:
- Try to connect to MinIO
- Create the `compliance-evidence` bucket if MinIO is available
- Initialize the file service (gracefully degrades if MinIO is unavailable)

**Note**: If MinIO is not running, the backend will still start successfully but file upload operations will return errors until MinIO becomes available.

## 3. Test File Upload API

### Step 1: Initiate Upload

```bash
curl -X POST http://localhost:8080/api/v1/files/upload/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "checklist_key": "global:security-policy",
    "file_name": "security-policy.pdf",
    "content_type": "application/pdf",
    "file_size": 1024000,
    "description": "Company security policy document"
  }'
```

Response:
```json
{
  "file_id": "file_123456",
  "upload_url": "http://localhost:9000/compliance-evidence/compliance/global%3Asecurity-policy/file_123456_security-policy.pdf?X-Amz-Algorithm=...",
  "expires_at": "2025-01-13T15:23:12Z",
  "method": "PUT"
}
```

### Step 2: Upload File

Use the returned `upload_url` to upload your file:

```bash
curl -X PUT "http://localhost:9000/compliance-evidence/..." \
  -H "Content-Type: application/pdf" \
  --data-binary @your-file.pdf
```

### Step 3: Confirm Upload

```bash
curl -X POST http://localhost:8080/api/v1/files/file_123456/confirm
```

### Step 4: Generate Download URL

```bash
curl http://localhost:8080/api/v1/files/file_123456/download
```

## 4. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/files/upload/initiate` | Create upload URL |
| POST | `/api/v1/files/{fileId}/confirm` | Confirm upload |
| GET | `/api/v1/files/{fileId}/download` | Get download URL |
| GET | `/api/v1/files/{fileId}` | Get file info |
| GET | `/api/v1/files?checklistKey=...` | List files for checklist |
| DELETE | `/api/v1/files/{fileId}` | Delete file |
| GET | `/api/v1/files/supported-types` | Get supported file types |
| GET | `/api/v1/files/limits` | Get upload limits |
| GET | `/api/v1/files/status` | Get file service status |

## 5. File Storage Structure

Files are stored in MinIO with this structure:
```
compliance-evidence/
├── compliance/
│   ├── global:item1/
│   │   ├── file_123_document.pdf
│   │   └── file_456_screenshot.png
│   └── asset:asset123:item2/
│       └── file_789_evidence.docx
```

## 6. Checklist Integration

Files are automatically linked to checklist items. When you retrieve checklist status:

```bash
curl http://localhost:8080/api/v1/checklist/global
```

The response includes file attachments:

```json
{
  "id": "security-policy",
  "title": "Security Policy Review",
  "status": "yes",
  "attachments": ["file_123456"],
  "notes": "Policy reviewed and approved"
}
```

## 7. Supported File Types

- **Images**: JPEG, PNG, GIF, WebP
- **Documents**: PDF, Word, Excel, Text, CSV
- **Data**: JSON, XML
- **Archives**: ZIP

Maximum file size: **50MB**

## 8. Environment Variables

```bash
# MinIO Configuration
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY_ID=minioadmin
MINIO_SECRET_ACCESS_KEY=minioadmin
MINIO_USE_SSL=false
MINIO_BUCKET_NAME=compliance-evidence
MINIO_REGION=us-east-1
MINIO_PRESIGN_DURATION=1h
```

## 9. Troubleshooting

### Check File Service Status
```bash
# Check if file service is available
curl http://localhost:8080/api/v1/files/status
```

Response when MinIO is unavailable:
```json
{
  "available": false,
  "endpoint": "localhost:9000",
  "bucket": "compliance-evidence",
  "error": "MinIO service is not accessible"
}
```

### MinIO Connection Issues
```bash
# Check if MinIO is running
curl http://localhost:9000/minio/health/live

# View MinIO logs
docker-compose -f docker-compose.minio.yml logs minio
```

### File Upload Failures
- Check file service status first: `GET /api/v1/files/status`
- Check file size (max 50MB)
- Verify content type is supported
- Ensure MinIO bucket exists
- Check presigned URL hasn't expired

### Storage Issues
- Files are stored in `./data/file_attachments.json`
- MinIO data is persisted in Docker volume `minio_data`

## 10. Clean Up

```bash
# Stop MinIO
docker-compose -f docker-compose.minio.yml down

# Remove MinIO data (optional)
docker-compose -f docker-compose.minio.yml down -v
```
