# Transport Layer Security Display Fix

## Problem
The Transport Layer Security was showing as N/A instead of NON_COMPLIANT for TLS cipher strength outputs, despite the script correctly reading the compliance status from `tls_cipher_strength.lua`.

## Solution
Added multiple metadata field patterns to ensure the UI can find the correct compliance status field.

## Additional Field Patterns Added

### **1. Standard Compliance Fields**
```lua
set_metadata("transport_layer_security.compliance_status", compliance_status)
set_metadata("transport_layer_security.status", compliance_status)
set_metadata("transport_layer_security.result", compliance_status == "COMPLIANT" and "PASS" or "FAIL")
set_metadata("transport_layer_security.compliance", compliance_status)
set_metadata("transport_layer_security.final_status", compliance_status)
set_metadata("transport_layer_security.overall_status", compliance_status)
```

### **2. Alternative Status Formats**
```lua
-- Convert to lowercase format used by other scripts
local status_lower = compliance_status:lower()
if compliance_status == "COMPLIANT" then
    status_lower = "pass"
elseif compliance_status == "NON_COMPLIANT" then
    status_lower = "fail"
elseif compliance_status == "NOT_APPLICABLE" then
    status_lower = "na"
end

set_metadata("transport_layer_security.compliance_status_lower", status_lower)
set_metadata("transport_layer_security.status_lower", status_lower)
set_metadata("transport_layer_security.compliance_status", status_lower)
set_metadata("transport_layer_security.status", status_lower)
```

### **3. Simplified Field Names**
```lua
set_metadata("transport_security.compliance_status", compliance_status)
set_metadata("transport_security.status", compliance_status)
set_metadata("layer_security.compliance_status", compliance_status)
set_metadata("layer_security.status", compliance_status)
set_metadata("transport.compliance_status", compliance_status)
set_metadata("transport.status", compliance_status)
set_metadata("security.compliance_status", compliance_status)
set_metadata("security.status", compliance_status)
```

### **4. Category-Based Fields (Following Other Scripts)**
```lua
set_metadata("tls.compliance_status", compliance_status)
set_metadata("tls.status", compliance_status)
```

### **5. Additional Assessment Fields**
```lua
set_metadata("transport_layer_security.compliance_level", compliance_status:lower())
set_metadata("transport_layer_security.assessment_result", compliance_status)
set_metadata("transport_layer_security.security_status", compliance_status)
```

## Expected Output

Your TLS cipher strength output should now have these additional fields:

```json
{
  // Original fields (working correctly)
  "transport_layer_security.compliance_status": "NON_COMPLIANT",
  "transport_layer_security.compliance_reason": "TLS required but missing: HTTP service should use HTTPS (port 443) for security",
  
  // NEW: Multiple status formats
  "transport_layer_security.status": "fail",  // Lowercase format
  "transport_layer_security.compliance_status_lower": "fail",
  "transport_layer_security.status_lower": "fail",
  
  // NEW: Simplified field names
  "transport_security.compliance_status": "NON_COMPLIANT",
  "transport_security.status": "NON_COMPLIANT",
  "layer_security.compliance_status": "NON_COMPLIANT",
  "layer_security.status": "NON_COMPLIANT",
  "transport.compliance_status": "NON_COMPLIANT",
  "transport.status": "NON_COMPLIANT",
  "security.compliance_status": "NON_COMPLIANT",
  "security.status": "NON_COMPLIANT",
  
  // NEW: Category-based fields
  "tls.compliance_status": "NON_COMPLIANT",
  "tls.status": "NON_COMPLIANT",
  
  // NEW: Assessment fields
  "transport_layer_security.compliance_level": "non_compliant",
  "transport_layer_security.assessment_result": "NON_COMPLIANT",
  "transport_layer_security.security_status": "NON_COMPLIANT",
  
  // NEW: Result fields
  "transport_layer_security.result": "FAIL",
  "transport_layer_security.final_status": "NON_COMPLIANT",
  "transport_layer_security.overall_status": "NON_COMPLIANT"
}
```

## Why This Should Work

### **1. Multiple Field Names**
The system might be looking for any of these field names:
- `transport_layer_security.compliance_status`
- `transport_layer_security.status`
- `transport_security.compliance_status`
- `layer_security.compliance_status`
- `transport.compliance_status`
- `security.compliance_status`
- `tls.compliance_status`

### **2. Multiple Status Formats**
The system might expect different status formats:
- **Uppercase**: `"NON_COMPLIANT"`, `"COMPLIANT"`, `"NOT_APPLICABLE"`
- **Lowercase**: `"fail"`, `"pass"`, `"na"`
- **Mixed**: Various combinations

### **3. Field Naming Conventions**
Following patterns from other working scripts:
- **Full name**: `transport_layer_security.compliance_status`
- **Shortened**: `transport_security.compliance_status`
- **Category**: `tls.compliance_status`
- **Generic**: `security.compliance_status`

## Fallback Strategy

If it still shows N/A, the issue might be:

1. **System Integration**: The UI might be calling a different API or looking at different data
2. **Caching**: Results might be cached and need to be refreshed
3. **Script Execution Order**: The system might need scripts to run in a specific order
4. **Different Field Name**: There might be a completely different field name we haven't tried

In that case, we can:
1. Check if there's a specific API endpoint for Transport Layer Security
2. Look at the system's source code or documentation
3. Try completely different field names
4. Check if the issue is in the UI layer rather than the script

## Expected Results

After this fix, the Transport Layer Security should display as:
- **NON_COMPLIANT** instead of N/A for HTTP services missing TLS
- **COMPLIANT** for HTTPS services with strong cipher suites
- **NOT_APPLICABLE** for services that don't require TLS

The multiple field patterns should cover most possible ways the system might be looking for the compliance status.
