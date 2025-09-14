-- @title HTTP Headers Detection and Analysis
-- @description Comprehensive HTTP headers detection that links with security headers analysis for compliance assessment
-- @category Web Security
-- @compliance_article Article 11 - Security Measures
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed banner_grab.lua

-- Only run on service assets
if asset.type ~= "service" then
    log("Skipping HTTP headers detection - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    na_checklist("http-security-headers-013", "Invalid service format")
    na_checklist("web-security-hardening-018", "Invalid service format")
    return
end

port = tonumber(port)
log("Starting HTTP headers detection and analysis for " .. host .. ":" .. port .. "/" .. protocol)

-- Set basic metadata
set_metadata("http_headers.host", host)
set_metadata("http_headers.port", port)
set_metadata("http_headers.protocol", protocol)

-- Function to detect if this is a web service that should have HTTP headers
local function detect_http_service()
    local http_service_info = {
        is_http_service = false,
        service_type = "unknown",
        detection_method = "none",
        confidence = "none",
        supports_http = false,
        scheme = "http"
    }
    
    -- Check banner grab results for web service detection
    local detected_service = asset.scan_metadata and asset.scan_metadata["service.port." .. port]
    local service_banner = asset.scan_metadata and asset.scan_metadata["banner.port." .. port]
    local service_confidence = asset.scan_metadata and asset.scan_metadata["service.confidence.port." .. port]
    
    log("Checking for HTTP service - Service: " .. (detected_service or "none") .. 
        ", Banner: " .. (service_banner and string.sub(service_banner, 1, 50) or "none") ..
        ", Confidence: " .. (service_confidence or "none"))
    
    -- HTTP/HTTPS service detection
    local http_services = {
        "http", "https", "http-alt", "https-alt", "nginx", "apache", "iis", 
        "lighttpd", "tomcat", "jetty", "gunicorn", "unicorn"
    }
    
    -- Check detected service type
    if detected_service then
        local lower_service = string.lower(detected_service)
        for _, http_svc in ipairs(http_services) do
            if lower_service == http_svc or string.find(lower_service, http_svc, 1, true) then
                http_service_info.is_http_service = true
                http_service_info.service_type = detected_service
                http_service_info.confidence = service_confidence or "medium"
                http_service_info.detection_method = "banner_analysis"
                http_service_info.supports_http = true
                log("HTTP service detected via banner analysis: " .. http_svc)
                break
            end
        end
    end
    
    -- Check banner content for HTTP indicators
    if not http_service_info.is_http_service and service_banner then
        local lower_banner = string.lower(service_banner)
        local http_indicators = {
            "http/", "server:", "content-type:", "location:", "set-cookie:",
            "cache-control:", "expires:", "last-modified:", "etag:"
        }
        
        for _, indicator in ipairs(http_indicators) do
            if string.find(lower_banner, indicator, 1, true) then
                http_service_info.is_http_service = true
                http_service_info.service_type = "http"
                http_service_info.confidence = "high"
                http_service_info.detection_method = "banner_content"
                http_service_info.supports_http = true
                log("HTTP service detected via banner content: found " .. indicator)
                break
            end
        end
    end
    
    -- Port-based HTTP service detection
    local http_ports = {
        [80] = {scheme = "http", type = "http", confidence = "high"},
        [443] = {scheme = "https", type = "https", confidence = "high"},
        [8080] = {scheme = "http", type = "http-alt", confidence = "medium"},
        [8443] = {scheme = "https", type = "https-alt", confidence = "medium"},
        [8000] = {scheme = "http", type = "http-dev", confidence = "medium"},
        [8008] = {scheme = "http", type = "http-alt", confidence = "medium"},
        [3000] = {scheme = "http", type = "http-dev", confidence = "medium"},
        [5000] = {scheme = "http", type = "http-dev", confidence = "medium"},
        [9000] = {scheme = "http", type = "http-admin", confidence = "low"},
        [9090] = {scheme = "http", type = "http-monitoring", confidence = "low"}
    }
    
    if http_ports[port] then
        if not http_service_info.is_http_service then
            http_service_info.is_http_service = true
            http_service_info.service_type = http_ports[port].type
            http_service_info.detection_method = "port_based"
            http_service_info.confidence = http_ports[port].confidence
            log("HTTP service detected via port analysis: " .. http_ports[port].type)
        end
        
        http_service_info.supports_http = true
        http_service_info.scheme = http_ports[port].scheme
    end
    
    return http_service_info
end

-- Function to fetch and analyze HTTP headers
local function fetch_http_headers(host, port, scheme)
    local headers_info = {
        success = false,
        status_code = 0,
        headers = {},
        response_time = 0,
        error_message = nil,
        total_headers = 0,
        security_headers = 0,
        info_headers = 0,
        custom_headers = 0
    }
    
    local url = scheme .. "://" .. host .. ":" .. port .. "/"
    log("Fetching HTTP headers from: " .. url)
    
    local start_time = os.time()
    local status, body, headers, err = http.get(url, {
        ["User-Agent"] = "RegTech-HTTP-Headers-Scanner/1.0",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.5",
        ["Accept-Encoding"] = "gzip, deflate",
        ["Connection"] = "close"
    }, 15)
    
    headers_info.response_time = os.time() - start_time
    
    if err then
        log("Failed to fetch HTTP headers: " .. err)
        headers_info.error_message = err
        return headers_info
    end
    
    headers_info.success = true
    headers_info.status_code = status or 0
    headers_info.headers = headers or {}
    
    -- Count and categorize headers
    if headers then
        for header_name, header_value in pairs(headers) do
            headers_info.total_headers = headers_info.total_headers + 1
            
            local lower_header = string.lower(header_name)
            
            -- Security headers
            local security_header_patterns = {
                "strict-transport-security", "content-security-policy", "x-frame-options",
                "x-content-type-options", "referrer-policy", "permissions-policy",
                "x-xss-protection", "expect-ct", "public-key-pins"
            }
            
            for _, sec_pattern in ipairs(security_header_patterns) do
                if lower_header == sec_pattern then
                    headers_info.security_headers = headers_info.security_headers + 1
                    break
                end
            end
            
            -- Information headers
            local info_header_patterns = {
                "server", "x-powered-by", "x-aspnet-version", "x-generator",
                "x-drupal-cache", "x-varnish", "via"
            }
            
            for _, info_pattern in ipairs(info_header_patterns) do
                if lower_header == info_pattern then
                    headers_info.info_headers = headers_info.info_headers + 1
                    break
                end
            end
            
            -- Custom headers (starting with x-)
            if string.sub(lower_header, 1, 2) == "x-" then
                headers_info.custom_headers = headers_info.custom_headers + 1
            end
        end
    end
    
    log("HTTP headers fetched successfully: " .. headers_info.total_headers .. " total headers (" ..
        headers_info.security_headers .. " security, " .. headers_info.info_headers .. " info, " ..
        headers_info.custom_headers .. " custom)")
    
    return headers_info
end

-- Function to analyze HTTP headers for compliance
local function analyze_http_headers_compliance(headers_info, http_service_info)
    local compliance_analysis = {
        compliance_status = "NON_COMPLIANT",
        compliance_score = 0,
        max_score = 100,
        issues = {},
        recommendations = {},
        security_assessment = {},
        header_analysis = {}
    }
    
    if not headers_info.success then
        table.insert(compliance_analysis.issues, "Failed to fetch HTTP headers: " .. (headers_info.error_message or "unknown error"))
        table.insert(compliance_analysis.recommendations, "Ensure HTTP service is accessible and responding")
        return compliance_analysis
    end
    
    local headers = headers_info.headers
    compliance_analysis.compliance_score = 20  -- Base score for successful HTTP response
    
    -- Critical Security Headers Assessment (60 points total)
    local critical_headers = {
        ["strict-transport-security"] = {
            name = "HSTS",
            points = 15,
            required_for_https = true,
            description = "HTTP Strict Transport Security"
        },
        ["content-security-policy"] = {
            name = "CSP",
            points = 15,
            required_for_all = true,
            description = "Content Security Policy"
        },
        ["x-frame-options"] = {
            name = "X-Frame-Options",
            points = 10,
            required_for_all = true,
            description = "Clickjacking protection"
        },
        ["x-content-type-options"] = {
            name = "X-Content-Type-Options",
            points = 10,
            required_for_all = true,
            description = "MIME type sniffing protection"
        },
        ["referrer-policy"] = {
            name = "Referrer-Policy",
            points = 10,
            required_for_all = false,
            description = "Referrer information control"
        }
    }
    
    for header_key, header_config in pairs(critical_headers) do
        local header_found = false
        local header_value = nil
        
        -- Find header (case-insensitive)
        for response_header, response_value in pairs(headers) do
            if string.lower(response_header) == header_key then
                header_found = true
                header_value = response_value
                break
            end
        end
        
        if header_found then
            compliance_analysis.compliance_score = compliance_analysis.compliance_score + header_config.points
            compliance_analysis.header_analysis[header_key] = {
                present = true,
                value = header_value,
                points_awarded = header_config.points
            }
            log("Found security header: " .. header_config.name .. " = " .. header_value)
        else
            local is_required = header_config.required_for_all or 
                               (header_config.required_for_https and http_service_info.scheme == "https")
            
            if is_required then
                table.insert(compliance_analysis.issues, "Missing required security header: " .. header_config.name)
                table.insert(compliance_analysis.recommendations, "Implement " .. header_config.name .. " header")
            end
            
            compliance_analysis.header_analysis[header_key] = {
                present = false,
                required = is_required,
                points_lost = header_config.points
            }
            log("Missing security header: " .. header_config.name)
        end
    end
    
    -- Information Disclosure Assessment (10 points penalty)
    local disclosure_headers = {"server", "x-powered-by", "x-aspnet-version", "x-generator"}
    for response_header, response_value in pairs(headers) do
        for _, disclosure_header in ipairs(disclosure_headers) do
            if string.lower(response_header) == disclosure_header then
                compliance_analysis.compliance_score = compliance_analysis.compliance_score - 5
                table.insert(compliance_analysis.issues, "Information disclosure: " .. response_header .. " header reveals: " .. response_value)
                table.insert(compliance_analysis.recommendations, "Remove or obfuscate " .. response_header .. " header")
                log("Information disclosure detected: " .. response_header .. " = " .. response_value)
            end
        end
    end
    
    -- HTTPS Requirement Assessment (10 points)
    if http_service_info.scheme == "https" then
        compliance_analysis.compliance_score = compliance_analysis.compliance_score + 10
        log("HTTPS detected - bonus points awarded")
    else
        table.insert(compliance_analysis.issues, "Service uses unencrypted HTTP instead of HTTPS")
        table.insert(compliance_analysis.recommendations, "Implement HTTPS/TLS encryption")
        log("HTTP detected - security risk identified")
    end
    
    -- Ensure score doesn't exceed maximum
    compliance_analysis.compliance_score = math.min(compliance_analysis.compliance_score, compliance_analysis.max_score)
    compliance_analysis.compliance_score = math.max(compliance_analysis.compliance_score, 0)
    
    -- Determine compliance status
    local compliance_percentage = math.floor((compliance_analysis.compliance_score / compliance_analysis.max_score) * 100)
    
    if compliance_percentage >= 80 then
        compliance_analysis.compliance_status = "COMPLIANT"
    elseif compliance_percentage >= 60 then
        compliance_analysis.compliance_status = "PARTIALLY_COMPLIANT"
    else
        compliance_analysis.compliance_status = "NON_COMPLIANT"
    end
    
    compliance_analysis.compliance_percentage = compliance_percentage
    
    return compliance_analysis
end

-- Main execution
local http_service_info = detect_http_service()

-- Set HTTP service detection metadata
set_metadata("http_headers.is_http_service", http_service_info.is_http_service)
set_metadata("http_headers.service_type", http_service_info.service_type)
set_metadata("http_headers.detection_method", http_service_info.detection_method)
set_metadata("http_headers.confidence", http_service_info.confidence)
set_metadata("http_headers.supports_http", http_service_info.supports_http)
set_metadata("http_headers.scheme", http_service_info.scheme)

if http_service_info.is_http_service then
    log("HTTP service detected: " .. http_service_info.service_type .. 
        " (method: " .. http_service_info.detection_method .. 
        ", confidence: " .. http_service_info.confidence .. ")")
    
    -- Fetch HTTP headers
    local headers_info = fetch_http_headers(host, port, http_service_info.scheme)
    
    -- Set headers fetch metadata
    set_metadata("http_headers.fetch_success", headers_info.success)
    set_metadata("http_headers.status_code", headers_info.status_code)
    set_metadata("http_headers.response_time", headers_info.response_time)
    set_metadata("http_headers.total_headers", headers_info.total_headers)
    set_metadata("http_headers.security_headers_count", headers_info.security_headers)
    set_metadata("http_headers.info_headers_count", headers_info.info_headers)
    set_metadata("http_headers.custom_headers_count", headers_info.custom_headers)
    
    if headers_info.error_message then
        set_metadata("http_headers.error", headers_info.error_message)
    end
    
    -- Store individual headers as metadata
    if headers_info.headers then
        for header_name, header_value in pairs(headers_info.headers) do
            local safe_header_name = string.gsub(string.lower(header_name), "[^%w]", "_")
            set_metadata("http_headers.header." .. safe_header_name, header_value)
        end
    end
    
    -- Perform compliance analysis
    local compliance_analysis = analyze_http_headers_compliance(headers_info, http_service_info)
    
    -- Set compliance metadata
    set_metadata("http_headers.compliance_status", compliance_analysis.compliance_status)
    set_metadata("http_headers.compliance_score", compliance_analysis.compliance_score)
    set_metadata("http_headers.compliance_percentage", compliance_analysis.compliance_percentage)
    set_metadata("http_headers.max_score", compliance_analysis.max_score)
    
    if #compliance_analysis.issues > 0 then
        set_metadata("http_headers.issues", table.concat(compliance_analysis.issues, "; "))
    end
    
    if #compliance_analysis.recommendations > 0 then
        set_metadata("http_headers.recommendations", table.concat(compliance_analysis.recommendations, "; "))
    end
    
    -- Log compliance results
    log("HTTP Headers Compliance Analysis Complete:")
    log("  Score: " .. compliance_analysis.compliance_score .. "/" .. compliance_analysis.max_score .. 
        " (" .. compliance_analysis.compliance_percentage .. "%)")
    log("  Status: " .. compliance_analysis.compliance_status)
    log("  Headers Found: " .. headers_info.total_headers .. 
        " (Security: " .. headers_info.security_headers .. ", Info: " .. headers_info.info_headers .. ")")
    
    if #compliance_analysis.issues > 0 then
        log("  Issues: " .. table.concat(compliance_analysis.issues, "; "))
    end
    
    -- Update checklists based on compliance status
    if compliance_analysis.compliance_status == "COMPLIANT" then
        pass_checklist("http-security-headers-013", 
            "HTTP security headers compliant (" .. compliance_analysis.compliance_percentage .. "% score)")
        pass_checklist("web-security-hardening-018", 
            "HTTP headers meet security hardening requirements")
        
        add_tag("http-headers-compliant")
        add_tag("security-headers-configured")
        
        log("HTTP HEADERS: COMPLIANT - Service meets HTTP security header requirements")
        pass()
        
    elseif compliance_analysis.compliance_status == "PARTIALLY_COMPLIANT" then
        pass_checklist("http-security-headers-013", 
            "HTTP security headers partially compliant (" .. compliance_analysis.compliance_percentage .. "% score)")
        fail_checklist("web-security-hardening-018", 
            "HTTP headers have security issues requiring attention")
        
        add_tag("http-headers-partial")
        add_tag("security-headers-incomplete")
        
        log("HTTP HEADERS: PARTIALLY COMPLIANT - Service has header security issues")
        pass()  -- Pass with warnings
        
    else
        fail_checklist("http-security-headers-013", 
            "HTTP security headers insufficient (" .. compliance_analysis.compliance_percentage .. "% score)")
        fail_checklist("web-security-hardening-018", 
            "HTTP headers fail security hardening requirements")
        
        add_tag("http-headers-non-compliant")
        add_tag("missing-security-headers")
        add_tag("article-11-headers-violation")
        
        log("HTTP HEADERS: NON-COMPLIANT - Service fails HTTP security header requirements")
        reject("HTTP security headers insufficient")
    end
    
    -- Add specific issue tags
    for _, issue in ipairs(compliance_analysis.issues) do
        if string.match(issue, "Missing.*header") then
            add_tag("missing-critical-headers")
        elseif string.match(issue, "Information disclosure") then
            add_tag("information-disclosure")
        elseif string.match(issue, "unencrypted HTTP") then
            add_tag("unencrypted-http")
        end
    end
    
else
    log("No HTTP service detected on " .. host .. ":" .. port)
    set_metadata("http_headers.assessment", "not_applicable")
    
    -- Not applicable for non-HTTP services
    na_checklist("http-security-headers-013", "Not an HTTP service")
    na_checklist("web-security-hardening-018", "Not an HTTP service")
    
    add_tag("non-http-service")
    pass()
end

log("HTTP headers detection and analysis complete for " .. host .. ":" .. port)
