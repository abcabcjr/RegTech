-- @title Service Detection and Banner Grabbing
-- @description Banner grab + lightweight protocol identification for discovered services
-- @category network  
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed port_scan.lua
-- @moldovan_law Article 11 - Security Measures (Service identification and risk assessment)

log("Starting service detection for: " .. asset.value)

-- Service detection patterns
local service_patterns = {
    -- Web services
    ["HTTP/1"] = "http",
    ["Server:"] = "http",
    ["Content-Type:"] = "http",
    ["nginx"] = "http",
    ["Apache"] = "http",
    ["IIS"] = "http",
    ["Jetty"] = "http",
    ["Tomcat"] = "http",
    
    -- SSH
    ["SSH-"] = "ssh",
    ["OpenSSH"] = "ssh",
    ["Dropbear"] = "ssh",
    
    -- FTP
    ["220 "] = "ftp",
    ["FTP server"] = "ftp",
    ["vsftpd"] = "ftp",
    ["Pure-FTPd"] = "ftp",
    ["ProFTPD"] = "ftp",
    
    -- SMTP  
    ["220.*SMTP"] = "smtp",
    ["220.*mail"] = "smtp",
    ["220.*ESMTP"] = "smtp",
    ["Postfix"] = "smtp",
    ["Sendmail"] = "smtp",
    ["Exchange"] = "smtp",
    
    -- DNS
    ["BIND"] = "dns",
    
    -- Databases
    ["MySQL"] = "mysql", 
    ["PostgreSQL"] = "postgresql",
    ["Microsoft SQL Server"] = "mssql",
    ["Oracle"] = "oracle",
    ["Redis"] = "redis",
    ["MongoDB"] = "mongodb",
    
    -- Other services
    ["Microsoft Terminal Services"] = "rdp",
    ["VNC"] = "vnc",
    ["Telnet"] = "telnet",
    ["POP3"] = "pop3",
    ["IMAP"] = "imap"
}

-- Version extraction patterns
local version_patterns = {
    ["OpenSSH_([%d%.]+)"] = "openssh",
    ["nginx/([%d%.]+)"] = "nginx", 
    ["Apache/([%d%.]+)"] = "apache",
    ["Microsoft%-IIS/([%d%.]+)"] = "iis",
    ["vsftpd ([%d%.]+)"] = "vsftpd",
    ["MySQL ([%d%.%-]+)"] = "mysql",
    ["PostgreSQL ([%d%.]+)"] = "postgresql",
    ["Redis server v=([%d%.]+)"] = "redis"
}

-- Banner grabbing function  
local function grab_banner(host, port, timeout)
    timeout = timeout or 5
    
    local fd, err = tcp.connect(host, port, timeout)
    if not fd then
        return nil, "Connection failed: " .. (err or "unknown error")
    end
    
    -- Try to receive initial banner
    local banner, recv_err = tcp.recv(fd, 1024, 3)
    if not banner or banner == "" then
        -- Some services need a probe first
        local probes = {
            "GET / HTTP/1.0\r\n\r\n",  -- HTTP probe
            "\r\n",                    -- Generic probe
            "HELP\r\n",               -- Generic help command
            "QUIT\r\n"                -- Generic quit
        }
        
        for _, probe in ipairs(probes) do
            tcp.send(fd, probe)
            banner, recv_err = tcp.recv(fd, 1024, 2)
            if banner and banner ~= "" then
                break
            end
        end
    end
    
    tcp.close(fd)
    
    if banner and banner ~= "" then
        -- Clean up banner (remove control characters, limit length)
        banner = string.gsub(banner, "[%c]", " ")  -- Replace control chars with spaces
        banner = string.gsub(banner, "%s+", " ")   -- Collapse multiple spaces
        banner = string.sub(banner, 1, 200)       -- Limit length
        return string.match(banner, "^%s*(.-)%s*$"), nil  -- Trim whitespace
    end
    
    return nil, recv_err or "No banner received"
end

