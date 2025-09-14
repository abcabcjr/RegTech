# Metadata Access Fix Summary

## Problem Description
All three newly created scripts were failing with the same Lua execution error:
```
Lua execution error: <string>:46: attempt to call a non-function object
stack traceback:
	<string>:46: in function 'detect_*_service'
```

## Root Cause
The scripts were trying to use `get_metadata("key")` function which is not available in the Lua execution environment. The error occurred because `get_metadata` was `nil` and we were attempting to call it as a function.

## Scripts Affected
1. `web_security_hardening.lua` - Line 47
2. `http_headers.lua` - Line 46  
3. `tls_cipher_strength.lua` - Line 46

## Incorrect Code Pattern
```lua
-- ❌ WRONG - get_metadata() function doesn't exist
local detected_service = get_metadata("service.port." .. port)
local service_banner = get_metadata("banner.port." .. port)
local service_confidence = get_metadata("service.confidence.port." .. port)
```

## Correct Code Pattern
```lua
-- ✅ CORRECT - Use asset.scan_metadata with safe access
local detected_service = asset.scan_metadata and asset.scan_metadata["service.port." .. port]
local service_banner = asset.scan_metadata and asset.scan_metadata["banner.port." .. port]
local service_confidence = asset.scan_metadata and asset.scan_metadata["service.confidence.port." .. port]
```

## Key Differences

### 1. Metadata Access Method
- **Wrong**: `get_metadata("key")` - Function call that doesn't exist
- **Correct**: `asset.scan_metadata["key"]` - Direct table access

### 2. Safe Access Pattern  
- **Wrong**: Direct function call without checking existence
- **Correct**: `asset.scan_metadata and asset.scan_metadata["key"]` - Safe access with nil checking

### 3. Evidence from Existing Scripts
Looking at working scripts like `tls_compliance_checklist.lua`, we can see the correct pattern:
```lua
if asset.scan_metadata and asset.scan_metadata["tls.supported"] then
    results.tls_supported = asset.scan_metadata["tls.supported"]
    -- ... more metadata access
end
```

## Fix Applied
Replaced all instances of:
```lua
get_metadata("service.port." .. port)
```

With:
```lua
asset.scan_metadata and asset.scan_metadata["service.port." .. port]
```

This ensures:
1. **No function call errors**: We're accessing a table, not calling a function
2. **Safe nil handling**: The `and` operator prevents errors if `asset.scan_metadata` is nil
3. **Consistent with existing code**: Matches the pattern used in working scripts

## Testing
After the fix, the scripts should:
1. ✅ Execute without Lua errors
2. ✅ Properly access banner grab metadata when available
3. ✅ Handle cases where metadata is not available (nil values)
4. ✅ Continue with port-based detection as fallback

## Prevention
For future scripts, always use:
- `asset.scan_metadata["key"]` for metadata access
- Safe access pattern: `asset.scan_metadata and asset.scan_metadata["key"]`
- Check existing working scripts for reference patterns

The scripts should now execute successfully and properly integrate with banner grab results for service detection.
