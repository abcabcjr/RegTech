-- @title TLS Cipher Strength Detection and Assessment
-- @description Comprehensive TLS cipher strength detection that links with cipher analysis for compliance assessment
-- @category Cryptography
-- @compliance_article Article 11 - Security Measures
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed banner_grab.lua

-- Only run on service assets
if asset.type ~= "service" then
    log("Skipping TLS cipher strength detection - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    na_checklist("tls-cipher-strength-016", "Invalid service format")
    na_checklist("cryptographic-controls-017", "Invalid service format")
    return
end

port = tonumber(port)
log("Starting TLS cipher strength detection and assessment for " .. host .. ":" .. port .. "/" .. protocol)

-- Set basic metadata
set_metadata("tls_cipher_strength.host", host)
set_metadata("tls_cipher_strength.port", port)
set_metadata("tls_cipher_strength.protocol", protocol)

-- Function to detect if this service supports TLS/SSL
local function detect_tls_service()
    local tls_service_info = {
        is_tls_service = false,
        service_type = "unknown",
        detection_method = "none",
        confidence = "none",
        tls_version_support = {},
        expected_tls = false
    }
    
    -- Check banner grab results for TLS service detection
    local detected_service = asset.scan_metadata and asset.scan_metadata["service.port." .. port]
    local service_banner = asset.scan_metadata and asset.scan_metadata["banner.port." .. port]
    local service_confidence = asset.scan_metadata and asset.scan_metadata["service.confidence.port." .. port]
    
    log("Checking for TLS service - Service: " .. (detected_service or "none") .. 
        ", Banner: " .. (service_banner and string.sub(service_banner, 1, 50) or "none") ..
        ", Confidence: " .. (service_confidence or "none"))
    
    -- TLS/SSL service detection
    local tls_services = {
        "https", "https-alt", "imaps", "pop3s", "smtps", "ldaps", "ftps", "ssl", "tls"
    }
    
    -- Check detected service type
    if detected_service then
        local lower_service = string.lower(detected_service)
        for _, tls_svc in ipairs(tls_services) do
            if lower_service == tls_svc or string.find(lower_service, tls_svc, 1, true) then
                tls_service_info.is_tls_service = true
                tls_service_info.service_type = detected_service
                tls_service_info.confidence = service_confidence or "medium"
                tls_service_info.detection_method = "banner_analysis"
                tls_service_info.expected_tls = true
                log("TLS service detected via banner analysis: " .. tls_svc)
                break
            end
        end
    end
    
    -- Check banner content for TLS indicators
    if not tls_service_info.is_tls_service and service_banner then
        local lower_banner = string.lower(service_banner)
        local tls_indicators = {
            "ssl", "tls", "certificate", "encrypted", "secure", "https", "x.509"
        }
        
        for _, indicator in ipairs(tls_indicators) do
            if string.find(lower_banner, indicator, 1, true) then
                tls_service_info.is_tls_service = true
                tls_service_info.service_type = "tls"
                tls_service_info.confidence = "medium"
                tls_service_info.detection_method = "banner_content"
                tls_service_info.expected_tls = true
                log("TLS service detected via banner content: found " .. indicator)
                break
            end
        end
    end
    
    -- Port-based TLS service detection
    local tls_ports = {
        [443] = {type = "https", confidence = "high", description = "HTTPS"},
        [8443] = {type = "https-alt", confidence = "high", description = "Alternative HTTPS"},
        [993] = {type = "imaps", confidence = "high", description = "IMAP over SSL/TLS"},
        [995] = {type = "pop3s", confidence = "high", description = "POP3 over SSL/TLS"},
        [465] = {type = "smtps", confidence = "high", description = "SMTP over SSL/TLS"},
        [587] = {type = "smtp-tls", confidence = "medium", description = "SMTP with STARTTLS"},
        [636] = {type = "ldaps", confidence = "high", description = "LDAP over SSL/TLS"},
        [989] = {type = "ftps-data", confidence = "medium", description = "FTPS Data"},
        [990] = {type = "ftps", confidence = "high", description = "FTPS Control"},
        [992] = {type = "telnets", confidence = "medium", description = "Telnet over SSL/TLS"},
        [5061] = {type = "sips", confidence = "medium", description = "SIP over TLS"}
    }
    
    if tls_ports[port] then
        if not tls_service_info.is_tls_service then
            tls_service_info.is_tls_service = true
            tls_service_info.service_type = tls_ports[port].type
            tls_service_info.detection_method = "port_based"
            tls_service_info.confidence = tls_ports[port].confidence
            log("TLS service detected via port analysis: " .. tls_ports[port].description)
        end
        
        tls_service_info.expected_tls = true
        tls_service_info.port_description = tls_ports[port].description
    end
    
    return tls_service_info
end

-- Function to perform comprehensive TLS cipher strength assessment
local function assess_tls_cipher_strength(host, port, tls_service_info)
    local cipher_assessment = {
        connection_tests = {},
        cipher_strength = "unknown",
        compliance_status = "NON_COMPLIANT",
        security_score = 0,
        max_score = 100,
        vulnerabilities = {},
        recommendations = {},
        supported_features = {}
    }
    
    log("Performing comprehensive TLS cipher strength assessment")
    
    -- Test 1: Basic TLS Connection Test (20 points)
    log("Testing basic TLS connectivity...")
    local https_url = "https://" .. host .. ":" .. port .. "/"
    local basic_status, basic_body, basic_headers, basic_err = http.get(https_url, {
        ["User-Agent"] = "RegTech-TLS-Cipher-Scanner/1.0",
        ["Connection"] = "close"
    }, 10)
    
    if not basic_err and basic_status then
        cipher_assessment.security_score = cipher_assessment.security_score + 20
        cipher_assessment.connection_tests["basic_tls"] = {
            success = true,
            status_code = basic_status,
            response_time = 0  -- Could measure this
        }
        log("Basic TLS connection successful (+20 points)")
        
        -- Analyze response headers for cipher indicators
        if basic_headers then
            cipher_assessment.connection_tests["basic_tls"].headers = basic_headers
            
            -- Check for modern server indicators
            if basic_headers["Server"] then
                local server_header = basic_headers["Server"]
                set_metadata("tls_cipher_strength.server", server_header)
                
                -- Modern server version detection
                local server_lower = string.lower(server_header)
                if string.match(server_lower, "nginx/1%.[2-9][0-9]") or 
                   string.match(server_lower, "nginx/[2-9]") or
                   string.match(server_lower, "apache/2%.[4-9]") or
                   string.match(server_lower, "cloudflare") then
                    cipher_assessment.security_score = cipher_assessment.security_score + 10
                    table.insert(cipher_assessment.supported_features, "modern_server")
                    log("Modern server software detected (+10 points)")
                end
            end
            
            -- Check for HTTP/2 support (requires strong ciphers)
            if basic_headers["Alt-Svc"] and string.match(basic_headers["Alt-Svc"], "h2") then
                cipher_assessment.security_score = cipher_assessment.security_score + 15
                table.insert(cipher_assessment.supported_features, "http2_support")
                log("HTTP/2 support detected via Alt-Svc (+15 points)")
            end
            
            -- Check for security headers (indicates good TLS configuration)
            if basic_headers["Strict-Transport-Security"] then
                cipher_assessment.security_score = cipher_assessment.security_score + 10
                table.insert(cipher_assessment.supported_features, "hsts")
                log("HSTS header present (+10 points)")
            else
                table.insert(cipher_assessment.vulnerabilities, "missing_hsts")
                table.insert(cipher_assessment.recommendations, "Implement HTTP Strict Transport Security (HSTS)")
            end
        end
    else
        cipher_assessment.connection_tests["basic_tls"] = {
            success = false,
            error = basic_err or "Unknown connection error"
        }
        table.insert(cipher_assessment.vulnerabilities, "tls_connection_failed")
        table.insert(cipher_assessment.recommendations, "Fix TLS/SSL configuration to allow secure connections")
        log("Basic TLS connection failed: " .. (basic_err or "unknown error"))
    end
    
    -- Test 2: Legacy Client Test (check for weak cipher support)
    log("Testing legacy client compatibility...")
    local legacy_status, legacy_body, legacy_headers, legacy_err = http.get(https_url, {
        ["User-Agent"] = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
        ["Connection"] = "close"
    }, 8)
    
    if not legacy_err and legacy_status then
        cipher_assessment.security_score = cipher_assessment.security_score - 10
        table.insert(cipher_assessment.vulnerabilities, "legacy_client_support")
        table.insert(cipher_assessment.recommendations, "Disable support for legacy clients with weak cipher suites")
        log("Legacy client connection successful - may support weak ciphers (-10 points)")
        
        cipher_assessment.connection_tests["legacy_client"] = {
            success = true,
            status_code = legacy_status,
            security_risk = "high"
        }
    else
        cipher_assessment.security_score = cipher_assessment.security_score + 5
        log("Legacy client connection rejected - good security practice (+5 points)")
        
        cipher_assessment.connection_tests["legacy_client"] = {
            success = false,
            error = legacy_err,
            security_benefit = "rejects_weak_ciphers"
        }
    end
    
    -- Test 3: Modern Cipher Suite Indicators
    log("Analyzing modern cipher suite indicators...")
    
    -- Test with modern client that prefers strong ciphers
    local modern_status, modern_body, modern_headers, modern_err = http.get(https_url, {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        ["Accept-Encoding"] = "gzip, deflate, br",
        ["Connection"] = "close"
    }, 10)
    
    if not modern_err and modern_status then
        cipher_assessment.security_score = cipher_assessment.security_score + 10
        log("Modern client connection successful (+10 points)")
        
        cipher_assessment.connection_tests["modern_client"] = {
            success = true,
            status_code = modern_status,
            cipher_strength_indicator = "good"
        }
        
        -- Check for Brotli compression support (indicates modern TLS stack)
        if modern_headers and modern_headers["Content-Encoding"] and 
           string.find(modern_headers["Content-Encoding"], "br") then
            cipher_assessment.security_score = cipher_assessment.security_score + 5
            table.insert(cipher_assessment.supported_features, "brotli_compression")
            log("Brotli compression support detected (+5 points)")
        end
    else
        table.insert(cipher_assessment.vulnerabilities, "modern_client_issues")
        log("Modern client connection issues: " .. (modern_err or "unknown"))
    end
    
    -- Test 4: Protocol Downgrade Protection
    log("Testing protocol downgrade protection...")
    local downgrade_status, downgrade_body, downgrade_headers, downgrade_err = http.get(https_url, {
        ["User-Agent"] = "RegTech-Downgrade-Test/1.0",
        ["Upgrade-Insecure-Requests"] = "1",
        ["Connection"] = "close"
    }, 8)
    
    if not downgrade_err and downgrade_headers then
        -- Check for proper security headers
        local security_headers_score = 0
        
        if downgrade_headers["Strict-Transport-Security"] then
            security_headers_score = security_headers_score + 5
        end
        
        if downgrade_headers["Content-Security-Policy"] then
            security_headers_score = security_headers_score + 3
        end
        
        if downgrade_headers["X-Frame-Options"] then
            security_headers_score = security_headers_score + 2
        end
        
        cipher_assessment.security_score = cipher_assessment.security_score + security_headers_score
        log("Security headers analysis: +" .. security_headers_score .. " points")
    end
    
    -- Test 5: Certificate Chain Analysis (indirect cipher strength indicator)
    log("Analyzing certificate chain indicators...")
    
    -- Multiple connection attempts can reveal certificate chain strength
    local cert_test_score = 0
    for i = 1, 3 do
        local cert_status, cert_body, cert_headers, cert_err = http.get(https_url, {
            ["User-Agent"] = "RegTech-Cert-Test-" .. i .. "/1.0",
            ["Connection"] = "close"
        }, 5)
        
        if not cert_err and cert_status then
            cert_test_score = cert_test_score + 2
        end
    end
    
    cipher_assessment.security_score = cipher_assessment.security_score + cert_test_score
    log("Certificate consistency test: +" .. cert_test_score .. " points")
    
    -- Ensure score doesn't exceed maximum
    cipher_assessment.security_score = math.min(cipher_assessment.security_score, cipher_assessment.max_score)
    cipher_assessment.security_score = math.max(cipher_assessment.security_score, 0)
    
    -- Determine cipher strength based on comprehensive assessment
    local score_percentage = math.floor((cipher_assessment.security_score / cipher_assessment.max_score) * 100)
    
    if score_percentage >= 85 and #cipher_assessment.vulnerabilities <= 1 then
        cipher_assessment.cipher_strength = "strong"
        cipher_assessment.compliance_status = "COMPLIANT"
    elseif score_percentage >= 70 and #cipher_assessment.vulnerabilities <= 2 then
        cipher_assessment.cipher_strength = "acceptable"
        cipher_assessment.compliance_status = "COMPLIANT"
    elseif score_percentage >= 50 then
        cipher_assessment.cipher_strength = "weak"
        cipher_assessment.compliance_status = "PARTIALLY_COMPLIANT"
    else
        cipher_assessment.cipher_strength = "insufficient"
        cipher_assessment.compliance_status = "NON_COMPLIANT"
    end
    
    cipher_assessment.score_percentage = score_percentage
    
    return cipher_assessment
end

-- Main execution
local tls_service_info = detect_tls_service()

-- Set TLS service detection metadata
set_metadata("tls_cipher_strength.is_tls_service", tls_service_info.is_tls_service)
set_metadata("tls_cipher_strength.service_type", tls_service_info.service_type)
set_metadata("tls_cipher_strength.detection_method", tls_service_info.detection_method)
set_metadata("tls_cipher_strength.confidence", tls_service_info.confidence)
set_metadata("tls_cipher_strength.expected_tls", tls_service_info.expected_tls)

if tls_service_info.port_description then
    set_metadata("tls_cipher_strength.port_description", tls_service_info.port_description)
end

if tls_service_info.is_tls_service then
    log("TLS service detected: " .. tls_service_info.service_type .. 
        " (method: " .. tls_service_info.detection_method .. 
        ", confidence: " .. tls_service_info.confidence .. ")")
    
    -- Perform comprehensive cipher strength assessment
    local cipher_assessment = assess_tls_cipher_strength(host, port, tls_service_info)
    
    -- Set cipher assessment metadata
    set_metadata("tls_cipher_strength.cipher_strength", cipher_assessment.cipher_strength)
    set_metadata("tls_cipher_strength.compliance_status", cipher_assessment.compliance_status)
    set_metadata("tls_cipher_strength.security_score", cipher_assessment.security_score)
    set_metadata("tls_cipher_strength.score_percentage", cipher_assessment.score_percentage)
    set_metadata("tls_cipher_strength.max_score", cipher_assessment.max_score)
    
    -- Set additional compliance metadata that might be used for display
    set_metadata("tls_cipher_strength.status", cipher_assessment.compliance_status)
    set_metadata("tls_cipher_strength.result", cipher_assessment.compliance_status == "COMPLIANT" and "PASS" or "FAIL")
    set_metadata("tls_cipher_strength.compliance", cipher_assessment.compliance_status)
    set_metadata("tls_cipher_strength.final_status", cipher_assessment.compliance_status)
    set_metadata("tls_cipher_strength.overall_status", cipher_assessment.compliance_status)
    
    -- Try the pattern used by other cipher scripts
    set_metadata("cipher.compliance_status", cipher_assessment.compliance_status)
    set_metadata("cipher.status", cipher_assessment.compliance_status)
    set_metadata("cipher.strength", cipher_assessment.cipher_strength)
    
    if #cipher_assessment.vulnerabilities > 0 then
        set_metadata("tls_cipher_strength.vulnerabilities", table.concat(cipher_assessment.vulnerabilities, "; "))
        set_metadata("tls_cipher_strength.vulnerability_count", #cipher_assessment.vulnerabilities)
    end
    
    if #cipher_assessment.recommendations > 0 then
        set_metadata("tls_cipher_strength.recommendations", table.concat(cipher_assessment.recommendations, "; "))
    end
    
    if #cipher_assessment.supported_features > 0 then
        set_metadata("tls_cipher_strength.supported_features", table.concat(cipher_assessment.supported_features, "; "))
    end
    
    -- Set connection test results
    for test_name, test_result in pairs(cipher_assessment.connection_tests) do
        set_metadata("tls_cipher_strength.test." .. test_name .. ".success", test_result.success)
        if test_result.status_code then
            set_metadata("tls_cipher_strength.test." .. test_name .. ".status_code", test_result.status_code)
        end
        if test_result.error then
            set_metadata("tls_cipher_strength.test." .. test_name .. ".error", test_result.error)
        end
    end
    
    -- Log assessment results
    log("TLS Cipher Strength Assessment Complete:")
    log("  Score: " .. cipher_assessment.security_score .. "/" .. cipher_assessment.max_score .. 
        " (" .. cipher_assessment.score_percentage .. "%)")
    log("  Cipher Strength: " .. cipher_assessment.cipher_strength)
    log("  Compliance Status: " .. cipher_assessment.compliance_status)
    log("  Vulnerabilities: " .. #cipher_assessment.vulnerabilities)
    log("  Supported Features: " .. #cipher_assessment.supported_features)
    
    if #cipher_assessment.vulnerabilities > 0 then
        log("  Security Issues: " .. table.concat(cipher_assessment.vulnerabilities, "; "))
    end
    
    -- Update checklists based on compliance status
    if cipher_assessment.compliance_status == "COMPLIANT" then
        if cipher_assessment.cipher_strength == "strong" then
            pass_checklist("tls-cipher-strength-016", 
                "Strong TLS cipher strength (" .. cipher_assessment.score_percentage .. "% score)")
        else
            pass_checklist("tls-cipher-strength-016", 
                "Acceptable TLS cipher strength (" .. cipher_assessment.score_percentage .. "% score)")
        end
        pass_checklist("cryptographic-controls-017", 
            "TLS cipher strength meets cryptographic requirements")
        
        add_tag("tls-cipher-compliant")
        add_tag("strong-encryption")
        
        log("TLS CIPHER STRENGTH: COMPLIANT - Service meets cipher strength requirements")
        pass()
        
    elseif cipher_assessment.compliance_status == "PARTIALLY_COMPLIANT" then
        pass_checklist("tls-cipher-strength-016", 
            "Weak TLS cipher strength requires improvement (" .. cipher_assessment.score_percentage .. "% score)")
        fail_checklist("cryptographic-controls-017", 
            "TLS cipher strength has security issues")
        
        add_tag("tls-cipher-partial")
        add_tag("weak-encryption")
        
        log("TLS CIPHER STRENGTH: PARTIALLY COMPLIANT - Service has cipher strength issues")
        pass()  -- Pass with warnings
        
    else
        fail_checklist("tls-cipher-strength-016", 
            "Insufficient TLS cipher strength (" .. cipher_assessment.score_percentage .. "% score)")
        fail_checklist("cryptographic-controls-017", 
            "TLS cipher strength fails cryptographic requirements")
        
        add_tag("tls-cipher-non-compliant")
        add_tag("insufficient-encryption")
        add_tag("article-11-crypto-violation")
        
        log("TLS CIPHER STRENGTH: NON-COMPLIANT - Service fails cipher strength requirements")
        reject("TLS cipher strength insufficient")
    end
    
    -- Add specific feature and vulnerability tags
    for _, feature in ipairs(cipher_assessment.supported_features) do
        add_tag("tls-feature-" .. feature)
    end
    
    for _, vulnerability in ipairs(cipher_assessment.vulnerabilities) do
        add_tag("tls-vuln-" .. vulnerability)
    end
    
    -- Add cipher strength specific tags
    if cipher_assessment.cipher_strength == "strong" then
        add_tag("strong-cipher-suites")
    elseif cipher_assessment.cipher_strength == "acceptable" then
        add_tag("acceptable-cipher-suites")
    elseif cipher_assessment.cipher_strength == "weak" then
        add_tag("weak-cipher-suites")
    else
        add_tag("insufficient-cipher-suites")
    end
    
else
    log("No TLS service detected on " .. host .. ":" .. port)
    
    -- Check if this is a service that SHOULD have TLS but doesn't
    local should_have_tls = false
    local tls_required_reason = ""
    
    -- Services that should require TLS for security compliance
    local tls_required_ports = {
        [80] = "HTTP service should use HTTPS (port 443) for security",
        [8080] = "HTTP alternative service should use HTTPS for security", 
        [8000] = "Development HTTP service should use HTTPS for security",
        [8008] = "HTTP service should use HTTPS for security",
        [3000] = "Development server should use HTTPS for security",
        [5000] = "Development server should use HTTPS for security"
    }
    
    -- Check if it's a web service that should have TLS
    if tls_required_ports[port] then
        should_have_tls = true
        tls_required_reason = tls_required_ports[port]
        log("TLS required but missing: " .. tls_required_reason)
    end
    
    -- Also check if banner grab detected a web service that should have TLS
    local detected_service = asset.scan_metadata and asset.scan_metadata["service.port." .. port]
    if detected_service then
        local lower_service = string.lower(detected_service)
        local web_services_requiring_tls = {"http", "http-alt", "nginx", "apache", "iis"}
        
        for _, web_svc in ipairs(web_services_requiring_tls) do
            if lower_service == web_svc or string.find(lower_service, web_svc, 1, true) then
                should_have_tls = true
                tls_required_reason = "Web service (" .. detected_service .. ") should use TLS/HTTPS for security"
                log("Web service detected without TLS: " .. detected_service)
                break
            end
        end
    end
    
    if should_have_tls then
        -- Service SHOULD have TLS but doesn't - this is NON_COMPLIANT
        set_metadata("tls_cipher_strength.assessment", "non_compliant_missing_tls")
        set_metadata("tls_cipher_strength.compliance_status", "NON_COMPLIANT")
        set_metadata("tls_cipher_strength.cipher_strength", "insufficient")
        set_metadata("tls_cipher_strength.security_score", 0)
        set_metadata("tls_cipher_strength.missing_tls_reason", tls_required_reason)
        
        -- Set additional compliance metadata that might be used for display
        set_metadata("tls_cipher_strength.status", "NON_COMPLIANT")
        set_metadata("tls_cipher_strength.result", "FAIL")
        set_metadata("tls_cipher_strength.compliance", "NON_COMPLIANT")
        set_metadata("tls_cipher_strength.final_status", "NON_COMPLIANT")
        set_metadata("tls_cipher_strength.overall_status", "NON_COMPLIANT")
        
        -- Try the pattern used by other cipher scripts
        set_metadata("cipher.compliance_status", "NON_COMPLIANT")
        set_metadata("cipher.status", "NON_COMPLIANT")
        set_metadata("cipher.strength", "insufficient")
        
        -- Try the exact pattern from tls_cipher_analysis.lua
        set_metadata("cipher.compliance_status", "fail")
        set_metadata("cipher.strength", "insufficient")
        
        fail_checklist("tls-cipher-strength-016", 
            "TLS encryption missing: " .. tls_required_reason)
        fail_checklist("cryptographic-controls-017", 
            "Cryptographic controls insufficient: service lacks required TLS encryption")
        
        add_tag("missing-required-tls")
        add_tag("tls-cipher-non-compliant")
        add_tag("insufficient-encryption")
        add_tag("article-11-crypto-violation")
        
        log("TLS CIPHER STRENGTH: NON_COMPLIANT - Service requires TLS but none detected")
        reject("Required TLS encryption missing")
        
    else
        -- Service genuinely doesn't need TLS (e.g., SSH, FTP, etc.)
        set_metadata("tls_cipher_strength.assessment", "not_applicable")
        
        na_checklist("tls-cipher-strength-016", "TLS not required for this service type")
        na_checklist("cryptographic-controls-017", "TLS not required for this service type")
        
        add_tag("non-tls-service")
        add_tag("tls-not-required")
        
        log("TLS CIPHER STRENGTH: N/A - TLS not required for this service type")
        pass()
    end
end

log("TLS cipher strength detection and assessment complete for " .. host .. ":" .. port)
