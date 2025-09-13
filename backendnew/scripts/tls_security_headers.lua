-- @title HTTP Security Headers Analysis (Article 11 Compliance)
-- @description Validates comprehensive HTTP security headers for web applications in compliance with Moldovan Cybersecurity Law Article 11 (Security Measures)
-- @category Web Security
-- @compliance_article Article 11 - Security Measures
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.1
-- @asset_types service
-- @requires_passed http_probe.lua

-- Only run on service assets that have HTTP detected
if asset.type ~= "service" then
    log("Skipping security headers check - not a service asset")
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
local web_ports = {80, 443, 8080, 8443, 8000, 8008, 3000, 5000}
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

log("Analyzing HTTP security headers for: " .. host .. ":" .. port)

-- Define comprehensive security headers with scoring
local security_headers = {
    -- Critical security headers (high score)
    ["strict-transport-security"] = {
        name = "HSTS",
        score = 3,
        required = true,
        description = "HTTP Strict Transport Security"
    },
    ["content-security-policy"] = {
        name = "CSP",
        score = 3,
        required = true,
        description = "Content Security Policy"
    },
    ["x-frame-options"] = {
        name = "X-Frame-Options",
        score = 2,
        required = true,
        description = "Clickjacking protection"
    },
    ["x-content-type-options"] = {
        name = "X-Content-Type-Options",
        score = 2,
        required = true,
        description = "MIME type sniffing protection"
    },
    
    -- Important security headers (medium score)
    ["referrer-policy"] = {
        name = "Referrer-Policy",
        score = 2,
        required = false,
        description = "Referrer information control"
    },
    ["permissions-policy"] = {
        name = "Permissions-Policy",
        score = 2,
        required = false,
        description = "Feature policy control"
    },
    ["x-xss-protection"] = {
        name = "X-XSS-Protection",
        score = 1,
        required = false,
        description = "XSS filtering (legacy)"
    },
    
    -- Additional security headers (lower score)
    ["expect-ct"] = {
        name = "Expect-CT",
        score = 1,
        required = false,
        description = "Certificate Transparency"
    },
    ["public-key-pins"] = {
        name = "Public-Key-Pins",
        score = 1,
        required = false,
        description = "Certificate pinning"
    },
    ["cross-origin-opener-policy"] = {
        name = "COOP",
        score = 1,
        required = false,
        description = "Cross-Origin Opener Policy"
    },
    ["cross-origin-embedder-policy"] = {
        name = "COEP",
        score = 1,
        required = false,
        description = "Cross-Origin Embedder Policy"
    },
    ["cross-origin-resource-policy"] = {
        name = "CORP",
        score = 1,
        required = false,
        description = "Cross-Origin Resource Policy"
    }
}

-- Function to analyze security header values
local function analyze_header_value(header_name, header_value)
    local analysis = {
        present = true,
        value = header_value,
        secure = false,
        issues = {},
        score_multiplier = 1.0
    }
    
    local lower_header = string.lower(header_name)
    local lower_value = string.lower(header_value)
    
    if lower_header == "strict-transport-security" then
        -- Analyze HSTS configuration
        local max_age = string.match(header_value, "max%-age=(%d+)")
        if max_age then
            local max_age_num = tonumber(max_age)
            if max_age_num >= 31536000 then -- 1 year
                analysis.secure = true
                log("HSTS max-age is secure (≥ 1 year)")
            elseif max_age_num >= 86400 then -- 1 day
                analysis.secure = true
                analysis.score_multiplier = 0.8
                table.insert(analysis.issues, "HSTS max-age could be longer")
            else
                analysis.score_multiplier = 0.5
                table.insert(analysis.issues, "HSTS max-age is too short")
            end
        else
            analysis.score_multiplier = 0.3
            table.insert(analysis.issues, "HSTS missing max-age")
        end
        
        if string.match(header_value, "includeSubDomains") then
            log("HSTS includes subdomains")
        else
            analysis.score_multiplier = analysis.score_multiplier * 0.9
        end
        
    elseif lower_header == "content-security-policy" then
        -- Analyze CSP configuration
        if string.match(lower_value, "unsafe%-inline") then
            analysis.score_multiplier = 0.6
            table.insert(analysis.issues, "CSP allows unsafe-inline")
        end
        
        if string.match(lower_value, "unsafe%-eval") then
            analysis.score_multiplier = analysis.score_multiplier * 0.7
            table.insert(analysis.issues, "CSP allows unsafe-eval")
        end
        
        if string.match(lower_value, "'self'") then
            analysis.secure = true
            log("CSP includes 'self' directive")
        end
        
        if string.match(lower_value, "frame%-ancestors") then
            log("CSP includes frame-ancestors directive")
        else
            analysis.score_multiplier = analysis.score_multiplier * 0.9
        end
        
    elseif lower_header == "x-frame-options" then
        -- Analyze X-Frame-Options
        if lower_value == "deny" or lower_value == "sameorigin" then
            analysis.secure = true
            log("X-Frame-Options is properly configured: " .. header_value)
        elseif string.match(lower_value, "allow%-from") then
            analysis.score_multiplier = 0.8
            log("X-Frame-Options uses allow-from (consider CSP frame-ancestors)")
        else
            analysis.score_multiplier = 0.5
            table.insert(analysis.issues, "X-Frame-Options has weak value")
        end
        
    elseif lower_header == "x-content-type-options" then
        -- Analyze X-Content-Type-Options
        if lower_value == "nosniff" then
            analysis.secure = true
            log("X-Content-Type-Options properly set to nosniff")
        else
            analysis.score_multiplier = 0.3
            table.insert(analysis.issues, "X-Content-Type-Options should be 'nosniff'")
        end
        
    elseif lower_header == "referrer-policy" then
        -- Analyze Referrer-Policy
        local secure_policies = {
            "no-referrer", "same-origin", "strict-origin", 
            "strict-origin-when-cross-origin"
        }
        
        for _, policy in ipairs(secure_policies) do
            if lower_value == policy then
                analysis.secure = true
                log("Referrer-Policy is secure: " .. header_value)
                break
            end
        end
        
        if not analysis.secure then
            analysis.score_multiplier = 0.6
            table.insert(analysis.issues, "Referrer-Policy could be more restrictive")
        end
        
    elseif lower_header == "x-xss-protection" then
        -- Analyze X-XSS-Protection (note: deprecated but still checked)
        if lower_value == "1; mode=block" or lower_value == "0" then
            analysis.secure = true
            log("X-XSS-Protection configured correctly")
        else
            analysis.score_multiplier = 0.7
            table.insert(analysis.issues, "X-XSS-Protection should be '1; mode=block' or '0'")
        end
    else
        -- For other headers, just check that they exist
        analysis.secure = true
    end
    
    return analysis
