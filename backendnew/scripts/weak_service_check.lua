-- @title Weak Service Exposure Detector
-- @description Flag insecure services like FTP/Telnet/POP3/IMAP/SNMP v2c on internet exposure
-- @category security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed service_detector.lua
-- @moldovan_law Article 11 - Security Measures (Prohibition of insecure protocols on internet)

log("Starting weak service exposure check for: " .. asset.value)

-- Insecure services that violate Article 11 when exposed to internet
local insecure_services = {
    -- Critical violations - plaintext protocols
    [21] = {
        service = "ftp", 
        risk = "CRITICAL",
        reason = "FTP transmits credentials in plaintext",
        article_11_violation = true,
        recommendation = "Use SFTP (port 22) or FTPS (port 990) instead"
    },
    [23] = {
        service = "telnet",
        risk = "CRITICAL", 
        reason = "Telnet transmits all data including passwords in plaintext",
        article_11_violation = true,
        recommendation = "Use SSH (port 22) for secure remote access"
    },
    [110] = {
        service = "pop3",
        risk = "HIGH",
        reason = "POP3 authentication often transmitted in plaintext", 
        article_11_violation = true,
        recommendation = "Use POP3S (port 995) or IMAP over SSL/TLS"
    },
    [143] = {
        service = "imap",
        risk = "HIGH",
        reason = "IMAP authentication often transmitted in plaintext",
        article_11_violation = true, 
        recommendation = "Use IMAPS (port 993) for encrypted email access"
    },
    
    -- High-risk services - should not be internet-facing
    [161] = {
        service = "snmp",
        risk = "HIGH",
        reason = "SNMP v1/v2c uses community strings in plaintext",
        article_11_violation = true,
        recommendation = "Use SNMP v3 with encryption, or restrict to internal networks"
    },
    [1433] = {
        service = "mssql",
        risk = "CRITICAL",
        reason = "Database should not be exposed to internet",
        article_11_violation = true,
        recommendation = "Restrict database access to internal networks only"
    },
    [3306] = {
        service = "mysql", 
        risk = "CRITICAL",
        reason = "Database should not be exposed to internet",
        article_11_violation = true,
        recommendation = "Restrict database access to internal networks only"
    },
    [5432] = {
        service = "postgresql",
        risk = "CRITICAL",
        reason = "Database should not be exposed to internet", 
        article_11_violation = true,
        recommendation = "Restrict database access to internal networks only"
    },
    [6379] = {
        service = "redis",
        risk = "CRITICAL",
        reason = "Redis often has no authentication and should not be internet-facing",
        article_11_violation = true,
        recommendation = "Enable authentication and restrict to internal networks"
    },
    [27017] = {
        service = "mongodb",
        risk = "CRITICAL",
        reason = "Database should not be exposed to internet",
        article_11_violation = true, 
        recommendation = "Restrict database access to internal networks only"
    },
    [3389] = {
        service = "rdp",
        risk = "HIGH",
        reason = "RDP is frequent target of brute force attacks",
        article_11_violation = false,  -- Not strictly prohibited but high risk
        recommendation = "Use VPN or implement strong authentication (NLA, MFA)"
    },
    [5900] = {
        service = "vnc",
        risk = "HIGH", 
        reason = "VNC often has weak authentication",
        article_11_violation = false,
        recommendation = "Use encrypted VNC variants or restrict access"
    }
}

-- Services that should use encryption when internet-facing  
local unencrypted_web_services = {
    [80] = {
        service = "http",
        risk = "MEDIUM", 
        reason = "HTTP transmits data in plaintext",
        article_11_violation = false,  -- Allowed but should redirect to HTTPS
        recommendation = "Implement HTTPS and redirect HTTP traffic"
    },
    [8080] = {
        service = "http-alt",
        risk = "MEDIUM",
        reason = "Alternative HTTP port transmits data in plaintext", 
        article_11_violation = false,
        recommendation = "Implement HTTPS on port 8443 or 443"
    }
}

