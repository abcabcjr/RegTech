# File Upload Quick Start Guide

This guide shows how to quickly test the local file upload functionality for compliance evidence.

## 1. Start the Backend

```bash
go run ./cmd/scanner
```

The application will automatically:
- Create the `data/files/` directory for file storage
- Initialize the file service for local storage
- Set up all necessary directories

## 2. Test File Upload API

### Direct File Upload

Upload files directly using multipart form data:

```bash
curl -X POST http://localhost:8080/api/v1/files/upload \
  -F "checklist_key=global:security-policy" \
  -F "description=Company security policy document" \
  -F "file=@security-policy.pdf"
```

Response:
```json
{
  "file_id": "file_123456",
  "file_name": "security-policy.pdf",
  "content_type": "application/pdf",
  "file_size": 1024000,
  "uploaded_at": "2025-01-13T15:23:12Z",
  "status": "uploaded"
}
```

### Download File

```bash
curl http://localhost:8080/api/v1/files/file_123456/download \
  --output downloaded-file.pdf
```

## 3. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/files/upload` | Upload file directly |
| GET | `/api/v1/files/{fileId}/download` | Download file |
| GET | `/api/v1/files/{fileId}` | Get file info |
| GET | `/api/v1/files?checklistKey=...` | List files for checklist |
| DELETE | `/api/v1/files/{fileId}` | Delete file |
| GET | `/api/v1/files/supported-types` | Get supported file types |
| GET | `/api/v1/files/limits` | Get upload limits |
| GET | `/api/v1/files/status` | Get file service status |

## 4. File Storage Structure

Files are stored locally in the data directory:
```
data/
├── files/
│   ├── global_item1/
│   │   ├── file_123_document.pdf
│   │   └── file_456_screenshot.png
│   └── asset_asset123_item2/
│       └── file_789_evidence.docx
├── assets.json
├── checklist_statuses.json
└── file_attachments.json
```

## 5. Checklist Integration

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

## 6. Supported File Types

- **Images**: JPEG, PNG, GIF, WebP
- **Documents**: PDF, Word, Excel, Text, CSV
- **Data**: JSON, XML
- **Archives**: ZIP

Maximum file size: **50MB**

## 7. Environment Variables

```bash
# Storage Configuration
STORAGE_DATA_DIR=/app/data
```

## 8. Troubleshooting

### Check File Service Status
```bash
# Check if file service is available
curl http://localhost:8080/api/v1/files/status
```

Response:
```json
{
  "available": true,
  "files_dir": "/app/data/files",
  "storage_type": "local_filesystem"
}
```

### File Upload Failures
- Check file service status first: `GET /api/v1/files/status`
- Check file size (max 50MB)
- Verify content type is supported
- Ensure data directory is writable

### Storage Issues
- Files are stored in `./data/file_attachments.json` (metadata)
- Actual files are stored in `./data/files/` directory
- Ensure the data directory has proper write permissions

## 9. Docker Usage

When using Docker, ensure the data directory is properly mounted:

```yaml
services:
  asset-scanner:
    build: .
    volumes:
      - ./data:/app/data  # Files will be stored here
    environment:
      - STORAGE_DATA_DIR=/app/data
```

## 10. Clean Up

```bash
# Remove uploaded files
rm -rf data/files/

# Or just remove specific checklist files
rm -rf data/files/global_security-policy/
```

## Migration from MinIO

If you were previously using MinIO-based file storage:

1. **No migration needed** - the new system uses a separate storage mechanism
2. **Update your client code** to use the new single-step upload API
3. **Remove MinIO dependencies** from your deployment
4. **Files are now stored locally** in the data directory instead of object storage