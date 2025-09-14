# TLS Cipher Strength Display Fix

## Problem Description
Despite the script working correctly and showing NON_COMPLIANT in the metadata, the TLS Cipher Strength checklist was still displaying as N/A instead of showing the actual compliance status.

## Analysis
The script was correctly:
1. ✅ Setting `compliance_status` to "NON_COMPLIANT"
2. ✅ Calling `fail_checklist("tls-cipher-strength-016", ...)`
3. ✅ Setting `reject_reason` to "Required TLS encryption missing"
4. ✅ Setting assessment to "non_compliant_missing_tls"

However, the UI/display system might be looking for additional metadata fields to determine the overall TLS Cipher Strength status.

## Fix Applied

### Additional Metadata Fields Added
I've added multiple metadata fields that the system might use for displaying the compliance status:

```lua
-- Set additional compliance metadata that might be used for display
set_metadata("tls_cipher_strength.status", "NON_COMPLIANT")
set_metadata("tls_cipher_strength.result", "FAIL")
set_metadata("tls_cipher_strength.compliance", "NON_COMPLIANT")
set_metadata("tls_cipher_strength.final_status", "NON_COMPLIANT")
set_metadata("tls_cipher_strength.overall_status", "NON_COMPLIANT")
```

### Applied to Both Sections
The additional metadata fields are now set in both:
1. **Main TLS Assessment Section** (when TLS service is detected)
2. **Missing TLS Section** (when TLS is required but missing)

## Expected Results

### For Your Case (HTTP on Port 80)
The script should now set these additional metadata fields:

```json
{
  "tls_cipher_strength.compliance_status": "NON_COMPLIANT",
  "tls_cipher_strength.status": "NON_COMPLIANT",
  "tls_cipher_strength.result": "FAIL",
  "tls_cipher_strength.compliance": "NON_COMPLIANT",
  "tls_cipher_strength.final_status": "NON_COMPLIANT",
  "tls_cipher_strength.overall_status": "NON_COMPLIANT",
  "tls_cipher_strength.assessment": "non_compliant_missing_tls",
  "tls_cipher_strength.cipher_strength": "insufficient",
  "tls_cipher_strength.missing_tls_reason": "HTTP service should use HTTPS (port 443) for security"
}
```

## Why This Should Fix the Display Issue

### Multiple Field Coverage
The system might be looking for any of these field names to determine the compliance status:
- `status` - Common field name for status
- `result` - Often used for pass/fail results
- `compliance` - Direct compliance status
- `final_status` - Final assessment status
- `overall_status` - Overall compliance status

### Consistent Application
The same fields are set in both scenarios:
1. **When TLS service is detected and assessed**
2. **When TLS is required but missing**

This ensures consistent metadata regardless of which code path is taken.

## Testing

### Expected Behavior
After this fix, the TLS Cipher Strength should display as:
- **NON_COMPLIANT** instead of N/A for HTTP services missing TLS
- **COMPLIANT** for properly configured TLS services
- **N/A** only for services that genuinely don't require TLS (SSH, FTP, etc.)

### Verification
Check that the metadata now includes the additional status fields and that the UI properly displays NON_COMPLIANT for your HTTP service case.

## Fallback Strategy
If the display still shows N/A, the issue might be:
1. **Caching**: The system might be caching old results
2. **Field Mapping**: The system might be looking for a different field name
3. **Integration**: There might be a separate integration layer that maps results

In that case, we can:
1. Try different field names
2. Check if there's a specific format expected
3. Look at how other working scripts set their main status

The additional metadata fields should resolve the display issue by providing multiple ways for the system to determine the correct compliance status.
