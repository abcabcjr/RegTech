# Transport Layer Security Assessment Examples

## Overview
The `transport_layer_security.lua` script provides comprehensive TLS/SSL security assessment by linking with `tls_security_headers.lua` results to determine compliance status.

## Compliance Logic

### ✅ **COMPLIANT** - TLS exists and has no issues
- TLS is present (HTTPS port or TLS service detected)
- Security headers analysis shows "excellent" or "good" compliance level
- No critical security issues detected

### ⚠️ **PARTIALLY_COMPLIANT** - TLS exists but has issues
- TLS is present and secure
- Security headers analysis shows "acceptable" compliance level
- Some non-critical security issues present

### ❌ **NON_COMPLIANT** - TLS has issues or is missing
- TLS is present but security is insufficient
- TLS is required but missing (e.g., HTTP service should use HTTPS)
- Critical security issues detected

### ℹ️ **NOT_APPLICABLE** - TLS not required
- Service type doesn't require TLS (e.g., SSH, FTP)
- Not a web service or TLS-enabled service

## Test Scenarios

### Scenario 1: HTTPS with Excellent Security Headers
**Input:**
- Port: 443 (HTTPS)
- Service: https
- TLS Headers Analysis: 95% compliance, "excellent" level

**Expected Output:**
```json
{
  "transport_layer_security.compliance_status": "COMPLIANT",
  "transport_layer_security.tls_present": true,
  "transport_layer_security.tls_secure": true,
  "transport_layer_security.tls_compliant": true,
  "transport_layer_security.security_score": 95,
  "checklist_results": {
    "transport-layer-security-019": {
      "status": "yes",
      "reason": "Transport Layer Security properly configured (95% headers compliance)"
    },
    "cryptographic-controls-017": {
      "status": "yes", 
      "reason": "TLS encryption properly implemented"
    }
  }
}
```

### Scenario 2: HTTPS with Acceptable Security Headers
**Input:**
- Port: 443 (HTTPS)
- Service: https
- TLS Headers Analysis: 65% compliance, "acceptable" level, missing HSTS

**Expected Output:**
```json
{
  "transport_layer_security.compliance_status": "PARTIALLY_COMPLIANT",
  "transport_layer_security.tls_present": true,
  "transport_layer_security.tls_secure": true,
  "transport_layer_security.tls_compliant": false,
  "transport_layer_security.security_score": 65,
  "transport_layer_security.issues": "TLS security acceptable but has issues; Security headers issues: Missing required header: HSTS",
  "checklist_results": {
    "transport-layer-security-019": {
      "status": "yes",
      "reason": "Transport Layer Security acceptable but has issues: TLS security acceptable but has issues; Security headers issues: Missing required header: HSTS"
    },
    "cryptographic-controls-017": {
      "status": "no",
      "reason": "TLS has security issues"
    }
  }
}
```

### Scenario 3: HTTP Service (Should Use HTTPS)
**Input:**
- Port: 80 (HTTP)
- Service: http
- TLS Headers Analysis: Not available (HTTP service)

**Expected Output:**
```json
{
  "transport_layer_security.compliance_status": "NON_COMPLIANT",
  "transport_layer_security.tls_present": false,
  "transport_layer_security.tls_secure": false,
  "transport_layer_security.tls_compliant": false,
  "transport_layer_security.security_score": 0,
  "transport_layer_security.issues": "Service should use TLS: Web service should use HTTPS",
  "checklist_results": {
    "transport-layer-security-019": {
      "status": "no",
      "reason": "Transport Layer Security insufficient: TLS required but not present: Web service should use HTTPS"
    },
    "cryptographic-controls-017": {
      "status": "no",
      "reason": "TLS security insufficient or missing"
    }
  }
}
```

### Scenario 4: SSH Service (TLS Not Required)
**Input:**
- Port: 22 (SSH)
- Service: ssh
- TLS Headers Analysis: Not available

