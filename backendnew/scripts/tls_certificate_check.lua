-- @title TLS Certificate Validation
-- @description Validates TLS certificates for expiry, chain, and security properties
-- @category Cryptography
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed tls_version_check.lua

-- Only run on service assets that passed TLS version check
if asset.type ~= "service" then
    log("Skipping TLS certificate check - not a service asset")
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

log("Validating TLS certificate for: " .. host .. ":" .. port)

-- Function to test certificate validity through HTTPS connection
local function validate_certificate(host, port)
    local https_url = "https://" .. host .. ":" .. port
    
    -- Attempt HTTPS connection to validate certificate
    local status, body, headers, err = http.get(https_url, {
        ["User-Agent"] = "RegTech-Certificate-Validator/1.0"
    }, 15)
    
    if err then
        log("Certificate validation failed: " .. err)
        return false, err, {}
    end
    
    -- If connection succeeded, certificate is valid for basic trust
    local cert_info = {
        connection_successful = true,
        status_code = status,
        hostname = host,
        port = port
    }
    
    -- Analyze response headers for certificate-related security indicators
    if headers then
        -- Check for HSTS (indicates certificate is properly configured for security)
        if headers["Strict-Transport-Security"] then
            cert_info.hsts_present = true
            local hsts_value = headers["Strict-Transport-Security"]
            cert_info.hsts_value = hsts_value
            
            -- Parse HSTS max-age
            local max_age = string.match(hsts_value, "max%-age=(%d+)")
            if max_age then
                cert_info.hsts_max_age = tonumber(max_age)
                log("HSTS max-age: " .. max_age .. " seconds")
            end
        end
        
        -- Check for Public Key Pinning
        if headers["Public-Key-Pins"] then
            cert_info.public_key_pinning = true
            log("Public Key Pinning header present")
        end
        
        -- Check for Certificate Transparency
        if headers["Expect-CT"] then
            cert_info.certificate_transparency = true
            log("Certificate Transparency (Expect-CT) header present")
        end
        
        -- Store server information for certificate context
        if headers["Server"] then
            cert_info.server = headers["Server"]
        end
    end
    
    return true, nil, cert_info
end

-- Function to analyze certificate security based on connection behavior
local function analyze_certificate_security(cert_info)
    local security_score = 0
    local security_issues = {}
    
    -- Basic certificate validity (connection succeeded)
    if cert_info.connection_successful then
        security_score = security_score + 3
        log("Certificate allows successful TLS connection (+3 points)")
    else
        table.insert(security_issues, "Certificate validation failed")
        return 0, security_issues
    end
    
    -- HSTS configuration analysis
    if cert_info.hsts_present then
        security_score = security_score + 2
        log("HSTS header present (+2 points)")
        
        if cert_info.hsts_max_age then
            if cert_info.hsts_max_age >= 31536000 then -- 1 year
                security_score = security_score + 2
                log("HSTS max-age >= 1 year (+2 points)")
            elseif cert_info.hsts_max_age >= 86400 then -- 1 day
                security_score = security_score + 1
                log("HSTS max-age >= 1 day (+1 point)")
            else
                table.insert(security_issues, "HSTS max-age too short")
                log("Warning: HSTS max-age is very short")
            end
        end
    else
        table.insert(security_issues, "Missing HSTS header")
        log("Warning: No HSTS header found")
    end
    
    -- Advanced security features
    if cert_info.public_key_pinning then
        security_score = security_score + 1
        log("Public Key Pinning enabled (+1 point)")
    end
    
    if cert_info.certificate_transparency then
        security_score = security_score + 1
        log("Certificate Transparency enabled (+1 point)")
    end
    
    return security_score, security_issues
end

-- Function to test for common certificate vulnerabilities
local function test_certificate_vulnerabilities(host, port)
    local vulnerabilities = {}
    
    -- Test 1: Check if HTTP version is available (certificate not enforced)
    local http_url = "http://" .. host .. ":" .. (port == 443 and 80 or port)
    local http_status, http_body, http_headers, http_err = http.get(http_url, {
        ["User-Agent"] = "RegTech-HTTP-Test/1.0"
    }, 5)
    
    if not http_err and http_status then
        -- Check if HTTP redirects to HTTPS
        if http_status >= 300 and http_status < 400 and http_headers and http_headers["Location"] then
            local location = http_headers["Location"]
            if string.match(location, "^https://") then
                log("HTTP properly redirects to HTTPS")
            else
                table.insert(vulnerabilities, "http_redirect_not_https")
                log("Warning: HTTP redirect is not to HTTPS")
            end
        else
            table.insert(vulnerabilities, "http_no_redirect")
            log("Warning: HTTP does not redirect to HTTPS")
        end
    end
    
    -- Test 2: Check certificate with different SNI (if hostname differs from IP)
    if not string.match(host, "^%d+%.%d+%.%d+%.%d+$") then -- Not an IP address
        -- This is a hostname, test SNI behavior
        local sni_status, sni_body, sni_headers, sni_err = http.get(
            "https://" .. host .. ":" .. port,
            {["Host"] = host}, 8
        )
        
        if sni_err then
            table.insert(vulnerabilities, "sni_mismatch")
            log("Warning: Potential SNI certificate mismatch")
        end
    end
    
    return vulnerabilities
end

-- Perform certificate validation
local cert_ok, cert_err, cert_info = validate_certificate(host, port)