-- Service identification function
local function identify_service(banner, port)
    if not banner then
        return "unknown", nil, nil
    end
    
    local detected_service = "unknown"
    local detected_version = nil
    local software_name = nil
    
    -- Check against service patterns
    for pattern, service in pairs(service_patterns) do
        if string.match(banner:lower(), pattern:lower()) then
            detected_service = service
            break
        end
    end
    
    -- Extract version information  
    for pattern, software in pairs(version_patterns) do
        local version = string.match(banner, pattern)
        if version then
            detected_version = version
            software_name = software
            break
        end
    end
    
    -- Port-based fallback if no banner match
    if detected_service == "unknown" then
        local port_services = {
            [21] = "ftp", [22] = "ssh", [23] = "telnet", [25] = "smtp",
            [53] = "dns", [80] = "http", [110] = "pop3", [143] = "imap", 
            [443] = "https", [993] = "imaps", [995] = "pop3s",
            [1433] = "mssql", [3306] = "mysql", [3389] = "rdp",
            [5432] = "postgresql", [6379] = "redis", [27017] = "mongodb"
        }
        detected_service = port_services[port] or "unknown"
    end
    
    return detected_service, detected_version, software_name
end

-- Risk assessment function
local function assess_service_risk(service, version, port)
    local risk_level = "LOW"
    local risk_reasons = {}
    
    -- High-risk services
    local high_risk_services = {
        ["telnet"] = "Unencrypted protocol",
        ["ftp"] = "Often unencrypted, anonymous access risk",
        ["pop3"] = "Often unencrypted authentication", 
        ["imap"] = "Often unencrypted authentication",
        ["rdp"] = "Remote access, brute force target",
        ["vnc"] = "Remote access, often weak authentication"
    }
    
    -- Critical risk services
    local critical_risk_services = {
        ["mysql"] = "Database exposed to internet",
        ["postgresql"] = "Database exposed to internet", 
        ["mssql"] = "Database exposed to internet",
        ["redis"] = "In-memory database, often no auth",
        ["mongodb"] = "Database exposed to internet"
    }
    
    -- Check service-based risks
    if critical_risk_services[service] then
        risk_level = "CRITICAL"
        table.insert(risk_reasons, critical_risk_services[service])
    elseif high_risk_services[service] then  
        risk_level = "HIGH"
        table.insert(risk_reasons, high_risk_services[service])
    end
    
    -- Version-based risk (simplified)
    if version then
        -- Flag very old versions as higher risk
        local major_version = string.match(version, "^(%d+)")
        if major_version then
            local ver_num = tonumber(major_version)
            if service == "openssh" and ver_num and ver_num < 7 then
                risk_level = "HIGH"
                table.insert(risk_reasons, "Outdated SSH version")
            elseif service == "apache" and ver_num and ver_num < 2 then
                risk_level = "HIGH" 
                table.insert(risk_reasons, "Outdated Apache version")
            end
        end
    end
    
    return risk_level, risk_reasons
end