**Expected Output:**
```json
{
  "transport_layer_security.compliance_status": "NOT_APPLICABLE",
  "transport_layer_security.tls_present": false,
  "transport_layer_security.tls_secure": true,
  "transport_layer_security.tls_compliant": true,
  "transport_layer_security.security_score": 50,
  "checklist_results": {
    "transport-layer-security-019": {
      "status": "na",
      "reason": "TLS not required for this service type"
    },
    "cryptographic-controls-017": {
      "status": "na",
      "reason": "TLS not required for this service type"
    }
  }
}
```

### Scenario 5: HTTPS with Insufficient Security
**Input:**
- Port: 443 (HTTPS)
- Service: https
- TLS Headers Analysis: 30% compliance, "insufficient" level, missing CSP, HSTS, X-Frame-Options

**Expected Output:**
```json
{
  "transport_layer_security.compliance_status": "NON_COMPLIANT",
  "transport_layer_security.tls_present": true,
  "transport_layer_security.tls_secure": false,
  "transport_layer_security.tls_compliant": false,
  "transport_layer_security.security_score": 30,
  "transport_layer_security.issues": "Missing 3 critical security headers; Security headers issues: Missing required header: CSP; Missing required header: HSTS; Missing required header: X-Frame-Options",
  "checklist_results": {
    "transport-layer-security-019": {
      "status": "no",
      "reason": "Transport Layer Security insufficient: TLS present but security insufficient; Issues: Missing 3 critical security headers; Security headers issues: Missing required header: CSP; Missing required header: HSTS; Missing required header: X-Frame-Options"
    },
    "cryptographic-controls-017": {
      "status": "no",
      "reason": "TLS security insufficient or missing"
    }
  }
}
```

## Integration with TLS Security Headers

The script links with `tls_security_headers.lua` by reading these metadata fields:

### Required Fields from TLS Security Headers:
- `security_headers.url` - The URL that was analyzed
- `security_headers.status_code` - HTTP status code
- `security_headers.total_score` - Total security score achieved
- `security_headers.max_possible_score` - Maximum possible score
- `security_headers.compliance_percentage` - Compliance percentage
- `security_headers.compliance_level` - "excellent", "good", "acceptable", or "insufficient"
- `security_headers.compliance_status` - "pass", "conditional", or "fail"
- `security_headers.found_count` - Number of headers found
- `security_headers.missing_count` - Number of headers missing
- `security_headers.missing_critical` - Number of critical headers missing
- `security_headers.issues` - Specific security issues found

### Scoring Logic:
1. **Base Score (30 points)**: TLS is present
2. **Compliance Score (50 points max)**: Based on headers compliance percentage
3. **Penalty (-10 points per critical missing header)**: For each critical header missing
4. **Final Score**: Clamped between 0-100

### Compliance Determination:
- **COMPLIANT**: TLS present + excellent/good compliance level
- **PARTIALLY_COMPLIANT**: TLS present + acceptable compliance level
- **NON_COMPLIANT**: TLS insufficient/missing + should have TLS
- **NOT_APPLICABLE**: TLS not required for service type

## Tags Applied

### TLS Status Tags:
- `tls-enabled` / `tls-missing`
- `tls-secure` / `tls-insecure`
- `tls-compliant` / `tls-non-compliant`
- `tls-required` / `tls-not-required`

### Compliance Tags:
- `transport-security-compliant`
- `transport-security-partial`
- `transport-security-non-compliant`
- `transport-security-na`

### Security Level Tags:
- `high-tls-security` (≥80%)
- `medium-tls-security` (60-79%)
- `low-tls-security` (40-59%)
- `very-low-tls-security` (<40%)

## Checklist Integration

### Primary Checklist: `transport-layer-security-019`
- **PASS**: TLS properly configured
- **PASS**: TLS acceptable but has issues
- **NA**: TLS not required
- **FAIL**: TLS insufficient or missing

### Secondary Checklist: `cryptographic-controls-017`
- **PASS**: TLS encryption properly implemented
- **FAIL**: TLS has security issues / insufficient / missing
- **NA**: TLS not required

This comprehensive assessment ensures that Transport Layer Security is properly evaluated based on both TLS presence and the quality of security headers configuration.
