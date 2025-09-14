# Port Security Checklist with High Port Exposure - Test Examples

## Overview
The enhanced `port_security_checklist.lua` script now provides comprehensive high port exposure assessment and returns compliance status based on port security exposure results.

## Key Features Added

### 1. High Port Exposure Detection
- **High Ports**: Ports > 1024 are now categorized and assessed for risk
- **Known High Port Services**: Development tools, databases, monitoring services
- **Risk Categories**: CRITICAL, HIGH, MEDIUM, LOW
- **Service Categories**: development, database, monitoring, ci_cd, remote_access, web, network, etc.

### 2. Comprehensive Compliance Assessment
- **COMPLIANT**: Secure ports, low-risk high ports
- **NON_COMPLIANT**: Critical/high-risk ports, unknown services
- **Detailed Reasons**: Specific compliance failure reasons provided

### 3. Enhanced Metadata and Tagging
- Port risk level, service type, and category metadata
- Compliance status and reasons
- Detailed tagging for monitoring and alerting

## Test Scenarios

### Scenario 1: Standard Secure Port (COMPLIANT)
```
Service: example.com:443/tcp
Result: COMPLIANT
Reason: Standard HTTPS service on secure port
Tags: secure-port-configuration, port-security-compliant
Checklists: PASS open-ports-review-014, PASS high-risk-port-exposure-025
```

### Scenario 2: Critical Risk Port (NON_COMPLIANT)
```
Service: example.com:3389/tcp  (RDP)
Result: NON_COMPLIANT
Reason: Critical risk port exposed
Tags: critical-port-exposure, article-11-violation, port-security-non-compliant
Checklists: FAIL open-ports-review-014, FAIL high-risk-port-exposure-025
```

### Scenario 3: High Port Development Service (NON_COMPLIANT)
```
Service: example.com:3000/tcp  (Node.js/React Dev)
Result: NON_COMPLIANT
Reason: High-risk high port service exposed
Tags: high-risk-high-port-exposure, high-port-development, port-security-non-compliant
Checklists: FAIL open-ports-review-014, FAIL high-risk-port-exposure-025
```

### Scenario 4: Medium Risk High Port (COMPLIANT)
```
Service: example.com:8080/tcp  (HTTP Alt)
Result: COMPLIANT
Reason: Medium-risk high port acceptable with monitoring
Tags: medium-risk-high-port, high-port-web, requires-monitoring, port-security-compliant
Checklists: PASS open-ports-review-014, PASS high-risk-port-exposure-025
```

### Scenario 5: Low Risk High Port (COMPLIANT)
```
Service: example.com:49152/tcp  (Dynamic Port)
Result: COMPLIANT
Reason: Low-risk ephemeral port
Tags: low-risk-high-port, high-port-ephemeral, port-security-compliant
Checklists: PASS open-ports-review-014, PASS high-risk-port-exposure-025
```

### Scenario 6: Database High Port (NON_COMPLIANT)
```
Service: example.com:5432/tcp  (PostgreSQL)
Result: NON_COMPLIANT
Reason: Critical high port service exposed
Tags: critical-high-port-exposure, high-port-database, port-security-non-compliant
Checklists: FAIL open-ports-review-014, FAIL high-risk-port-exposure-025, FAIL service-authentication-020
```

## Integration Points

### 1. Links to Port Scan Results
The script integrates with `port_scan.lua` results by:
- Using the same risk assessment criteria
- Applying consistent tagging for high-risk ports
- Providing detailed compliance assessment per service

### 2. Compliance Reporting
- **Metadata**: `port.compliance_status`, `port.compliance_reasons`
- **Tags**: Specific tags for compliance status and risk levels
- **Checklists**: Both `open-ports-review-014` and `high-risk-port-exposure-025`

### 3. Article 11 Compliance
- Explicit compliance with Moldovan Cybersecurity Law Article 11
- Tags for Article 11 violations and risks
- Detailed logging for audit trails

## Usage
The script automatically runs on any `service` type asset with the format:
`host:port/protocol`

Example service assets:
- `192.168.1.100:22/tcp`
- `example.com:3000/tcp`  
- `server.local:8080/tcp`

The script will return COMPLIANT or NON_COMPLIANT based on the comprehensive port security and exposure assessment.
