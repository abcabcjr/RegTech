# HTTP Headers Integration with Security Headers Analysis - Examples

## Overview
The new `http_headers.lua` script provides comprehensive HTTP headers detection and analysis that integrates with existing security headers validation to determine compliance status.

## Key Integration Features

### 1. HTTP Service Detection Integration
- **Banner Grab Dependency**: Uses `banner_grab.lua` results for service identification
- **Multi-Method Detection**: Banner analysis → Banner content → Port-based detection
- **Service Confidence**: Inherits confidence levels from banner grab results
- **Scheme Detection**: Automatically determines HTTP vs HTTPS

### 2. Comprehensive Headers Analysis
- **Security Headers Assessment** (60 points): Critical security headers validation
- **Information Disclosure Detection** (-5 points each): Identifies problematic headers
- **HTTPS Bonus** (10 points): Rewards encrypted connections
- **Base Response Score** (20 points): Credit for successful HTTP response

### 3. Compliance Integration with Security Headers
- **Dual Checklist Support**: `http-security-headers-013` and `web-security-hardening-018`
- **Score-Based Assessment**: 0-100 point scoring system
- **Compliance Thresholds**: ≥80% COMPLIANT, 60-79% PARTIALLY_COMPLIANT, <60% NON_COMPLIANT

## Test Scenarios and Expected Results

### Scenario 1: Well-Secured HTTPS Service (COMPLIANT)
```
Input: example.com:443/tcp
Banner Grab: service.port.443 = "https", banner contains "HTTP/1.1 200 OK"

HTTP Headers Response:
  - Status: 200 OK
  - strict-transport-security: max-age=31536000; includeSubDomains
  - content-security-policy: default-src 'self'; script-src 'self'
  - x-frame-options: DENY
  - x-content-type-options: nosniff
  - referrer-policy: strict-origin-when-cross-origin

Analysis Results:
  - Base Score: 20 points (successful response)
  - HSTS: +15 points
  - CSP: +15 points  
  - X-Frame-Options: +10 points
  - X-Content-Type-Options: +10 points
  - Referrer-Policy: +10 points
  - HTTPS Bonus: +10 points
  - Total: 90/100 (90%)

Result: COMPLIANT
Checklists: PASS http-security-headers-013, PASS web-security-hardening-018
Tags: http-headers-compliant, security-headers-configured
```

### Scenario 2: HTTP Service with Missing Headers (NON_COMPLIANT)
```
Input: example.com:80/tcp
Banner Grab: service.port.80 = "http", banner contains "HTTP/1.1 200 OK"

HTTP Headers Response:
  - Status: 200 OK
  - server: Apache/2.4.41 (Ubuntu)
  - x-powered-by: PHP/7.4.3
  - content-type: text/html; charset=UTF-8
  - (No security headers present)

Analysis Results:
  - Base Score: 20 points (successful response)
  - Missing HSTS: 0 points (not required for HTTP)
  - Missing CSP: 0 points (-15 penalty)
  - Missing X-Frame-Options: 0 points (-10 penalty)
  - Missing X-Content-Type-Options: 0 points (-10 penalty)
  - Missing Referrer-Policy: 0 points (-10 penalty)
  - Server Header Disclosure: -5 points
  - X-Powered-By Disclosure: -5 points
  - HTTP (no HTTPS bonus): 0 points
  - Total: 0/100 (0%)

Result: NON_COMPLIANT
Issues: Missing required security headers, Information disclosure
Recommendations: Implement CSP, X-Frame-Options, X-Content-Type-Options headers
Checklists: FAIL http-security-headers-013, FAIL web-security-hardening-018
Tags: http-headers-non-compliant, missing-security-headers, information-disclosure
```

### Scenario 3: Partially Secured HTTPS Service (PARTIALLY_COMPLIANT)
```
Input: example.com:8443/tcp
Banner Grab: service.port.8443 = "https-alt", banner contains "HTTP/1.1 200 OK"

HTTP Headers Response:
  - Status: 200 OK
  - strict-transport-security: max-age=86400
  - x-frame-options: SAMEORIGIN
  - x-content-type-options: nosniff
  - server: nginx/1.18.0
  - (Missing CSP and Referrer-Policy)

Analysis Results:
  - Base Score: 20 points
  - HSTS: +15 points (present but short duration)
  - Missing CSP: 0 points (-15 penalty)
  - X-Frame-Options: +10 points
  - X-Content-Type-Options: +10 points
  - Missing Referrer-Policy: 0 points (-10 penalty)
  - Server Header Disclosure: -5 points
  - HTTPS Bonus: +10 points
  - Total: 50/100 (50%) -> Actually NON_COMPLIANT

Result: NON_COMPLIANT (score too low)
Issues: Missing CSP header, Information disclosure: server header
Recommendations: Implement Content Security Policy, Remove server header
Checklists: FAIL http-security-headers-013, FAIL web-security-hardening-018
Tags: http-headers-non-compliant, missing-critical-headers, information-disclosure
```

