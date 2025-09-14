# Transport Layer Security Debugging Changes

## Problem
Despite all the metadata field patterns being added, the Transport Layer Security is still showing as N/A instead of NON_COMPLIANT.

## Root Cause Investigation
I've identified and fixed two potential issues:

### **1. Script Execution Order Issue - FIXED**
**Problem**: The script had `@requires_passed tls_security_headers.lua` but we changed it to read from `tls_cipher_strength.lua`.

**Fix**: Updated the requirement to:
```lua
-- @requires_passed banner_grab.lua,tls_cipher_strength.lua
```

This ensures the script runs AFTER `tls_cipher_strength.lua` has completed and set its metadata.

### **2. Metadata Access Verification - ADDED DEBUGGING**
**Problem**: We need to verify that the metadata is actually being read correctly.

**Fix**: Added comprehensive debugging to see:
- What metadata keys are available
- What TLS cipher analysis data is found
- How the compliance status is determined

## Debugging Code Added

### **Metadata Access Debugging**
```lua
-- Debug: Log all available metadata keys
local available_keys = {}
for key, value in pairs(asset.scan_metadata) do
    table.insert(available_keys, key)
end
log("DEBUG: Available metadata keys: " .. table.concat(available_keys, ", "))

-- Debug: Log what we found
log("DEBUG: TLS cipher analysis found:")
log("  Assessment: " .. tostring(tls_cipher_analysis.assessment))
log("  Compliance Status: " .. tostring(tls_cipher_analysis.compliance_status))
log("  Cipher Strength: " .. tostring(tls_cipher_analysis.cipher_strength))
log("  Security Score: " .. tostring(tls_cipher_analysis.security_score))
log("  Is TLS Service: " .. tostring(tls_cipher_analysis.is_tls_service))
```

### **Compliance Determination Debugging**
```lua
log("DEBUG: Determining compliance status...")
log("  TLS cipher analysis available: " .. tostring(tls_cipher_analysis ~= nil))
if tls_cipher_analysis then
    log("  TLS cipher compliance status: " .. tostring(tls_cipher_analysis.compliance_status))
end

log("DEBUG: Using TLS cipher compliance status: " .. compliance_status)
log("DEBUG: Final compliance status determined: " .. compliance_status)
log("DEBUG: Final compliance reason: " .. compliance_reason)
```

## Expected Debug Output

When you run the script now, you should see debug logs like:

```
DEBUG: Found scan_metadata, checking for TLS cipher strength fields...
DEBUG: Available metadata keys: tls_cipher_strength.assessment, tls_cipher_strength.compliance_status, tls_cipher_strength.cipher_strength, ...
DEBUG: TLS cipher analysis found:
  Assessment: non_compliant_missing_tls
  Compliance Status: NON_COMPLIANT
  Cipher Strength: insufficient
  Security Score: 0
  Is TLS Service: false
DEBUG: Determining compliance status...
  TLS cipher analysis available: true
  TLS cipher compliance status: NON_COMPLIANT
DEBUG: Using TLS cipher compliance status: NON_COMPLIANT
DEBUG: Final compliance status determined: NON_COMPLIANT
DEBUG: Final compliance reason: TLS required but missing: HTTP service should use HTTPS (port 443) for security
```

## What to Check

### **1. Script Execution Order**
- Verify that `tls_cipher_strength.lua` runs before `transport_layer_security.lua`
- The `@requires_passed` directive should ensure this

### **2. Metadata Availability**
- Check if the debug logs show the TLS cipher strength metadata keys
- Verify that `tls_cipher_strength.compliance_status` is found and has the value "NON_COMPLIANT"

### **3. Compliance Status Determination**
- Check if the debug logs show the correct compliance status being determined
- Verify that the final compliance status is "NON_COMPLIANT"

## Possible Outcomes

### **Scenario 1: Metadata Not Found**
If debug logs show "No scan_metadata found!" or no TLS cipher strength keys:
- The script execution order is wrong
- `tls_cipher_strength.lua` hasn't run yet
- There's a system issue with metadata sharing

### **Scenario 2: Metadata Found but Wrong Status**
If debug logs show metadata but wrong compliance status:
- There's an issue with the compliance determination logic
- The TLS cipher strength script has a bug

### **Scenario 3: Everything Looks Correct**
If debug logs show correct metadata and compliance status:
- The issue is in the UI layer or field naming
- We need to try even more field name variations

## Next Steps

1. **Run the script** and check the debug logs
2. **Share the debug output** so we can see exactly what's happening
3. **Based on the debug output**, we can determine the next steps:
   - Fix script execution order if needed
   - Fix metadata access if needed
   - Try different field naming patterns if needed
   - Investigate UI integration if needed

The debugging will help us pinpoint exactly where the issue is occurring!