-- Main detection logic
local function detect_services()
    local services_detected = 0
    local high_risk_services = 0
    local critical_risk_services = 0
    
    -- Check if we have a service asset or need to work with open ports
    -- For now, let's detect based on asset type and common ports if no prior scan data
    local ports_to_scan = {}
    
    -- Determine target host and ports
    local target_host = asset.value
    if asset.type == "service" then
        -- Extract host and port from service asset  
        local host, port_str = string.match(asset.value, "([^:]+):(%d+)")
        if host and port_str then
            target_host = host
            table.insert(ports_to_scan, tonumber(port_str))
        else
            log("Invalid service format: " .. asset.value)
            na()
            return
        end
    else
        -- Scan common ports for IP/domain assets
        ports_to_scan = {21, 22, 23, 25, 53, 80, 110, 143, 443, 993, 995, 3389, 1433, 3306, 5432}
    end
    
    log("Performing service detection on " .. #ports_to_scan .. " ports")
    
    -- Detect services on each port
    for _, port in ipairs(ports_to_scan) do
        -- First check if port is actually open
        local fd, err = tcp.connect(target_host, port, 2)
        if not fd then
            -- Port is closed, skip
            goto continue
        end
        tcp.close(fd)
        log("Detecting service on " .. target_host .. ":" .. port)
        
        local banner, banner_err = grab_banner(target_host, port, 5)
        local service, version, software = identify_service(banner, port)
        local risk_level, risk_reasons = assess_service_risk(service, version, port)
        
        services_detected = services_detected + 1
        
        -- Set metadata for this service
        set_metadata("service_" .. port .. "_type", service)
        set_metadata("service_" .. port .. "_banner", banner or "")
        
        if version then
            set_metadata("service_" .. port .. "_version", version)
        end
        
        if software then
            set_metadata("service_" .. port .. "_software", software)
        end
        
        set_metadata("service_" .. port .. "_risk", risk_level)
        
        if #risk_reasons > 0 then
            set_metadata("service_" .. port .. "_risk_reasons", table.concat(risk_reasons, "; "))
        end
        
        -- Add service type tags
        add_tag("service-" .. service)
        
        -- Add risk-based tags
        if risk_level == "CRITICAL" then
            critical_risk_services = critical_risk_services + 1
            add_tag("critical-service-" .. port)
            add_tag("article-11-critical-exposure")
        elseif risk_level == "HIGH" then
            high_risk_services = high_risk_services + 1  
            add_tag("high-risk-service-" .. port)
            add_tag("article-11-high-exposure")
        end
        
        -- Service-specific tags
        if service == "http" or service == "https" then
            add_tag("web-service")
        elseif service == "ssh" then
            add_tag("remote-access")
        elseif service == "ftp" then
            add_tag("file-transfer")
            if risk_level ~= "LOW" then
                add_tag("insecure-file-transfer")
            end
        elseif service == "smtp" then
            add_tag("mail-server")
        elseif service:match("sql") or service:match("database") or service == "redis" or service == "mongodb" then
            add_tag("database-service")
            add_tag("database-exposed")
        end
        
        -- Log findings
        local log_msg = "Service: " .. service .. " on port " .. port
        if version then
            log_msg = log_msg .. " (version: " .. version .. ")"
        end
        log_msg = log_msg .. " - Risk: " .. risk_level
        
        if banner and banner ~= "" then
            log_msg = log_msg .. " - Banner: " .. string.sub(banner, 1, 50)
            if #banner > 50 then
                log_msg = log_msg .. "..."
            end
        end
        
        log(log_msg)
        
        -- Rate limiting
        sleep(0.1)
        
        ::continue::
    end
    
    return services_detected, high_risk_services, critical_risk_services
end

-- Execute service detection
local detected, high_risk, critical_risk = detect_services()

if not detected or detected == 0 then
    log("No services detected")
    pass_checklist("service-authentication-020", "No services requiring authentication detected")
    pass_checklist("web-service-security-021", "No web services detected to evaluate")
    na()
else
    log("Service detection completed: " .. detected .. " services analyzed")
    
    -- Set summary metadata
    set_metadata("services_detected_count", detected)
    set_metadata("high_risk_services_count", high_risk)
    set_metadata("critical_risk_services_count", critical_risk)
    
    -- Article 11 compliance assessment and checklist integration
    if critical_risk > 0 then
        set_metadata("service_risk_assessment", "critical")
        set_metadata("article_11_service_compliance", "non-compliant")
        add_tag("article-11-service-violations")
        log("CRITICAL: " .. critical_risk .. " critical risk services detected")
        fail_checklist("service-authentication-020", "Critical risk services detected requiring immediate authentication review (" .. critical_risk .. " services)")
        fail_checklist("web-service-security-021", "Web service security compromised by critical risk services")
    elseif high_risk > 0 then
        set_metadata("service_risk_assessment", "high")
        set_metadata("article_11_service_compliance", "needs-review") 
        add_tag("article-11-service-review-needed")
        log("WARNING: " .. high_risk .. " high risk services detected")
        fail_checklist("service-authentication-020", "High risk services detected requiring authentication review (" .. high_risk .. " services)")
        pass_checklist("web-service-security-021", "Web services acceptable but require monitoring")
    else
        set_metadata("service_risk_assessment", "acceptable")
        set_metadata("article_11_service_compliance", "compliant")
        add_tag("article-11-service-compliant")
        pass_checklist("service-authentication-020", "Service authentication assessment passed (" .. detected .. " services analyzed)")
        pass_checklist("web-service-security-021", "Web service security configuration acceptable")
    end
    
    pass()
end

log("Service detection analysis complete for " .. asset.value)