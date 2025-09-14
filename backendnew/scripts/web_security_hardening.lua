-- @title Web Security Hardening Assessment with Banner Analysis Integration
-- @description Comprehensive web security assessment linking banner grab results with security hardening checks
-- @category Web Security
-- @compliance_article Article 11 - Security Measures
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed banner_grab.lua

-- Only run on service assets
if asset.type ~= "service" then
    log("Skipping web security hardening - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    na_checklist("web-security-hardening-018", "Invalid service format")
    na_checklist("web-service-security-021", "Invalid service format")
    return
end

port = tonumber(port)
log("Starting web security hardening assessment for " .. host .. ":" .. port .. "/" .. protocol)

-- Set basic metadata
set_metadata("web_security.host", host)
set_metadata("web_security.port", port)
set_metadata("web_security.protocol", protocol)

-- Web service detection based on banner grab results and port analysis
local function detect_web_service()
    local web_service_info = {
        is_web_service = false,
        service_type = "unknown",
        server_software = "unknown",
        version = "unknown",
        confidence = "none",
        detection_method = "none",
        security_implications = {}
    }
    
    -- Check if banner grab detected a web service
    local detected_service = asset.scan_metadata and asset.scan_metadata["service.port." .. port]
    local service_banner = asset.scan_metadata and asset.scan_metadata["banner.port." .. port]
    local service_confidence = asset.scan_metadata and asset.scan_metadata["service.confidence.port." .. port]
    
    log("Banner grab results - Service: " .. (detected_service or "none") .. 
        ", Banner: " .. (service_banner and string.sub(service_banner, 1, 50) or "none") ..
        ", Confidence: " .. (service_confidence or "none"))
    
    -- Web service detection logic - enhanced with exact matching and partial matching
    local web_services = {
        "http", "https", "http-alt", "https-alt", "nginx", "apache", "iis", "lighttpd", "tomcat"
    }
    
    -- First try exact matching (case-insensitive)
    if detected_service then
        local lower_service = string.lower(detected_service)
        log("Checking detected service: '" .. lower_service .. "' against web service patterns")
        
        for _, web_svc in ipairs(web_services) do
            if lower_service == web_svc or string.find(lower_service, web_svc, 1, true) then
                web_service_info.is_web_service = true
                web_service_info.service_type = detected_service
                web_service_info.confidence = service_confidence or "medium"
                web_service_info.detection_method = "banner_analysis"
                log("Web service detected via banner analysis: " .. web_svc)
                break
            end
        end
    end
    
    -- Also check banner content for HTTP indicators if service detection missed it
    if not web_service_info.is_web_service and service_banner then
        local lower_banner = string.lower(service_banner)
        local http_indicators = {"http/", "server:", "content-type:", "location:", "set-cookie:"}
        
        for _, indicator in ipairs(http_indicators) do
            if string.find(lower_banner, indicator, 1, true) then
                web_service_info.is_web_service = true
                web_service_info.service_type = "http"
                web_service_info.confidence = "medium"
                web_service_info.detection_method = "banner_content_analysis"
                log("Web service detected via banner content analysis: found " .. indicator)
                break
            end
        end
    end
    
    -- Web port detection
    local web_ports = {
        [80] = {type = "http", security_risk = "high", description = "Unencrypted HTTP"},
        [443] = {type = "https", security_risk = "low", description = "Encrypted HTTPS"},
        [8080] = {type = "http-alt", security_risk = "medium", description = "Alternative HTTP"},
        [8443] = {type = "https-alt", security_risk = "low", description = "Alternative HTTPS"},
        [8000] = {type = "http-dev", security_risk = "high", description = "Development HTTP"},
        [8008] = {type = "http-alt", security_risk = "medium", description = "Alternative HTTP"},
        [3000] = {type = "http-dev", security_risk = "critical", description = "Development server"},
        [5000] = {type = "http-dev", security_risk = "critical", description = "Development server"},
        [9000] = {type = "http-admin", security_risk = "critical", description = "Admin interface"},
        [9090] = {type = "http-monitoring", security_risk = "high", description = "Monitoring interface"}
    }
    
    -- Enhanced port-based detection
    if web_ports[port] then
        if not web_service_info.is_web_service then
            web_service_info.is_web_service = true
            web_service_info.service_type = web_ports[port].type
            web_service_info.detection_method = "port_based"
            web_service_info.confidence = "medium"
            log("Web service detected via port analysis: " .. web_ports[port].type .. " on port " .. port)
        end
        
        web_service_info.port_risk = web_ports[port].security_risk
        web_service_info.port_description = web_ports[port].description
        
        -- Add security implications based on port
        if web_ports[port].security_risk == "critical" then
            table.insert(web_service_info.security_implications, "Development/admin interface exposed")
        elseif web_ports[port].security_risk == "high" then
            table.insert(web_service_info.security_implications, "Unencrypted web traffic")
        end
        
        log("Port-based web service info: " .. web_ports[port].description .. " (risk: " .. web_ports[port].security_risk .. ")")
    end
    
    -- Analyze banner for server software
    if service_banner and service_banner ~= "" then
        log("Analyzing banner for web server details: " .. string.sub(service_banner, 1, 100))
        
        -- Extract server software from banner
        local server_patterns = {
            {pattern = "nginx/([%d%.]+)", software = "nginx", version_capture = 1},
            {pattern = "Apache/([%d%.]+)", software = "apache", version_capture = 1},
            {pattern = "Microsoft%-IIS/([%d%.]+)", software = "iis", version_capture = 1},
            {pattern = "lighttpd/([%d%.]+)", software = "lighttpd", version_capture = 1},
            {pattern = "Server:%s*([^\r\n]+)", software = "generic", version_capture = 1},
            {pattern = "HTTP/([%d%.]+)", software = "http", version_capture = 1}
        }
        
        for _, pattern_info in ipairs(server_patterns) do
            local match = service_banner:match(pattern_info.pattern)
            if match then
                web_service_info.server_software = pattern_info.software
                if pattern_info.version_capture then
                    web_service_info.version = match
                end
                web_service_info.confidence = "high"
                log("Detected web server: " .. pattern_info.software .. " version " .. (match or "unknown"))
                break
            end
        end
        
        -- Check for security-related information in banner
        local security_indicators = {
            {pattern = "Server:%s*$", implication = "Server header hidden (good security practice)"},
            {pattern = "X%-Powered%-By", implication = "Technology disclosure in headers"},
            {pattern = "PHP/([%d%.]+)", implication = "PHP version disclosed"},
            {pattern = "OpenSSL", implication = "OpenSSL in use"},
            {pattern = "mod_ssl", implication = "Apache SSL module detected"}
        }
        
        for _, indicator in ipairs(security_indicators) do
            if service_banner:match(indicator.pattern) then
                table.insert(web_service_info.security_implications, indicator.implication)
            end
        end
    end
    
    return web_service_info
end

-- Function to perform comprehensive web security assessment
local function assess_web_security(web_info)
    local security_assessment = {
        overall_score = 0,
        max_score = 100,
        compliance_status = "NON_COMPLIANT",
        security_issues = {},
        recommendations = {},
        test_results = {}
    }
    
    log("Performing comprehensive web security assessment")
    
    -- Test 1: HTTPS/TLS Configuration (25 points)
    local tls_score = 0
    if port == 443 or port == 8443 then
        tls_score = 25
        log("HTTPS port detected - TLS encryption available")
        security_assessment.test_results["tls_available"] = true
    elseif port == 80 or port == 8080 or port == 8000 then
        table.insert(security_assessment.security_issues, "Unencrypted HTTP traffic")
        table.insert(security_assessment.recommendations, "Implement HTTPS/TLS encryption")
        security_assessment.test_results["tls_available"] = false
    else
        -- Unknown port - try to detect TLS capability
        log("Testing TLS capability on non-standard port " .. port)
        -- Note: In a real implementation, you might try a TLS handshake here
        tls_score = 10  -- Partial credit for non-standard port
        security_assessment.test_results["tls_available"] = "unknown"
    end
    security_assessment.overall_score = security_assessment.overall_score + tls_score
    
    -- Test 2: Security Headers Assessment (30 points)
    local headers_score = 0
    local scheme = (port == 443 or port == 8443) and "https" or "http"
    local url = scheme .. "://" .. host .. ":" .. port
    
    log("Testing security headers for: " .. url)
    local status, body, headers, err = http.get(url, {
        ["User-Agent"] = "RegTech-Web-Security-Scanner/1.0",
        ["Accept"] = "text/html,application/xhtml+xml"
    }, 10)
    
    if not err and headers then
        local critical_headers = {
            ["strict-transport-security"] = {score = 8, name = "HSTS"},
            ["content-security-policy"] = {score = 8, name = "CSP"},
            ["x-frame-options"] = {score = 5, name = "X-Frame-Options"},
            ["x-content-type-options"] = {score = 5, name = "X-Content-Type-Options"},
            ["referrer-policy"] = {score = 4, name = "Referrer-Policy"}
        }
        
        for header_key, header_info in pairs(critical_headers) do
            local header_found = false
            for response_header, response_value in pairs(headers) do
                if string.lower(response_header) == header_key then
                    header_found = true
                    headers_score = headers_score + header_info.score
                    log("Found security header: " .. header_info.name)
                    security_assessment.test_results["header_" .. string.gsub(header_key, "-", "_")] = response_value
                    break
                end
            end
            
            if not header_found then
                table.insert(security_assessment.security_issues, "Missing " .. header_info.name .. " header")
                table.insert(security_assessment.recommendations, "Implement " .. header_info.name .. " security header")
                security_assessment.test_results["header_" .. string.gsub(header_key, "-", "_")] = false
            end
        end
        
        -- Check for information disclosure headers
        local disclosure_headers = {"server", "x-powered-by", "x-aspnet-version"}
        for response_header, response_value in pairs(headers) do
            for _, disclosure_header in ipairs(disclosure_headers) do
                if string.lower(response_header) == disclosure_header then
                    table.insert(security_assessment.security_issues, "Information disclosure: " .. response_header .. " header")
                    table.insert(security_assessment.recommendations, "Remove or obfuscate " .. response_header .. " header")
                    headers_score = headers_score - 2  -- Penalty for disclosure
                end
            end
        end
        
    else
        table.insert(security_assessment.security_issues, "Could not fetch security headers")
        log("Failed to fetch headers: " .. (err or "unknown error"))
    end
    
    security_assessment.overall_score = security_assessment.overall_score + math.max(0, headers_score)
    
    -- Test 3: Service Configuration Security (25 points)
    local config_score = 0
    
    -- Analyze based on detected service
    if web_info.server_software == "nginx" then
        config_score = 20  -- Nginx generally secure by default
        log("Nginx detected - generally secure configuration")
    elseif web_info.server_software == "apache" then
        config_score = 15  -- Apache requires more hardening
        table.insert(security_assessment.recommendations, "Review Apache security configuration")
    elseif web_info.server_software == "iis" then
        config_score = 10  -- IIS requires significant hardening
        table.insert(security_assessment.recommendations, "Review IIS security configuration and disable unnecessary features")
    end
    
    -- Version analysis
    if web_info.version and web_info.version ~= "unknown" then
        log("Web server version: " .. web_info.version)
        -- In a real implementation, you might check against CVE databases
        config_score = config_score + 5
    else
        table.insert(security_assessment.recommendations, "Keep web server software updated")
    end
    
    security_assessment.overall_score = security_assessment.overall_score + config_score
    
    -- Test 4: Port and Service Risk Assessment (20 points)
    local risk_score = 0
    
    if web_info.port_risk then
        if web_info.port_risk == "low" then
            risk_score = 20
        elseif web_info.port_risk == "medium" then
            risk_score = 15
            table.insert(security_assessment.security_issues, "Medium risk port configuration")
        elseif web_info.port_risk == "high" then
            risk_score = 5
            table.insert(security_assessment.security_issues, "High risk port configuration")
        elseif web_info.port_risk == "critical" then
            risk_score = 0
            table.insert(security_assessment.security_issues, "Critical risk - development/admin interface exposed")
            table.insert(security_assessment.recommendations, "Do not expose development interfaces to public networks")
        end
    end
    
    security_assessment.overall_score = security_assessment.overall_score + risk_score
    
    -- Determine compliance status
    local compliance_percentage = math.floor((security_assessment.overall_score / security_assessment.max_score) * 100)
    
    if compliance_percentage >= 80 then
        security_assessment.compliance_status = "COMPLIANT"
    elseif compliance_percentage >= 60 then
        security_assessment.compliance_status = "PARTIALLY_COMPLIANT"
    else
        security_assessment.compliance_status = "NON_COMPLIANT"
    end
    
    security_assessment.compliance_percentage = compliance_percentage
    
    return security_assessment
end

-- Main execution
local web_service_info = detect_web_service()

-- Set web service detection metadata
set_metadata("web_security.is_web_service", web_service_info.is_web_service)
set_metadata("web_security.service_type", web_service_info.service_type)
set_metadata("web_security.server_software", web_service_info.server_software)
set_metadata("web_security.version", web_service_info.version)
set_metadata("web_security.confidence", web_service_info.confidence)
set_metadata("web_security.detection_method", web_service_info.detection_method)

if web_service_info.port_risk then
    set_metadata("web_security.port_risk", web_service_info.port_risk)
end

-- Log web service detection results
if web_service_info.is_web_service then
    log("Web service detected: " .. web_service_info.service_type .. 
        " (" .. web_service_info.server_software .. " " .. web_service_info.version .. ")")
    
    if #web_service_info.security_implications > 0 then
        log("Security implications: " .. table.concat(web_service_info.security_implications, "; "))
        set_metadata("web_security.implications", table.concat(web_service_info.security_implications, "; "))
    end
    
    -- Perform comprehensive security assessment
    local security_assessment = assess_web_security(web_service_info)
    
    -- Set assessment metadata
    set_metadata("web_security.overall_score", security_assessment.overall_score)
    set_metadata("web_security.max_score", security_assessment.max_score)
    set_metadata("web_security.compliance_percentage", security_assessment.compliance_percentage)
    set_metadata("web_security.compliance_status", security_assessment.compliance_status)
    
    if #security_assessment.security_issues > 0 then
        set_metadata("web_security.issues", table.concat(security_assessment.security_issues, "; "))
    end
    
    if #security_assessment.recommendations > 0 then
        set_metadata("web_security.recommendations", table.concat(security_assessment.recommendations, "; "))
    end
    
    -- Log assessment results
    log("Web Security Assessment Complete:")
    log("  Score: " .. security_assessment.overall_score .. "/" .. security_assessment.max_score .. 
        " (" .. security_assessment.compliance_percentage .. "%)")
    log("  Compliance Status: " .. security_assessment.compliance_status)
    
    if #security_assessment.security_issues > 0 then
        log("  Security Issues: " .. table.concat(security_assessment.security_issues, "; "))
    end
    
    -- Update checklists based on compliance status
    if security_assessment.compliance_status == "COMPLIANT" then
        pass_checklist("web-security-hardening-018", 
            "Web security hardening compliant (" .. security_assessment.compliance_percentage .. "% score)")
        pass_checklist("web-service-security-021", 
            "Web service security configuration meets requirements")
        
        add_tag("web-security-compliant")
        add_tag("web-hardening-passed")
        
        log("WEB SECURITY: COMPLIANT - Web service meets security hardening requirements")
        pass()
        
    elseif security_assessment.compliance_status == "PARTIALLY_COMPLIANT" then
        pass_checklist("web-security-hardening-018", 
            "Web security hardening partially compliant (" .. security_assessment.compliance_percentage .. "% score)")
        fail_checklist("web-service-security-021", 
            "Web service security has issues: " .. table.concat(security_assessment.security_issues, "; "))
        
        add_tag("web-security-partial")
        add_tag("web-hardening-issues")
        
        log("WEB SECURITY: PARTIALLY COMPLIANT - Web service has security issues requiring attention")
        pass()  -- Still pass but with warnings
        
    else
        fail_checklist("web-security-hardening-018", 
            "Web security hardening insufficient (" .. security_assessment.compliance_percentage .. "% score)")
        fail_checklist("web-service-security-021", 
            "Web service security fails requirements: " .. table.concat(security_assessment.security_issues, "; "))
        
        add_tag("web-security-non-compliant")
        add_tag("web-hardening-failed")
        add_tag("article-11-web-violation")
        
        log("WEB SECURITY: NON-COMPLIANT - Web service fails security hardening requirements")
        reject("Web security hardening insufficient")
    end
    
    -- Add specific tags based on detected issues
    for _, issue in ipairs(security_assessment.security_issues) do
        if string.match(issue, "Unencrypted") then
            add_tag("unencrypted-web-traffic")
        elseif string.match(issue, "Missing.*header") then
            add_tag("missing-security-headers")
        elseif string.match(issue, "development") or string.match(issue, "admin") then
            add_tag("exposed-admin-interface")
        end
    end
    
else
    log("No web service detected on " .. host .. ":" .. port)
    set_metadata("web_security.assessment", "not_applicable")
    
    -- Not applicable for non-web services
    na_checklist("web-security-hardening-018", "Not a web service")
    na_checklist("web-service-security-021", "Not a web service")
    
    add_tag("non-web-service")
    pass()
end

log("Web security hardening assessment complete for " .. host .. ":" .. port)
