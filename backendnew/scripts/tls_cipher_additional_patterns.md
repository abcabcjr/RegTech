# TLS Cipher Strength Additional Field Patterns

## Problem
Despite setting multiple compliance status fields, the TLS Cipher Strength was still displaying as N/A instead of NON_COMPLIANT.

## Investigation
I analyzed how other scripts set their compliance status and found that:
1. **Existing `tls_cipher_analysis.lua`** uses `cipher.compliance_status` and `cipher.strength`
2. **Other scripts** use `{category}.compliance_status` pattern
3. **Status values** might need to be "fail" instead of "NON_COMPLIANT"

## Additional Field Patterns Added

### 1. Category-Based Fields (Following Other Scripts)
```lua
-- Try the pattern used by other cipher scripts
set_metadata("cipher.compliance_status", "NON_COMPLIANT")
set_metadata("cipher.status", "NON_COMPLIANT")
set_metadata("cipher.strength", "insufficient")
```

### 2. Exact Pattern from tls_cipher_analysis.lua
```lua
-- Try the exact pattern from tls_cipher_analysis.lua
set_metadata("cipher.compliance_status", "fail")
set_metadata("cipher.strength", "insufficient")
```

## Complete Field Coverage

Your HTTP service should now have these additional fields:

```json
{
  // Existing fields (all working correctly)
  "tls_cipher_strength.compliance_status": "NON_COMPLIANT",
  "tls_cipher_strength.status": "NON_COMPLIANT",
  "tls_cipher_strength.result": "FAIL",
  "tls_cipher_strength.compliance": "NON_COMPLIANT",
  "tls_cipher_strength.final_status": "NON_COMPLIANT",
  "tls_cipher_strength.overall_status": "NON_COMPLIANT",
  
  // NEW: Category-based fields (following other scripts)
  "cipher.compliance_status": "NON_COMPLIANT",
  "cipher.status": "NON_COMPLIANT", 
  "cipher.strength": "insufficient",
  
  // NEW: Exact pattern from existing cipher script
  "cipher.compliance_status": "fail",  // This overwrites the above
  "cipher.strength": "insufficient"    // This overwrites the above
}
```

## Why This Should Work

### 1. Pattern Matching
The system might be looking for `cipher.compliance_status` specifically, which is the pattern used by the existing `tls_cipher_analysis.lua` script.

### 2. Status Value Format
The existing cipher script uses `"fail"` instead of `"NON_COMPLIANT"`, so the system might expect that specific value.

### 3. Field Naming Convention
Other scripts use `{category}.compliance_status` rather than `{category}_{type}.compliance_status`.

## Expected Results

After this fix, the TLS Cipher Strength should display as:
- **NON_COMPLIANT** (or equivalent) instead of N/A for HTTP services missing TLS
- The system should find the correct status using one of the multiple field patterns

## Fallback Strategy

If it still shows N/A, the issue might be:
1. **System Integration**: The UI might be calling a different API or looking at different data
2. **Caching**: Results might be cached and need to be refreshed
3. **Script Execution Order**: The system might need scripts to run in a specific order
4. **Different Field Name**: There might be a completely different field name we haven't tried

In that case, we can:
1. Check if there's a specific API endpoint for TLS Cipher Strength
2. Look at the system's source code or documentation
3. Try completely different field names
4. Check if the issue is in the UI layer rather than the script

The multiple field patterns should cover most possible ways the system might be looking for the compliance status.
