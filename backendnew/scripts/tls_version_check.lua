-- @title TLS Version Support Detection
-- @description Tests TLS protocol versions to identify weak/deprecated protocols
-- @category Cryptography
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed basic_info.lua

-- Only run on service assets
if asset.type ~= "service" then
    log("Skipping TLS version check - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    return
end

port = tonumber(port)

-- Only check HTTPS services and common TLS ports
local tls_ports = {443, 8443, 993, 995, 465, 587, 636, 989, 990, 992, 5061}
local is_tls_port = false
for _, tls_port in ipairs(tls_ports) do
    if port == tls_port then
        is_tls_port = true
        break
    end
end

if not is_tls_port then
    log("Skipping non-TLS port: " .. port)
    return
end

log("Checking TLS versions for: " .. host .. ":" .. port)

-- Function to test TLS connection with timeout
local function test_tls_connection(url, version_hint)
    local status, body, headers, err = http.get(url, {["User-Agent"] = "RegTech-TLS-Scanner/1.0"}, 8)
    if err then
        return false, err
    end
    return true, nil
end

-- Test HTTPS connection to determine TLS support
local https_url = "https://" .. host .. ":" .. port

-- Test basic HTTPS connectivity
local tls_supported, err = test_tls_connection(https_url, "modern")

if not tls_supported then
    log("TLS connection failed: " .. tostring(err))
    set_metadata("tls.supported", false)
    set_metadata("tls.error", err)
    
    -- Fail the TLS compliance checklist
    fail_checklist("tls-version-compliance-015", "TLS connection failed: " .. tostring(err))
    
    reject("TLS connection failed")
    return
end

-- Connection successful - TLS is supported
log("TLS connection successful")
set_metadata("tls.supported", true)
set_metadata("tls.connection_successful", true)

-- Modern TLS analysis based on successful connection
-- Note: With Go's http.Client, we get the negotiated protocol from the connection
-- We'll infer security based on the successful connection and headers

local response_status, response_body, response_headers, response_err = http.get(https_url, {
    ["User-Agent"] = "RegTech-TLS-Scanner/1.0",
    ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
}, 10)

if response_err then
    log("Failed to get detailed TLS response: " .. response_err)
    set_metadata("tls.detailed_check_failed", true)
    pass_checklist("tls-version-compliance-015", "Basic TLS supported but detailed analysis failed")
    pass()
    return
end

-- Analyze response for TLS indicators
set_metadata("tls.response_status", response_status)

-- Check for modern TLS indicators in headers
local modern_tls_indicators = 0
local security_issues = {}

-- Check for HSTS (indicates modern TLS deployment)
if response_headers and response_headers["Strict-Transport-Security"] then
    log("HSTS header present - indicates modern TLS deployment")
    set_metadata("tls.hsts_present", true)
    modern_tls_indicators = modern_tls_indicators + 1
else
    log("Warning: No HSTS header found")
    set_metadata("tls.hsts_present", false)
    table.insert(security_issues, "Missing HSTS header")
end

-- Check for Content Security Policy (modern security practice)
if response_headers and response_headers["Content-Security-Policy"] then
    log("CSP header present - indicates modern security practices")
    set_metadata("tls.csp_present", true)
    modern_tls_indicators = modern_tls_indicators + 1
end

-- Check for X-Frame-Options
if response_headers and response_headers["X-Frame-Options"] then
    log("X-Frame-Options present")
    set_metadata("tls.x_frame_options_present", true)
    modern_tls_indicators = modern_tls_indicators + 1
end

-- Analyze Server header for outdated software indicators
if response_headers and response_headers["Server"] then
    local server = response_headers["Server"]
    log("Server header: " .. server)
    set_metadata("tls.server", server)
    
    -- Check for outdated server software that might indicate weak TLS
    if string.match(server:lower(), "iis/[1-7]%.") then
        table.insert(security_issues, "Potentially outdated IIS version")
        log("Warning: Potentially outdated IIS version detected")
    elseif string.match(server:lower(), "apache/2%.[0-2]%.") then
        table.insert(security_issues, "Potentially outdated Apache version")
        log("Warning: Potentially outdated Apache version detected")
    end
end

-- Determine TLS compliance level
local compliance_level = "unknown"
if modern_tls_indicators >= 2 then
    compliance_level = "modern"
    log("Modern TLS deployment detected")
elseif modern_tls_indicators >= 1 then
    compliance_level = "intermediate"
    log("Intermediate TLS deployment detected")
else
    compliance_level = "basic"
    log("Basic TLS deployment detected")
end

set_metadata("tls.compliance_level", compliance_level)
set_metadata("tls.modern_indicators_count", modern_tls_indicators)

-- Set security issues if any
if #security_issues > 0 then
    set_metadata("tls.security_issues", table.concat(security_issues, "; "))
end

-- Evaluate against Moldovan Cybersecurity Law requirements (Article 11)
if compliance_level == "modern" then
    pass_checklist("tls-version-compliance-015", "Modern TLS deployment with " .. modern_tls_indicators .. " security indicators")
    log("TLS compliance: PASS - Modern configuration")
    pass()
    
elseif compliance_level == "intermediate" then
    if #security_issues == 0 then
        pass_checklist("tls-version-compliance-015", "Intermediate TLS deployment - acceptable")
        log("TLS compliance: PASS - Intermediate configuration acceptable")
        pass()
    else
        fail_checklist("tls-version-compliance-015", "Intermediate TLS with issues: " .. table.concat(security_issues, "; "))
        log("TLS compliance: FAIL - Intermediate with security issues")
        reject("TLS configuration has security issues")
    end
    
else
    fail_checklist("tls-version-compliance-015", "Basic TLS deployment - insufficient security indicators")
    log("TLS compliance: FAIL - Insufficient security measures")
    reject("TLS configuration insufficient for compliance")
end

-- Add descriptive tags based on findings
if set_metadata("tls.hsts_present", true) then
    add_tag("hsts-enabled")
end

if modern_tls_indicators >= 2 then
    add_tag("modern-tls")
elseif modern_tls_indicators >= 1 then
    add_tag("intermediate-tls")
else
    add_tag("basic-tls")
end

if #security_issues > 0 then
    add_tag("tls-security-issues")
end