-- Function to check if an IP is public (simplified)
local function is_public_ip(ip)
    -- Simple check for common private ranges
    if string.match(ip, "^192%.168%.") or 
       string.match(ip, "^10%.") or
       string.match(ip, "^172%.1[6-9]%.") or
       string.match(ip, "^172%.2[0-9]%.") or
       string.match(ip, "^172%.3[0-1]%.") or
       string.match(ip, "^127%.") or
       string.match(ip, "^169%.254%.") then
        return false
    end
    return true
end

-- Function to test service connectivity and gather additional info
local function test_service_security(host, port, service_info)
    local security_details = {}
    
    -- Test basic connectivity
    local fd, err = tcp.connect(host, port, 5)
    if not fd then
        return nil, "Service not accessible"
    end
    
    -- Try to get banner for additional analysis
    local banner, recv_err = tcp.recv(fd, 512, 3)
    if banner and banner ~= "" then
        security_details.banner = string.sub(banner, 1, 100)  -- Limit banner size
        
        -- Analyze banner for security indicators
        if service_info.service == "ftp" then
            if string.match(banner:lower(), "welcome") or string.match(banner:lower(), "ftp") then
                security_details.confirmed_service = true
            end
            -- Check for anonymous FTP
            tcp.send(fd, "USER anonymous\r\n")
            local response = tcp.recv(fd, 256, 2)
            if response and string.match(response, "^331") then
                security_details.anonymous_allowed = true
            end
        elseif service_info.service == "telnet" then
            if string.match(banner:lower(), "login") or string.match(banner:lower(), "username") then
                security_details.confirmed_service = true
            end
        elseif service_info.service == "snmp" then
            -- SNMP detection would require UDP, simplified here
            security_details.confirmed_service = true
        end
    end
    
    tcp.close(fd)
    return security_details, nil
end