if not cert_ok then
    log("Certificate validation failed: " .. tostring(cert_err))
    set_metadata("certificate.valid", false)
    set_metadata("certificate.error", cert_err)
    
    -- Determine failure reason for better compliance reporting
    local failure_reason = "Certificate validation failed"
    if string.match(tostring(cert_err), "certificate") then
        failure_reason = "Invalid or expired certificate"
    elseif string.match(tostring(cert_err), "hostname") then
        failure_reason = "Certificate hostname mismatch"
    elseif string.match(tostring(cert_err), "authority") then
        failure_reason = "Certificate authority not trusted"
    end
    
    fail_checklist("ssl-certificate-validation-012", failure_reason .. ": " .. tostring(cert_err))
    fail_checklist("cryptographic-controls-017", "Certificate validation failed")
    
    reject("Certificate validation failed")
    return
end

-- Certificate is valid - analyze security
log("Certificate validation successful")
set_metadata("certificate.valid", true)
set_metadata("certificate.hostname", cert_info.hostname)
set_metadata("certificate.port", cert_info.port)

-- Analyze certificate security
local security_score, security_issues = analyze_certificate_security(cert_info)
set_metadata("certificate.security_score", security_score)

if #security_issues > 0 then
    set_metadata("certificate.security_issues", table.concat(security_issues, "; "))
end

-- Test for certificate vulnerabilities
local vulnerabilities = test_certificate_vulnerabilities(host, port)
local vulnerability_count = #vulnerabilities

if vulnerability_count > 0 then
    set_metadata("certificate.vulnerabilities", table.concat(vulnerabilities, "; "))
    set_metadata("certificate.vulnerability_count", vulnerability_count)
end

-- Set HSTS metadata
if cert_info.hsts_present then
    set_metadata("certificate.hsts_enabled", true)
    set_metadata("certificate.hsts_value", cert_info.hsts_value)
    if cert_info.hsts_max_age then
        set_metadata("certificate.hsts_max_age", cert_info.hsts_max_age)
    end
else
    set_metadata("certificate.hsts_enabled", false)
end

-- Determine compliance level
local max_security_score = 9 -- 3 + 2 + 2 + 1 + 1
local compliance_percentage = math.floor((security_score / max_security_score) * 100)
set_metadata("certificate.compliance_percentage", compliance_percentage)

log("Certificate security score: " .. security_score .. "/" .. max_security_score .. " (" .. compliance_percentage .. "%)")

-- Evaluate against Moldovan Cybersecurity Law requirements
local compliance_status = "fail"
local compliance_level = "insufficient"

if security_score >= 7 and vulnerability_count == 0 then
    compliance_status = "pass"
    compliance_level = "excellent"
    log("Excellent certificate configuration")
    
elseif security_score >= 5 and vulnerability_count <= 1 then
    compliance_status = "pass"
    compliance_level = "good"
    log("Good certificate configuration")
    
elseif security_score >= 3 and vulnerability_count <= 2 then
    compliance_status = "conditional"
    compliance_level = "acceptable"
    log("Acceptable certificate configuration with minor issues")
    
else
    compliance_status = "fail"
    compliance_level = "insufficient"
    log("Insufficient certificate security")
end

set_metadata("certificate.compliance_status", compliance_status)
set_metadata("certificate.compliance_level", compliance_level)

-- Update compliance checklists
if compliance_status == "pass" then
    local pass_message = compliance_level:gsub("^%l", string.upper) .. " certificate configuration"
    pass_message = pass_message .. " (score: " .. security_score .. "/" .. max_security_score .. ")"
    
    pass_checklist("ssl-certificate-validation-012", pass_message)
    pass_checklist("cryptographic-controls-017", "Certificate validation passed")
    
    log("Certificate compliance: PASS - " .. compliance_level)
    pass()
    
elseif compliance_status == "conditional" then
    local conditional_message = "Certificate acceptable but has issues: " .. table.concat(security_issues, "; ")
    if vulnerability_count > 0 then
        conditional_message = conditional_message .. "; Vulnerabilities: " .. table.concat(vulnerabilities, "; ")
    end
    
    pass_checklist("ssl-certificate-validation-012", conditional_message)
    fail_checklist("cryptographic-controls-017", "Certificate has security issues")
    
    log("Certificate compliance: CONDITIONAL - " .. conditional_message)
    pass()
    
else
    local fail_message = "Insufficient certificate security"
    if #security_issues > 0 then
        fail_message = fail_message .. ": " .. table.concat(security_issues, "; ")
    end
    if vulnerability_count > 0 then
        fail_message = fail_message .. "; Vulnerabilities: " .. table.concat(vulnerabilities, "; ")
    end
    fail_message = fail_message .. " (score: " .. security_score .. "/" .. max_security_score .. ")"
    
    fail_checklist("ssl-certificate-validation-012", fail_message)
    fail_checklist("cryptographic-controls-017", "Certificate validation failed")
    
    log("Certificate compliance: FAIL - " .. fail_message)
    reject("Certificate security insufficient")
end

-- Add descriptive tags
if compliance_level == "excellent" then
    add_tag("excellent-certificate")
elseif compliance_level == "good" then
    add_tag("good-certificate")
elseif compliance_level == "acceptable" then
    add_tag("acceptable-certificate")
else
    add_tag("weak-certificate")
end

if cert_info.hsts_present then
    add_tag("hsts-enabled")
end

if cert_info.public_key_pinning then
    add_tag("certificate-pinning")
end

if cert_info.certificate_transparency then
    add_tag("certificate-transparency")
end

if vulnerability_count > 0 then
    add_tag("certificate-vulnerabilities")
end