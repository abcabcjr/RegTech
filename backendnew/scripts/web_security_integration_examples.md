# Web Security Hardening with Banner Grab Integration - Examples

## Overview
The new `web_security_hardening.lua` script provides comprehensive web security assessment by integrating with `banner_grab.lua` results and performing additional security tests.

## Key Integration Features

### 1. Banner Grab Results Integration
- **Service Detection**: Uses banner grab metadata (`service.port.X`, `banner.port.X`)
- **Server Software Identification**: Extracts web server type and version from banners
- **Confidence Assessment**: Leverages banner grab confidence levels
- **Security Implications**: Analyzes banner content for security indicators

### 2. Comprehensive Web Security Testing
- **HTTPS/TLS Configuration** (25 points): Tests encryption capability
- **Security Headers Assessment** (30 points): Validates critical security headers
- **Service Configuration Security** (25 points): Analyzes server software security
- **Port and Service Risk Assessment** (20 points): Evaluates port-based risks

### 3. Compliance Status Determination
- **COMPLIANT**: ≥80% score - meets all security requirements
- **PARTIALLY_COMPLIANT**: 60-79% score - has issues but acceptable
- **NON_COMPLIANT**: <60% score - fails security requirements

## Test Scenarios and Examples

### Scenario 1: Secure HTTPS Web Service (COMPLIANT)
```
Input: example.com:443/tcp
Banner Grab Result: "HTTP/1.1 200 OK\r\nServer: nginx/1.18.0"
Web Security Assessment:
  - Service: nginx (high confidence)
  - HTTPS: ✅ (25 points)
  - Security Headers: ✅ HSTS, CSP, X-Frame-Options (30 points)
  - Server Config: ✅ Nginx secure (20 points)
  - Port Risk: ✅ Low risk HTTPS port (20 points)
  
Result: COMPLIANT (95/100 = 95%)
Checklists: PASS web-security-hardening-018, PASS web-service-security-021
Tags: web-security-compliant, web-hardening-passed, high-confidence-detection
```

### Scenario 2: HTTP Service with Missing Headers (PARTIALLY_COMPLIANT)
```
Input: example.com:80/tcp
Banner Grab Result: "HTTP/1.1 200 OK\r\nServer: Apache/2.4.41"
Web Security Assessment:
  - Service: apache (high confidence)
  - HTTPS: ❌ Unencrypted HTTP (0 points)
  - Security Headers: ⚠️ Missing HSTS, CSP (10/30 points)
  - Server Config: ✅ Apache detected (15 points)
  - Port Risk: ❌ High risk HTTP port (5 points)
  
Result: PARTIALLY_COMPLIANT (30/100 = 30%) -> Actually NON_COMPLIANT
Issues: Unencrypted HTTP traffic, Missing HSTS header, Missing CSP header
Recommendations: Implement HTTPS/TLS encryption, Implement HSTS security header
Checklists: FAIL web-security-hardening-018, FAIL web-service-security-021
Tags: web-security-non-compliant, unencrypted-web-traffic, missing-security-headers
```

### Scenario 3: Development Server Exposed (NON_COMPLIANT)
```
Input: example.com:3000/tcp
Banner Grab Result: "HTTP/1.1 200 OK\r\nX-Powered-By: Express"
Web Security Assessment:
  - Service: http-dev (medium confidence)
  - HTTPS: ❌ Development HTTP (0 points)
  - Security Headers: ❌ No security headers (0 points)
  - Server Config: ⚠️ Express.js detected (10 points)
  - Port Risk: ❌ Critical - development interface (0 points)
  
Result: NON_COMPLIANT (10/100 = 10%)
Issues: Critical risk - development/admin interface exposed, Unencrypted HTTP traffic
Recommendations: Do not expose development interfaces to public networks
Checklists: FAIL web-security-hardening-018, FAIL web-service-security-021
Tags: web-security-non-compliant, exposed-admin-interface, article-11-web-violation
```

