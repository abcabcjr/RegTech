# OSS Bucket Security Plugins

This directory contains two Lua plugins for detecting and analyzing Object Storage Service (OSS) buckets for security misconfigurations.

## Plugins Overview

### 1. `oss_bucket_detector.lua`
**Purpose**: Detect OSS buckets from various cloud providers
- **Category**: cloud_security
- **Asset Types**: domain, subdomain, service
- **Dependencies**: basic_info.lua

**Features**:
- Detects OSS buckets from multiple cloud providers:
  - Amazon S3
  - Google Cloud Storage (GCS)
  - Microsoft Azure Blob Storage
  - Alibaba Cloud OSS
  - Tencent Cloud COS
  - Huawei Cloud OBS
  - DigitalOcean Spaces
  - Backblaze B2
  - Wasabi
  - IBM Cloud Object Storage
  - Oracle Cloud Infrastructure Object Storage
  - CDN endpoints (potential OSS backends)

- Extracts bucket names and metadata
- Probes endpoints to confirm OSS presence
- Analyzes response headers and content for OSS-specific information
- Tags assets with appropriate OSS provider and service type

**Tags Added**:
- `oss-bucket`: General OSS bucket indicator
- `oss-{service_type}`: Specific service type (e.g., `oss-s3`, `oss-gcs`)
- `cloud-storage`: General cloud storage indicator
- `oss-responsive`: Endpoint responds to probes
- `oss-unresponsive`: Endpoint detected but not responsive
- `oss-listable`: Bucket contents are listable
- `oss-directory-listing`: HTML directory listing detected
- `oss-access-denied`: Access denied (bucket exists but protected)
- `oss-endpoint-confirmed`: OSS endpoint confirmed via error messages

### 2. `oss_bucket_security_check.lua`
**Purpose**: Check OSS buckets for permission misconfigurations and security issues
- **Category**: cloud_security
- **Asset Types**: domain, subdomain, service
- **Dependencies**: oss_bucket_detector.lua

**Features**:
- Comprehensive security testing for OSS buckets
- Provider-specific security tests
- Permission misconfiguration detection
- CORS policy analysis
- Configuration assessment (versioning, encryption, logging)

**Security Tests**:

#### Common Tests (All Providers)
1. **Public Read Test**: Checks if bucket contents are publicly listable
2. **Public Write Test**: Tests for public write access permissions
3. **Anonymous Access Test**: Tests access to sensitive paths
4. **CORS Configuration Test**: Checks for overly permissive CORS settings

#### Provider-Specific Tests
- **Amazon S3**: ACL tests, bucket policy analysis, website configuration
- **Azure Blob Storage**: Container ACL analysis
- **Google Cloud Storage**: IAM configuration testing

**Security Levels**:
- **CRITICAL**: Immediate security risk (public read/write access)
- **HIGH**: Significant security concern (authenticated user access)
- **MEDIUM**: Configuration issues requiring review
- **PASS**: Properly configured security

**Tags Added**:
- `oss-critical-security-issue`: Critical security problems found
- `oss-high-security-issue`: High-risk security issues found
- `oss-medium-security-issue`: Medium-risk security issues found
- `oss-security-good`: Good security configuration
- `oss-versioning-enabled`: Versioning is enabled
- `oss-encryption-configured`: Encryption is configured
- `oss-logging-configured`: Logging is configured

## Usage

### Running the Plugins

1. **Detection Phase**: Run `oss_bucket_detector.lua` first
   ```bash
   # This will detect OSS buckets and tag them appropriately
   ```

2. **Security Analysis Phase**: Run `oss_bucket_security_check.lua`
   ```bash
   # This will only run on assets tagged as OSS buckets
   ```

### Integration with Asset Management System

These plugins integrate with the Asset Management System's scanning workflow:

1. Add the scripts to your scanning configuration
2. The detector runs during the discovery phase
3. The security check runs automatically on detected OSS buckets
4. Results are stored as metadata and tags on the asset

### Example Asset After Scanning

```json
{
  "id": "asset_123",
  "type": "domain",
  "value": "mybucket.s3.amazonaws.com",
  "tags": [
    "oss-bucket",
    "oss-s3",
    "cloud-storage",
    "oss-responsive",
    "oss-critical-security-issue"
  ],
  "properties": {
    "oss_detected": true,
    "oss_provider": "Amazon S3",
    "oss_service_type": "s3",
    "oss_bucket_name": "mybucket",
    "oss_security_score": 40,
    "oss_critical_issues": 1,
    "oss_high_issues": 0,
    "oss_medium_issues": 0
  }
}
```

## Security Implications

### Critical Issues Found
- **Public Read Access**: Bucket contents can be listed by anyone
- **Public Write Access**: Anyone can upload files to the bucket
- **Sensitive File Exposure**: Configuration files, backups, or credentials exposed

### Recommended Actions
1. **Immediate**: Block public access if not required
2. **Review**: Audit bucket policies and ACLs
3. **Monitor**: Enable logging and monitoring
4. **Encrypt**: Enable encryption at rest and in transit
5. **Version**: Enable versioning for data protection

## Configuration

### Customizing Detection Patterns
To add new OSS providers or patterns, modify the `oss_patterns` table in `oss_bucket_detector.lua`:

```lua
new_provider = {
    patterns = {
        "%.newprovider%.com$",
        "newprovider://",
    },
    provider = "New Provider Name",
    service_type = "new_provider"
}
```

### Customizing Security Tests
To add new security tests, modify the `security_tests` table in `oss_bucket_security_check.lua`:

```lua
{
    name = "New Security Test",
    description = "Description of what this tests",
    paths = {"/test-path"},
    check_function = function(status, body, headers)
        -- Your test logic here
        return "CRITICAL", "Issue description"
    end
}
```

## Best Practices

1. **Rate Limiting**: Both plugins include rate limiting to avoid overwhelming OSS endpoints
2. **Error Handling**: Comprehensive error handling for network failures
3. **Logging**: Detailed logging for troubleshooting and audit trails
4. **Metadata**: Rich metadata collection for analysis and reporting
5. **Dependency Management**: Proper script dependencies to ensure correct execution order

## Troubleshooting

### Common Issues
1. **Network Timeouts**: Adjust timeout values in HTTP requests
2. **Rate Limiting**: Increase sleep intervals between requests
3. **False Positives**: Review detection patterns for your specific environment
4. **Authentication**: Some tests may require authentication tokens

### Debugging
Enable verbose logging by checking the scan results for detailed test outcomes and HTTP response codes.