end

-- Function to fetch and analyze all security headers
local function analyze_security_headers(host, port)
    local scheme = (port == 443 or port == 8443) and "https" or "http"
    local url = scheme .. "://" .. host .. ":" .. port
    
    log("Fetching security headers from: " .. url)
    
    local status, body, headers, err = http.get(url, {
        ["User-Agent"] = "RegTech-Security-Headers-Scanner/1.0",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }, 15)
    
    if err then
        log("Failed to fetch headers: " .. err)
        return false, err, {}
    end
    
    local analysis_results = {
        url = url,
        status_code = status,
        headers_found = {},
        headers_missing = {},
        total_score = 0,
        max_possible_score = 0,
        security_issues = {}
    }
    
    -- Analyze each security header
    for header_key, header_info in pairs(security_headers) do
        analysis_results.max_possible_score = analysis_results.max_possible_score + header_info.score
        
        local header_found = false
        local header_value = nil
        
        -- Find header in response (case-insensitive)
        if headers then
            for response_header, response_value in pairs(headers) do
                if string.lower(response_header) == header_key then
                    header_found = true
                    header_value = response_value
                    break
                end
            end
        end
        
        if header_found then
            local header_analysis = analyze_header_value(header_key, header_value)
            
            analysis_results.headers_found[header_key] = {
                name = header_info.name,
                value = header_value,
                score = header_info.score * header_analysis.score_multiplier,
                secure = header_analysis.secure,
                issues = header_analysis.issues
            }
            
            analysis_results.total_score = analysis_results.total_score + (header_info.score * header_analysis.score_multiplier)
            
            -- Collect security issues
            for _, issue in ipairs(header_analysis.issues) do
                table.insert(analysis_results.security_issues, header_info.name .. ": " .. issue)
            end
            
            log("Found " .. header_info.name .. ": " .. header_value)
        else
            analysis_results.headers_missing[header_key] = header_info
            
            if header_info.required then
                table.insert(analysis_results.security_issues, "Missing required header: " .. header_info.name)
            end
            
            log("Missing header: " .. header_info.name)
        end
    end
    
    return true, nil, analysis_results
end

-- Perform security headers analysis
local headers_ok, headers_err, headers_analysis = analyze_security_headers(host, port)

if not headers_ok then
    log("Security headers analysis failed: " .. tostring(headers_err))
    set_metadata("security_headers.analysis_failed", true)
    set_metadata("security_headers.error", headers_err)
    
    fail_checklist("http-security-headers-013", "Security headers analysis failed: " .. tostring(headers_err))
    reject("Security headers analysis failed")
    return
end

-- Set comprehensive metadata
set_metadata("security_headers.url", headers_analysis.url)
set_metadata("security_headers.status_code", headers_analysis.status_code)
set_metadata("security_headers.total_score", headers_analysis.total_score)
set_metadata("security_headers.max_possible_score", headers_analysis.max_possible_score)