### Scenario 4: Well-Configured Alternative HTTPS Port (COMPLIANT)
```
Input: example.com:8443/tcp
Banner Grab Result: "HTTP/1.1 200 OK\r\nServer: nginx/1.20.2"
Web Security Assessment:
  - Service: https-alt (high confidence)
  - HTTPS: ✅ Alternative HTTPS port (25 points)
  - Security Headers: ✅ Most headers present (25/30 points)
  - Server Config: ✅ Nginx secure (20 points)
  - Port Risk: ✅ Low risk HTTPS alt (20 points)
  
Result: COMPLIANT (90/100 = 90%)
Checklists: PASS web-security-hardening-018, PASS web-service-security-021
Tags: web-security-compliant, web-hardening-passed
```

### Scenario 5: Non-Web Service (NOT_APPLICABLE)
```
Input: example.com:22/tcp
Banner Grab Result: "SSH-2.0-OpenSSH_8.2p1"
Web Security Assessment:
  - Service: ssh (high confidence)
  - Is Web Service: ❌ No
  
Result: NOT_APPLICABLE
Checklists: N/A web-security-hardening-018, N/A web-service-security-021
Tags: non-web-service
```

## Integration Flow

### 1. Banner Grab Dependency
```lua
-- @requires_passed banner_grab.lua
```
The script requires banner_grab.lua to run first, ensuring service detection metadata is available.

### 2. Metadata Usage
```lua
local detected_service = get_metadata("service.port." .. port)
local service_banner = get_metadata("banner.port." .. port)
local service_confidence = get_metadata("service.confidence.port." .. port)
```

### 3. Web Service Detection Logic
- **Banner Analysis**: Checks for HTTP/HTTPS services in banner grab results
- **Port-Based Detection**: Identifies common web ports (80, 443, 8080, 8443, etc.)
- **Server Software Extraction**: Parses server headers from banners
- **Confidence Assessment**: Uses banner grab confidence levels

### 4. Security Testing Integration
- **TLS Testing**: Tests HTTPS capability based on port and service detection
- **Header Analysis**: Performs HTTP requests to check security headers
- **Configuration Assessment**: Evaluates server software security
- **Risk Assessment**: Analyzes port-based security risks

## Metadata Generated

### Web Service Detection
- `web_security.is_web_service`: Boolean indicating web service presence
- `web_security.service_type`: Type of web service detected
- `web_security.server_software`: Web server software (nginx, apache, iis)
- `web_security.version`: Server software version
- `web_security.confidence`: Detection confidence level
- `web_security.detection_method`: How service was detected

### Security Assessment
- `web_security.overall_score`: Security score (0-100)
- `web_security.compliance_percentage`: Compliance percentage
- `web_security.compliance_status`: COMPLIANT/PARTIALLY_COMPLIANT/NON_COMPLIANT
- `web_security.issues`: List of security issues found
- `web_security.recommendations`: Security recommendations

### Test Results
- `web_security.port_risk`: Port-based risk level
- `web_security.implications`: Security implications from banner analysis

## Compliance Checklists

### web-security-hardening-018
- **Purpose**: Web Security Hardening compliance
- **Pass Conditions**: ≥80% security score
- **Fail Conditions**: <60% security score or critical issues

### web-service-security-021
- **Purpose**: Web Service Security compliance
- **Pass Conditions**: COMPLIANT status
- **Fail Conditions**: NON_COMPLIANT status or critical security issues

## Usage Notes

1. **Sequential Execution**: Must run after `banner_grab.lua` for full functionality
2. **Web Service Focus**: Only assesses services identified as web services
3. **Comprehensive Testing**: Performs multiple security tests beyond just headers
4. **Article 11 Compliance**: Aligned with Moldovan Cybersecurity Law requirements
5. **Integration Benefits**: Leverages existing banner grab results for efficiency

This integration provides a comprehensive web security assessment that builds upon the service detection capabilities of banner_grab.lua while adding detailed security hardening validation.
