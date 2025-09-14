# TLS Cipher Strength - Missing TLS Fix

## Problem Description
Previously, when a service that should have TLS (like HTTP on port 80) didn't have TLS encryption, the TLS cipher strength script would return N/A (Not Applicable) instead of NON_COMPLIANT.

## Your Case Example
```json
{
  "checklist_results": {
    "cryptographic-controls-017": {
      "reason": "Not a TLS service",
      "status": "na"
    },
    "tls-cipher-strength-016": {
      "reason": "Not a TLS service", 
      "status": "na"
    }
  },
  "tls_cipher_strength.assessment": "not_applicable",
  "tls_cipher_strength.is_tls_service": false,
  "tls_cipher_strength.port": 80,
  "tls_cipher_strength.service_type": "unknown"
}
```

**Issue**: Port 80 (HTTP) should be flagged as NON_COMPLIANT for missing required TLS, not N/A.

## Fix Applied

### New Logic: TLS Requirement Assessment
The script now distinguishes between:
1. **Services that SHOULD have TLS** → NON_COMPLIANT if missing
2. **Services that don't need TLS** → N/A (truly not applicable)

### TLS Required Ports
```lua
local tls_required_ports = {
    [80] = "HTTP service should use HTTPS (port 443) for security",
    [8080] = "HTTP alternative service should use HTTPS for security", 
    [8000] = "Development HTTP service should use HTTPS for security",
    [8008] = "HTTP service should use HTTPS for security",
    [3000] = "Development server should use HTTPS for security",
    [5000] = "Development server should use HTTPS for security"
}
```

### TLS Required Service Types
```lua
local web_services_requiring_tls = {"http", "http-alt", "nginx", "apache", "iis"}
```

## Expected Results After Fix

### Your Case (Port 80 HTTP) - Now NON_COMPLIANT
```json
{
  "checklist_results": {
    "cryptographic-controls-017": {
      "reason": "Cryptographic controls insufficient: service lacks required TLS encryption",
      "status": "fail"
    },
    "tls-cipher-strength-016": {
      "reason": "TLS encryption missing: HTTP service should use HTTPS (port 443) for security",
      "status": "fail"
    }
  },
  "tls_cipher_strength.assessment": "non_compliant_missing_tls",
  "tls_cipher_strength.compliance_status": "NON_COMPLIANT",
  "tls_cipher_strength.cipher_strength": "insufficient",
  "tls_cipher_strength.security_score": 0,
  "tls_cipher_strength.missing_tls_reason": "HTTP service should use HTTPS (port 443) for security",
  "tls_cipher_strength.is_tls_service": false,
  "tls_cipher_strength.port": 80,
  "tls_cipher_strength.service_type": "unknown"
}
```

### Tags Added
- `missing-required-tls`
- `tls-cipher-non-compliant`
- `insufficient-encryption`
- `article-11-crypto-violation`

## Test Scenarios

### Scenario 1: HTTP Service on Port 80 (NON_COMPLIANT)
```
Input: 127.0.0.1:80/tcp
Service Detection: HTTP service detected
TLS Detection: No TLS found
Assessment: NON_COMPLIANT - HTTP should use HTTPS for security
Checklists: FAIL tls-cipher-strength-016, FAIL cryptographic-controls-017
```

### Scenario 2: HTTP Service on Port 8080 (NON_COMPLIANT)
```
Input: example.com:8080/tcp
Service Detection: HTTP alternative service
TLS Detection: No TLS found
Assessment: NON_COMPLIANT - HTTP alternative should use HTTPS
Checklists: FAIL tls-cipher-strength-016, FAIL cryptographic-controls-017
```

### Scenario 3: Development Server on Port 3000 (NON_COMPLIANT)
```
Input: localhost:3000/tcp
Service Detection: Development server
TLS Detection: No TLS found
Assessment: NON_COMPLIANT - Development server should use HTTPS
Checklists: FAIL tls-cipher-strength-016, FAIL cryptographic-controls-017
```

### Scenario 4: SSH Service on Port 22 (N/A - Correct)
```
Input: server.local:22/tcp
Service Detection: SSH service
TLS Detection: No TLS found (expected)
Assessment: N/A - SSH doesn't require TLS (has its own encryption)
Checklists: N/A tls-cipher-strength-016, N/A cryptographic-controls-017
```

### Scenario 5: FTP Service on Port 21 (N/A - Correct)
```
Input: ftp.example.com:21/tcp
Service Detection: FTP service
TLS Detection: No TLS found
Assessment: N/A - FTP doesn't require TLS (though FTPS is recommended)
Checklists: N/A tls-cipher-strength-016, N/A cryptographic-controls-017
```

### Scenario 6: HTTPS Service on Port 443 (Assessed for TLS Quality)
```
Input: secure.example.com:443/tcp
Service Detection: HTTPS service
TLS Detection: TLS found
Assessment: COMPLIANT/NON_COMPLIANT based on cipher strength quality
Checklists: PASS/FAIL based on actual TLS cipher assessment
```

## Key Benefits

1. **Security Compliance**: Web services without TLS are now properly flagged as non-compliant
2. **Clear Distinction**: Separates services that need TLS from those that don't
3. **Actionable Results**: Provides specific reasons why TLS is required
4. **Article 11 Compliance**: Aligns with cybersecurity law requirements for encryption
5. **Comprehensive Coverage**: Checks both port-based and service-based TLS requirements

## Implementation Details

### Double-Check Logic
1. **Port-Based Check**: Looks at known web service ports that should have TLS
2. **Service-Based Check**: Examines banner grab results for web services
3. **Combined Assessment**: If either check indicates TLS should be present, failure to have TLS = NON_COMPLIANT

### Metadata Enhancement
- `tls_cipher_strength.missing_tls_reason`: Explains why TLS was expected
- `tls_cipher_strength.assessment`: Distinguishes between "not_applicable" and "non_compliant_missing_tls"

This fix ensures that your HTTP service on port 80 will now correctly return NON_COMPLIANT for TLS cipher strength instead of N/A, providing proper security compliance assessment.