-- Calculate compliance percentage
local compliance_percentage = 0
if headers_analysis.max_possible_score > 0 then
    compliance_percentage = math.floor((headers_analysis.total_score / headers_analysis.max_possible_score) * 100)
end
set_metadata("security_headers.compliance_percentage", compliance_percentage)

-- Set found headers metadata
local found_count = 0
for header_key, header_data in pairs(headers_analysis.headers_found) do
    found_count = found_count + 1
    set_metadata("security_headers.found." .. header_key, header_data.value)
    set_metadata("security_headers.score." .. header_key, header_data.score)
end
set_metadata("security_headers.found_count", found_count)

-- Set missing headers metadata
local missing_count = 0
local missing_critical = 0
for header_key, header_info in pairs(headers_analysis.headers_missing) do
    missing_count = missing_count + 1
    if header_info.required then
        missing_critical = missing_critical + 1
    end
end
set_metadata("security_headers.missing_count", missing_count)
set_metadata("security_headers.missing_critical", missing_critical)

-- Set security issues
if #headers_analysis.security_issues > 0 then
    set_metadata("security_headers.issues", table.concat(headers_analysis.security_issues, "; "))
end

log("Security headers score: " .. headers_analysis.total_score .. "/" .. headers_analysis.max_possible_score .. " (" .. compliance_percentage .. "%)")
log("Found " .. found_count .. " headers, missing " .. missing_count .. " (" .. missing_critical .. " critical)")

-- Evaluate compliance level for Moldovan Cybersecurity Law
local compliance_level = "insufficient"
local compliance_status = "fail"

if compliance_percentage >= 85 and missing_critical == 0 then
    compliance_level = "excellent"
    compliance_status = "pass"
    log("Excellent security headers configuration")
    
elseif compliance_percentage >= 70 and missing_critical <= 1 then
    compliance_level = "good"
    compliance_status = "pass"
    log("Good security headers configuration")
    
elseif compliance_percentage >= 50 and missing_critical <= 2 then
    compliance_level = "acceptable"
    compliance_status = "conditional"
    log("Acceptable security headers configuration with issues")
    
else
    compliance_level = "insufficient"
    compliance_status = "fail"
    log("Insufficient security headers configuration")
end

set_metadata("security_headers.compliance_level", compliance_level)
set_metadata("security_headers.compliance_status", compliance_status)

-- Update compliance checklists
if compliance_status == "pass" then
    local pass_message = compliance_level:gsub("^%l", string.upper) .. " security headers configuration"
    pass_message = pass_message .. " (" .. compliance_percentage .. "% compliance)"
    
    pass_checklist("http-security-headers-013", pass_message)
    pass_checklist("web-security-hardening-018", "Security headers properly configured")
    
    log("Security headers compliance: PASS - " .. compliance_level)
    pass()
    
elseif compliance_status == "conditional" then
    local conditional_message = "Security headers acceptable but incomplete"
    if #headers_analysis.security_issues > 0 then
        conditional_message = conditional_message .. ": " .. table.concat(headers_analysis.security_issues, "; ")
    end
    conditional_message = conditional_message .. " (" .. compliance_percentage .. "% compliance)"
    
    pass_checklist("http-security-headers-013", conditional_message)
    fail_checklist("web-security-hardening-018", "Security headers have issues")
    
    log("Security headers compliance: CONDITIONAL - " .. conditional_message)
    pass()
    
else
    local fail_message = "Insufficient security headers"
    if missing_critical > 0 then
        fail_message = fail_message .. " (missing " .. missing_critical .. " critical headers)"
    end
    if #headers_analysis.security_issues > 0 then
        fail_message = fail_message .. ": " .. table.concat(headers_analysis.security_issues, "; ")
    end
    fail_message = fail_message .. " (" .. compliance_percentage .. "% compliance)"
    
    fail_checklist("http-security-headers-013", fail_message)
    fail_checklist("web-security-hardening-018", "Security headers insufficient")
    
    log("Security headers compliance: FAIL - " .. fail_message)
    reject("Security headers insufficient")
end

-- Add descriptive tags
if compliance_level == "excellent" then
    add_tag("excellent-security-headers")
elseif compliance_level == "good" then
    add_tag("good-security-headers")
elseif compliance_level == "acceptable" then
    add_tag("basic-security-headers")
else
    add_tag("weak-security-headers")
end

-- Add specific header tags
for header_key, _ in pairs(headers_analysis.headers_found) do
    local tag_name = string.gsub(header_key, "%-", "_")
    add_tag("has_" .. tag_name)
end

if missing_critical > 0 then
    add_tag("missing-critical-headers")
end

if #headers_analysis.security_issues > 0 then
    add_tag("security-header-issues")
end