-- @title HSTS Policy Validation
-- @description Validates HTTP Strict Transport Security implementation and policies
-- @category Web Security
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed tls_certificate_check.lua

-- Only run on service assets that passed certificate check
if asset.type ~= "service" then
    log("Skipping HSTS validation - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    return
end

port = tonumber(port)

-- Only check HTTP/HTTPS services
local web_ports = {80, 443, 8080, 8443, 8000, 8008}
local is_web_port = false
for _, web_port in ipairs(web_ports) do
    if port == web_port then
        is_web_port = true
        break
    end
end

if not is_web_port then
    log("Skipping non-web port: " .. port)
    return
end

log("Validating HSTS policy for: " .. host .. ":" .. port)

-- Function to test HTTP to HTTPS redirect
local function test_http_redirect(host, web_port)
    local http_port = web_port == 443 and 80 or (web_port == 8443 and 8080 or web_port)
    local http_url = "http://" .. host .. ":" .. http_port
    
    log("Testing HTTP redirect from: " .. http_url)
    
    local status, body, headers, err = http.get(http_url, {
        ["User-Agent"] = "RegTech-HSTS-Validator/1.0"
    }, 8)
    
    if err then
        log("HTTP request failed: " .. err)
        return false, err, {}
    end
    
    local redirect_info = {
        status_code = status,
        has_redirect = false,
        redirect_to_https = false,
        redirect_location = nil
    }
    
    -- Check for redirect status codes
    if status >= 300 and status < 400 then
        redirect_info.has_redirect = true
        
        if headers and headers["Location"] then
            local location = headers["Location"]
            redirect_info.redirect_location = location
            
            if string.match(location, "^https://") then
                redirect_info.redirect_to_https = true
                log("HTTP properly redirects to HTTPS: " .. location)
            else
                log("Warning: HTTP redirects but not to HTTPS: " .. location)
            end
        else
            log("Warning: Redirect status but no Location header")
        end
    elseif status == 200 then
        log("Warning: HTTP request returns 200 OK (no redirect to HTTPS)")
    else
        log("HTTP request returned status: " .. status)
    end
    
    return true, nil, redirect_info
end

-- Function to analyze HSTS header
local function analyze_hsts_header(hsts_value)
    local hsts_analysis = {
        valid = false,
        max_age = 0,
        include_subdomains = false,
        preload = false,
        issues = {}
    }
    
    if not hsts_value or hsts_value == "" then
        table.insert(hsts_analysis.issues, "HSTS header is empty")
        return hsts_analysis
    end
    
    log("Analyzing HSTS header: " .. hsts_value)
    
    -- Parse max-age
    local max_age_str = string.match(hsts_value, "max%-age=(%d+)")
    if max_age_str then
        hsts_analysis.max_age = tonumber(max_age_str)
        hsts_analysis.valid = true
        log("HSTS max-age: " .. max_age_str .. " seconds")
        
        -- Validate max-age value
        if hsts_analysis.max_age < 3600 then -- Less than 1 hour
            table.insert(hsts_analysis.issues, "HSTS max-age too short (< 1 hour)")
        elseif hsts_analysis.max_age < 86400 then -- Less than 1 day
            table.insert(hsts_analysis.issues, "HSTS max-age should be at least 1 day")
        elseif hsts_analysis.max_age >= 31536000 then -- 1 year or more
            log("HSTS max-age meets recommended duration (≥ 1 year)")
        end
    else
        table.insert(hsts_analysis.issues, "HSTS header missing max-age directive")
    end
    
    -- Check for includeSubDomains
    if string.match(hsts_value, "includeSubDomains") then
        hsts_analysis.include_subdomains = true
        log("HSTS includeSubDomains directive present")
    else
        log("HSTS includeSubDomains directive not present")
    end
    
    -- Check for preload
    if string.match(hsts_value, "preload") then
        hsts_analysis.preload = true
        log("HSTS preload directive present")
    else
        log("HSTS preload directive not present")
    end
    
    return hsts_analysis
end

-- Function to test HSTS policy comprehensively
local function validate_hsts_policy(host, port)
    local https_url = "https://" .. host .. ":" .. port
    
    -- Test HTTPS endpoint for HSTS header
    local status, body, headers, err = http.get(https_url, {
        ["User-Agent"] = "RegTech-HSTS-Validator/1.0"
    }, 10)
    
    if err then
        log("HTTPS request failed: " .. err)
        return false, err, {}
    end
    
    local hsts_policy = {
        https_accessible = true,
        status_code = status,
        has_hsts_header = false,
        hsts_value = nil,
        hsts_analysis = nil
    }
    
    -- Check for HSTS header
    if headers and headers["Strict-Transport-Security"] then
        hsts_policy.has_hsts_header = true
        hsts_policy.hsts_value = headers["Strict-Transport-Security"]
        hsts_policy.hsts_analysis = analyze_hsts_header(hsts_policy.hsts_value)
        log("HSTS header found")
    else
        log("Warning: No HSTS header found in HTTPS response")
    end
    
    return true, nil, hsts_policy
end

-- Perform HSTS validation
local hsts_ok, hsts_err, hsts_policy = validate_hsts_policy(host, port)

if not hsts_ok then
    log("HSTS validation failed: " .. tostring(hsts_err))
    set_metadata("hsts.validation_failed", true)
    set_metadata("hsts.error", hsts_err)
    
    fail_checklist("http-security-headers-013", "HSTS validation failed: " .. tostring(hsts_err))
    reject("HSTS validation failed")
    return
end

-- Test HTTP redirect behavior
local redirect_ok, redirect_err, redirect_info = test_http_redirect(host, port)

-- Set basic HSTS metadata
set_metadata("hsts.https_accessible", hsts_policy.https_accessible)
set_metadata("hsts.has_hsts_header", hsts_policy.has_hsts_header)

if hsts_policy.hsts_value then
    set_metadata("hsts.header_value", hsts_policy.hsts_value)
end

-- Analyze HSTS configuration
local hsts_score = 0
local hsts_issues = {}

-- Base score for HTTPS accessibility
if hsts_policy.https_accessible then
    hsts_score = hsts_score + 1
    log("HTTPS accessible (+1 point)")
end

-- HSTS header presence and validity
if hsts_policy.has_hsts_header and hsts_policy.hsts_analysis then
    local analysis = hsts_policy.hsts_analysis
    
    if analysis.valid then
        hsts_score = hsts_score + 3
        log("Valid HSTS header (+3 points)")
        
        -- Max-age scoring
        if analysis.max_age >= 31536000 then -- 1 year
            hsts_score = hsts_score + 3
            log("HSTS max-age ≥ 1 year (+3 points)")
        elseif analysis.max_age >= 86400 then -- 1 day
            hsts_score = hsts_score + 2
            log("HSTS max-age ≥ 1 day (+2 points)")
        elseif analysis.max_age >= 3600 then -- 1 hour
            hsts_score = hsts_score + 1
            log("HSTS max-age ≥ 1 hour (+1 point)")
        end
        
        -- includeSubDomains directive
        if analysis.include_subdomains then
            hsts_score = hsts_score + 1
            log("HSTS includeSubDomains (+1 point)")
        end
        
        -- preload directive
        if analysis.preload then
            hsts_score = hsts_score + 1
            log("HSTS preload directive (+1 point)")
        end
    else
        table.insert(hsts_issues, "Invalid HSTS header")
    end
    
    -- Add any header-specific issues
    for _, issue in ipairs(analysis.issues) do
        table.insert(hsts_issues, issue)
    end
    
    -- Set detailed HSTS metadata
    set_metadata("hsts.max_age", analysis.max_age)
    set_metadata("hsts.include_subdomains", analysis.include_subdomains)
    set_metadata("hsts.preload", analysis.preload)
    set_metadata("hsts.valid", analysis.valid)
else
    table.insert(hsts_issues, "No HSTS header found")
end

-- HTTP redirect analysis
if redirect_ok and redirect_info then
    set_metadata("hsts.http_redirect_tested", true)
    set_metadata("hsts.http_has_redirect", redirect_info.has_redirect)
    set_metadata("hsts.http_redirects_to_https", redirect_info.redirect_to_https)
    
    if redirect_info.redirect_location then
        set_metadata("hsts.http_redirect_location", redirect_info.redirect_location)
    end
    
    if redirect_info.redirect_to_https then
        hsts_score = hsts_score + 1
        log("HTTP properly redirects to HTTPS (+1 point)")
    elseif redirect_info.has_redirect then
        table.insert(hsts_issues, "HTTP redirects but not to HTTPS")
    else
        table.insert(hsts_issues, "HTTP does not redirect to HTTPS")
    end
else
    table.insert(hsts_issues, "Could not test HTTP redirect behavior")
end

-- Set HSTS issues if any
if #hsts_issues > 0 then
    set_metadata("hsts.issues", table.concat(hsts_issues, "; "))
end

-- Calculate HSTS compliance
local max_hsts_score = 10 -- 1 + 3 + 3 + 1 + 1 + 1
set_metadata("hsts.score", hsts_score)
set_metadata("hsts.max_score", max_hsts_score)

local hsts_percentage = math.floor((hsts_score / max_hsts_score) * 100)
set_metadata("hsts.compliance_percentage", hsts_percentage)

log("HSTS score: " .. hsts_score .. "/" .. max_hsts_score .. " (" .. hsts_percentage .. "%)")

-- Evaluate HSTS compliance level
local compliance_level = "insufficient"
local compliance_status = "fail"

if hsts_score >= 8 and #hsts_issues == 0 then
    compliance_level = "excellent"
    compliance_status = "pass"
    log("Excellent HSTS configuration")
    
elseif hsts_score >= 6 and #hsts_issues <= 1 then
    compliance_level = "good"
    compliance_status = "pass"
    log("Good HSTS configuration")
    
elseif hsts_score >= 4 and #hsts_issues <= 2 then
    compliance_level = "acceptable"
    compliance_status = "conditional"
    log("Acceptable HSTS configuration with minor issues")
    
else
    compliance_level = "insufficient"
    compliance_status = "fail"
    log("Insufficient HSTS configuration")
end

set_metadata("hsts.compliance_level", compliance_level)
set_metadata("hsts.compliance_status", compliance_status)

-- Update compliance checklists based on HSTS analysis
if compliance_status == "pass" then
    local pass_message = compliance_level:gsub("^%l", string.upper) .. " HSTS configuration"
    pass_message = pass_message .. " (score: " .. hsts_score .. "/" .. max_hsts_score .. ")"
    
    pass_checklist("http-security-headers-013", pass_message)
    
    -- Also pass web security checklist if HSTS is properly configured
    if hsts_score >= 6 then
        pass_checklist("web-security-hardening-018", "HSTS properly configured")
    end
    
    log("HSTS compliance: PASS - " .. compliance_level)
    pass()
    
elseif compliance_status == "conditional" then
    local conditional_message = "HSTS acceptable but has issues: " .. table.concat(hsts_issues, "; ")
    conditional_message = conditional_message .. " (score: " .. hsts_score .. "/" .. max_hsts_score .. ")"
    
    pass_checklist("http-security-headers-013", conditional_message)
    fail_checklist("web-security-hardening-018", "HSTS has security issues")
    
    log("HSTS compliance: CONDITIONAL - " .. conditional_message)
    pass()
    
else
    local fail_message = "Insufficient HSTS security"
    if #hsts_issues > 0 then
        fail_message = fail_message .. ": " .. table.concat(hsts_issues, "; ")
    end
    fail_message = fail_message .. " (score: " .. hsts_score .. "/" .. max_hsts_score .. ")"
    
    fail_checklist("http-security-headers-013", fail_message)
    fail_checklist("web-security-hardening-018", "HSTS configuration insufficient")
    
    log("HSTS compliance: FAIL - " .. fail_message)
    reject("HSTS configuration insufficient")
end

-- Add descriptive tags
if compliance_level == "excellent" then
    add_tag("excellent-hsts")
elseif compliance_level == "good" then
    add_tag("good-hsts")
elseif compliance_level == "acceptable" then
    add_tag("basic-hsts")
else
    add_tag("weak-hsts")
end

if hsts_policy.has_hsts_header then
    add_tag("hsts-enabled")
else
    add_tag("no-hsts")
end

if redirect_ok and redirect_info and redirect_info.redirect_to_https then
    add_tag("https-redirect")
end

if hsts_policy.hsts_analysis and hsts_policy.hsts_analysis.include_subdomains then
    add_tag("hsts-subdomains")
end

if hsts_policy.hsts_analysis and hsts_policy.hsts_analysis.preload then
    add_tag("hsts-preload")
end