-- Main weak service detection function
local function detect_weak_services()
    local weak_services_found = {}
    local critical_violations = 0
    local high_risk_services = 0
    local total_violations = 0
    
    -- Determine target and scanning approach
    local target_host = asset.value
    local ports_to_check = {}
    
    if asset.type == "service" then
        -- Single service check
        local host, port_str = string.match(asset.value, "([^:]+):(%d+)")
        if host and port_str then
            target_host = host
            table.insert(ports_to_check, tonumber(port_str))
        end
    else
        -- Check all known insecure service ports
        for port, _ in pairs(insecure_services) do
            table.insert(ports_to_check, port)
        end
        -- Also check unencrypted web services
        for port, _ in pairs(unencrypted_web_services) do
            table.insert(ports_to_check, port)
        end
    end
    
    log("Checking " .. #ports_to_check .. " potentially insecure services on " .. target_host)
    
    -- Check if target is likely internet-facing
    local is_internet_facing = true
    if asset.type == "ip" then
        is_internet_facing = is_public_ip(asset.value)
    end
    
    if not is_internet_facing then
        log("Target appears to be on private network - Article 11 violations less critical")
    end
    
    -- Test each potentially insecure service
    for _, port in ipairs(ports_to_check) do
        local service_info = insecure_services[port] or unencrypted_web_services[port]
        if not service_info then
            goto continue
        end
        
        -- Test if port is open
        local fd, err = tcp.connect(target_host, port, 3)
        if not fd then
            goto continue  -- Port closed, skip
        end
        tcp.close(fd)
        
        log("INSECURE SERVICE DETECTED: " .. service_info.service .. " on port " .. port)
        
        -- Gather additional service details
        local security_details, test_err = test_service_security(target_host, port, service_info)
        
        -- Record the finding
        local finding = {
            port = port,
            service = service_info.service,
            risk = service_info.risk,
            reason = service_info.reason,
            recommendation = service_info.recommendation,
            article_11_violation = service_info.article_11_violation,
            internet_facing = is_internet_facing,
            details = security_details or {}
        }
        
        table.insert(weak_services_found, finding)
        
        -- Set individual service metadata
        set_metadata("insecure_service_" .. port .. "_type", service_info.service)
        set_metadata("insecure_service_" .. port .. "_risk", service_info.risk) 
        set_metadata("insecure_service_" .. port .. "_violation", service_info.article_11_violation)
        set_metadata("insecure_service_" .. port .. "_reason", service_info.reason)
        
        -- Add security-specific tags
        add_tag("insecure-service")
        add_tag("insecure-" .. service_info.service)
        
        if service_info.article_11_violation then
            total_violations = total_violations + 1
            add_tag("article-11-violation-" .. port)
            add_tag("article-11-protocol-violation")
        end
        
        if service_info.risk == "CRITICAL" then
            critical_violations = critical_violations + 1
            add_tag("critical-insecure-service")
        elseif service_info.risk == "HIGH" then
            high_risk_services = high_risk_services + 1
            add_tag("high-risk-insecure-service")
        end
        
        -- Specific service tags and additional checks
        if service_info.service == "ftp" and security_details and security_details.anonymous_allowed then
            add_tag("anonymous-ftp")
            add_tag("critical-exposure")
            log("CRITICAL: Anonymous FTP access enabled")
        end
        
        if is_internet_facing and service_info.article_11_violation then
            add_tag("internet-facing-violation")
            log("COMPLIANCE VIOLATION: " .. service_info.service .. " exposed on internet (Article 11)")
        end
        
        ::continue::
    end
    
    return weak_services_found, critical_violations, high_risk_services, total_violations
end

-- Execute weak service detection
local findings, critical, high_risk, violations = detect_weak_services()

-- Analyze and report results
if #findings == 0 then
    log("No insecure services detected")
    set_metadata("weak_services_result", "none_found")
    add_tag("no-insecure-services")
    pass_checklist("insecure-service-detection-023", "No insecure services detected - optimal security configuration")
    pass()
else
    log("SECURITY ALERT: " .. #findings .. " insecure service(s) detected")
    
    -- Set summary metadata
    set_metadata("weak_services_count", #findings)
    set_metadata("critical_violations_count", critical)
    set_metadata("high_risk_services_count", high_risk)
    set_metadata("article_11_violations_count", violations)
    
    -- Build findings summary
    local services_list = {}
    local violations_list = {}
    
    for _, finding in ipairs(findings) do
        table.insert(services_list, finding.service .. ":" .. finding.port)
        if finding.article_11_violation then
            table.insert(violations_list, finding.service .. ":" .. finding.port .. " (" .. finding.reason .. ")")
        end
    end
    
    set_metadata("insecure_services_list", table.concat(services_list, "; "))
    
    if #violations_list > 0 then
        set_metadata("article_11_violations_list", table.concat(violations_list, "; "))
    end
    
    -- Article 11 compliance assessment
    if violations > 0 then
        set_metadata("article_11_insecure_services_compliance", "non-compliant")
        add_tag("article-11-non-compliant") 
        add_tag("security-policy-violation")
        log("COMPLIANCE STATUS: NON-COMPLIANT - " .. violations .. " Article 11 violation(s)")
    else
        set_metadata("article_11_insecure_services_compliance", "compliant")
        add_tag("article-11-compliant")
        log("COMPLIANCE STATUS: COMPLIANT - No Article 11 violations found")
    end
    
    -- Risk-based decision and checklist integration
    if critical > 0 then
        add_tag("critical-security-risk")
        fail_checklist("insecure-service-detection-023", "Critical insecure services detected: " .. critical .. " critical services exposed")
        reject("Critical insecure services exposed: " .. critical .. " critical, " .. high_risk .. " high-risk")
    elseif violations > 0 then
        fail_checklist("insecure-service-detection-023", "Article 11 compliance violations: " .. violations .. " insecure protocol(s) exposed")
        reject("Article 11 compliance violations: " .. violations .. " insecure protocol(s) exposed")
    elseif high_risk > 0 then
        add_tag("security-review-needed")
        fail_checklist("insecure-service-detection-023", "High-risk insecure services detected requiring immediate review")
        reject("High-risk services detected requiring security review")
    else
        pass_checklist("insecure-service-detection-023", "Service security validation passed - no insecure protocols detected")
        pass()
    end
    
    -- Log detailed recommendations
    log("Remediation recommendations:")
    for _, finding in ipairs(findings) do
        log("- " .. finding.service .. ":" .. finding.port .. " - " .. finding.recommendation)
    end
end

log("Weak service exposure check complete for " .. asset.value)