### Scenario 4: Good Security Configuration (COMPLIANT)
```
Input: example.com:443/tcp
Banner Grab: service.port.443 = "https", banner contains "HTTP/1.1 200 OK"

HTTP Headers Response:
  - Status: 200 OK
  - strict-transport-security: max-age=31536000; includeSubDomains; preload
  - content-security-policy: default-src 'self'
  - x-frame-options: DENY
  - x-content-type-options: nosniff
  - (No information disclosure headers)
  - (Missing Referrer-Policy)

Analysis Results:
  - Base Score: 20 points
  - HSTS: +15 points
  - CSP: +15 points
  - X-Frame-Options: +10 points
  - X-Content-Type-Options: +10 points
  - Missing Referrer-Policy: 0 points (not required)
  - No disclosure penalties: 0 points
  - HTTPS Bonus: +10 points
  - Total: 80/100 (80%)

Result: COMPLIANT
Checklists: PASS http-security-headers-013, PASS web-security-hardening-018
Tags: http-headers-compliant, security-headers-configured
```

### Scenario 5: Non-HTTP Service (NOT_APPLICABLE)
```
Input: example.com:22/tcp
Banner Grab: service.port.22 = "ssh", banner contains "SSH-2.0-OpenSSH_8.2p1"

Detection Result: Not an HTTP service
Result: NOT_APPLICABLE
Checklists: N/A http-security-headers-013, N/A web-security-hardening-018
Tags: non-http-service
```

## Integration Flow

### 1. HTTP Service Detection
```lua
-- Uses banner_grab.lua results
local detected_service = get_metadata("service.port." .. port)
local service_banner = get_metadata("banner.port." .. port)
local service_confidence = get_metadata("service.confidence.port." .. port)
```

### 2. Headers Fetching and Analysis
```lua
-- Performs actual HTTP request
local status, body, headers, err = http.get(url, {...}, 15)

-- Analyzes headers for security compliance
analyze_http_headers_compliance(headers_info, http_service_info)
```

### 3. Compliance Determination
```lua
-- Score-based compliance assessment
if compliance_percentage >= 80 then
    compliance_status = "COMPLIANT"
elseif compliance_percentage >= 60 then
    compliance_status = "PARTIALLY_COMPLIANT"
else
    compliance_status = "NON_COMPLIANT"
end
```

## Metadata Generated

### HTTP Service Detection
- `http_headers.is_http_service`: Boolean indicating HTTP service
- `http_headers.service_type`: Type of HTTP service detected
- `http_headers.detection_method`: How service was detected
- `http_headers.confidence`: Detection confidence level
- `http_headers.scheme`: http or https

### Headers Analysis
- `http_headers.fetch_success`: Whether headers were successfully fetched
- `http_headers.status_code`: HTTP response status code
- `http_headers.total_headers`: Total number of headers received
- `http_headers.security_headers_count`: Number of security headers found
- `http_headers.header.{header_name}`: Individual header values

### Compliance Assessment
- `http_headers.compliance_status`: COMPLIANT/PARTIALLY_COMPLIANT/NON_COMPLIANT
- `http_headers.compliance_score`: Score (0-100)
- `http_headers.compliance_percentage`: Compliance percentage
- `http_headers.issues`: List of security issues found
- `http_headers.recommendations`: Security recommendations

## Compliance Checklists

### http-security-headers-013
- **Purpose**: HTTP Security Headers compliance validation
- **Pass Conditions**: COMPLIANT or PARTIALLY_COMPLIANT status
- **Fail Conditions**: NON_COMPLIANT status

### web-security-hardening-018
- **Purpose**: Web Security Hardening compliance
- **Pass Conditions**: COMPLIANT status only
- **Fail Conditions**: PARTIALLY_COMPLIANT or NON_COMPLIANT status

## Integration Benefits

1. **Comprehensive Detection**: Multiple methods ensure HTTP services are properly identified
2. **Real Headers Analysis**: Performs actual HTTP requests to validate headers
3. **Score-Based Assessment**: Objective scoring system for compliance determination
4. **Security Focus**: Emphasizes critical security headers over optional ones
5. **Information Disclosure Detection**: Identifies and penalizes problematic headers
6. **HTTPS Incentive**: Rewards encrypted connections with bonus points
7. **Flexible Thresholds**: Different compliance levels for different security postures

This integration provides a robust HTTP headers assessment that works seamlessly with banner grab service detection and delivers comprehensive security compliance validation.
