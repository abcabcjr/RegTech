-- @title Enhanced Service Detection and Classification
-- @description Comprehensive service detection with improved identification and tagging
-- @category network  
-- @author RegTech Compliance Team
-- @version 2.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed port_scan.lua
-- @moldovan_law Article 11 - Security Measures (Service identification and risk assessment)

log("Starting enhanced service detection for: " .. asset.value)

-- Comprehensive service definitions with multiple identification methods
local service_definitions = {
    [21] = {
        name = "ftp",
        category = "file_transfer",
        risk = "HIGH",
        patterns = {"220 ", "FTP server", "vsftpd", "Pure-FTPd", "ProFTPD", "FileZilla"},
        probes = {"HELP\r\n", "USER anonymous\r\n"},
        tags = {"ftp-service", "file-transfer", "unencrypted-protocol"}
    },
    [22] = {
        name = "ssh",
        category = "remote_access", 
        risk = "MEDIUM",
        patterns = {"SSH-", "OpenSSH", "Dropbear"},
        probes = {"\r\n"},
        tags = {"ssh-service", "remote-access", "encrypted-protocol"}
    },
    [23] = {
        name = "telnet",
        category = "remote_access",
        risk = "CRITICAL",
        patterns = {"login:", "Username:", "Password:", "Welcome"},
        probes = {"\r\n", "help\r\n"},
        tags = {"telnet-service", "remote-access", "unencrypted-protocol", "legacy-protocol"}
    },
    [25] = {
        name = "smtp",
        category = "mail",
        risk = "MEDIUM",
        patterns = {"220.*SMTP", "220.*mail", "220.*ESMTP", "Postfix", "Sendmail", "Exchange"},
        probes = {"EHLO test\r\n", "HELP\r\n"},
        tags = {"smtp-service", "mail-server", "email-service"}
    },
    [53] = {
        name = "dns",
        category = "infrastructure",
        risk = "MEDIUM", 
        patterns = {"BIND", "dnsmasq", "PowerDNS"},
        probes = {},
        tags = {"dns-service", "infrastructure-service"}
    },
    [80] = {
        name = "http",
        category = "web",
        risk = "MEDIUM",
        patterns = {"HTTP/1", "Server:", "Content-Type:", "nginx", "Apache", "IIS"},
        probes = {"GET / HTTP/1.0\r\n\r\n", "HEAD / HTTP/1.0\r\n\r\n"},
        tags = {"http-service", "web-service", "unencrypted-web"}
    },
    [110] = {
        name = "pop3",
        category = "mail",
        risk = "HIGH",
        patterns = {"+OK", "POP3", "ready"},
        probes = {"USER test\r\n", "HELP\r\n"},
        tags = {"pop3-service", "mail-service", "unencrypted-mail"}
    },
    [143] = {
        name = "imap",
        category = "mail", 
        risk = "HIGH",
        patterns = {"* OK", "IMAP", "ready"},
        probes = {"A001 CAPABILITY\r\n", "A001 LOGOUT\r\n"},
        tags = {"imap-service", "mail-service", "unencrypted-mail"}
    },
    [161] = {
        name = "snmp",
        category = "monitoring",
        risk = "MEDIUM",
        patterns = {},
        probes = {},
        tags = {"snmp-service", "monitoring-service", "management-protocol"}
    },
    [389] = {
        name = "ldap",
        category = "directory",
        risk = "MEDIUM",
        patterns = {"LDAP", "Active Directory"},
        probes = {},
        tags = {"ldap-service", "directory-service", "authentication-service"}
    },
    [443] = {
        name = "https",
        category = "web",
        risk = "LOW",
        patterns = {"HTTP/1", "Server:", "Content-Type:", "nginx", "Apache", "IIS"},
        probes = {},
        tags = {"https-service", "web-service", "encrypted-web", "ssl-service"}
    },
    [587] = {
        name = "smtp-submission",
        category = "mail",
        risk = "MEDIUM", 
        patterns = {"220.*SMTP", "220.*mail", "220.*ESMTP"},
        probes = {"EHLO test\r\n"},
        tags = {"smtp-service", "mail-server", "email-submission"}
    },
    [636] = {
        name = "ldaps",
        category = "directory",
        risk = "LOW",
        patterns = {},
        probes = {},
        tags = {"ldaps-service", "directory-service", "encrypted-ldap", "ssl-service"}
    },
    [993] = {
        name = "imaps",
        category = "mail",
        risk = "LOW",
        patterns = {},
        probes = {},
        tags = {"imaps-service", "mail-service", "encrypted-mail", "ssl-service"}
    },
    [995] = {
        name = "pop3s",
        category = "mail",
        risk = "LOW",
        patterns = {},
        probes = {},
        tags = {"pop3s-service", "mail-service", "encrypted-mail", "ssl-service"}
    },
    [1433] = {
        name = "mssql",
        category = "database",
        risk = "HIGH",
        patterns = {"Microsoft SQL Server", "MSSQL"},
        probes = {},
        tags = {"mssql-service", "database-service", "microsoft-service"}
    },
    [2222] = {
        name = "ssh-alt",
        category = "remote_access",
        risk = "MEDIUM",
        patterns = {"SSH-", "OpenSSH", "Dropbear"},
        probes = {"\r\n"},
        tags = {"ssh-service", "remote-access", "encrypted-protocol", "non-standard-port"}
    },
    [3306] = {
        name = "mysql",
        category = "database",
        risk = "HIGH",
        patterns = {"MySQL", "mysql_native_password", "MariaDB"},
        probes = {},
        tags = {"mysql-service", "database-service", "sql-database"}
    },
    [3389] = {
        name = "rdp",
        category = "remote_access",
        risk = "HIGH",
        patterns = {"Microsoft Terminal Services", "Remote Desktop"},
        probes = {},
        tags = {"rdp-service", "remote-access", "windows-service", "desktop-sharing"}
    },
    [5432] = {
        name = "postgresql",
        category = "database",
        risk = "HIGH",
        patterns = {"PostgreSQL", "postgres"},
        probes = {},
        tags = {"postgresql-service", "database-service", "sql-database"}
    },
    [5900] = {
        name = "vnc",
        category = "remote_access",
        risk = "HIGH",
        patterns = {"RFB", "VNC"},
        probes = {},
        tags = {"vnc-service", "remote-access", "desktop-sharing", "unencrypted-protocol"}
    },
    [5901] = {
        name = "vnc-alt",
        category = "remote_access", 
        risk = "HIGH",
        patterns = {"RFB", "VNC"},
        probes = {},
        tags = {"vnc-service", "remote-access", "desktop-sharing", "unencrypted-protocol"}
    },
    [6379] = {
        name = "redis",
        category = "database",
        risk = "HIGH",
        patterns = {"Redis", "PONG", "+PONG"},
        probes = {"PING\r\n", "INFO\r\n"},
        tags = {"redis-service", "database-service", "nosql-database", "cache-service"}
    },
    [6901] = {
        name = "vnc-web",
        category = "remote_access",
        risk = "HIGH", 
        patterns = {"VNC", "noVNC", "Kasm"},
        probes = {},
        tags = {"vnc-service", "remote-access", "web-vnc", "desktop-sharing"}
    },
    [8080] = {
        name = "http-alt",
        category = "web",
        risk = "MEDIUM",
        patterns = {"HTTP/1", "Server:", "Content-Type:", "nginx", "Apache", "Jetty", "Tomcat"},
        probes = {"GET / HTTP/1.0\r\n\r\n"},
        tags = {"http-service", "web-service", "unencrypted-web", "non-standard-port"}
    },
    [8081] = {
        name = "http-alt2",
        category = "web",
        risk = "MEDIUM",
        patterns = {"HTTP/1", "Server:", "Content-Type:", "nginx", "Apache"},
        probes = {"GET / HTTP/1.0\r\n\r\n"},
        tags = {"http-service", "web-service", "unencrypted-web", "non-standard-port"}
    },
    [8443] = {
        name = "https-alt",
        category = "web",
        risk = "MEDIUM",
        patterns = {"HTTP/1", "Server:", "Content-Type:"},
        probes = {},
        tags = {"https-service", "web-service", "encrypted-web", "ssl-service", "non-standard-port"}
    },
    [9200] = {
        name = "elasticsearch",
        category = "database",
        risk = "HIGH",
        patterns = {"elasticsearch", "You Know, for Search", "cluster_name"},
        probes = {},
        tags = {"elasticsearch-service", "database-service", "search-engine", "nosql-database"}
    },
    [9300] = {
        name = "elasticsearch-transport",
        category = "database",
        risk = "HIGH",
        patterns = {"elasticsearch"},
        probes = {},
        tags = {"elasticsearch-service", "database-service", "transport-protocol"}
    },
    [11211] = {
        name = "memcached",
        category = "database",
        risk = "MEDIUM",
        patterns = {"STAT", "VERSION", "memcached"},
        probes = {"stats\r\n", "version\r\n"},
        tags = {"memcached-service", "cache-service", "memory-database"}
    },
    [27017] = {
        name = "mongodb",
        category = "database", 
        risk = "HIGH",
        patterns = {"MongoDB", "mongo", "ismaster"},
        probes = {},
        tags = {"mongodb-service", "database-service", "nosql-database", "document-database"}
    }
}

-- Enhanced banner grabbing with multiple probe attempts
local function enhanced_banner_grab(host, port, timeout)
    timeout = timeout or 5
    
    local fd, err = tcp_connect(host, port, timeout)
    if not fd then
        return nil, "Connection failed: " .. (err or "unknown error")
    end
    
    -- Try to receive initial banner
    local banner, recv_err = tcp_recv(fd, 1024, 3)
    
    -- If no initial banner, try service-specific probes
    if not banner or banner == "" then
        local service_def = service_definitions[port]
        if service_def and service_def.probes then
            for _, probe in ipairs(service_def.probes) do
                tcp_send(fd, probe)
                banner, recv_err = tcp_recv(fd, 1024, 2)
                if banner and banner ~= "" then
                    break
                end
            end
        end
        
        -- Generic probes if still no response
        if not banner or banner == "" then
            local generic_probes = {
                "GET / HTTP/1.0\r\n\r\n",  -- HTTP
                "\r\n",                    -- Generic newline
                "HELP\r\n",               -- Help command
                "INFO\r\n",               -- Info command
                "PING\r\n"                -- Ping command
            }
            
            for _, probe in ipairs(generic_probes) do
                tcp_send(fd, probe)
                banner, recv_err = tcp_recv(fd, 1024, 2)
                if banner and banner ~= "" then
                    break
                end
            end
        end
    end
    
    tcp_close(fd)
    return banner, recv_err
end

-- Enhanced service identification
local function identify_service_enhanced(banner, port)
    local service = "unknown"
    local version = nil
    local confidence = "low"
    
    -- First check if we have a service definition for this port
    local service_def = service_definitions[port]
    if service_def then
        service = service_def.name
        confidence = "medium"
        
        -- If we have a banner, try to match patterns for higher confidence
        if banner and banner ~= "" then
            for _, pattern in ipairs(service_def.patterns) do
                if string.find(string.lower(banner), string.lower(pattern)) then
                    confidence = "high"
                    
                    -- Try to extract version information
                    local version_patterns = {
                        pattern .. "%s+([%d%.%-]+)",
                        pattern .. "/([%d%.%-]+)",
                        pattern .. "_([%d%.%-]+)",
                        "version%s+([%d%.%-]+)",
                        "v([%d%.%-]+)"
                    }
                    
                    for _, ver_pattern in ipairs(version_patterns) do
                        local ver_match = string.match(banner, ver_pattern)
                        if ver_match then
                            version = ver_match
                            break
                        end
                    end
                    break
                end
            end
        end
    end
    
    -- Fallback: try to identify from banner patterns if port-based identification failed
    if service == "unknown" and banner and banner ~= "" then
        local banner_lower = string.lower(banner)
        
        -- Web services
        if string.find(banner_lower, "http/") or string.find(banner_lower, "server:") then
            service = port == 443 and "https" or "http"
            confidence = "high"
        -- SSH
        elseif string.find(banner_lower, "ssh%-") then
            service = "ssh"
            confidence = "high"
        -- FTP
        elseif string.find(banner_lower, "220 ") and string.find(banner_lower, "ftp") then
            service = "ftp"
            confidence = "high"
        -- SMTP
        elseif string.find(banner_lower, "220 ") and (string.find(banner_lower, "smtp") or string.find(banner_lower, "mail")) then
            service = "smtp"
            confidence = "high"
        -- Database services
        elseif string.find(banner_lower, "mysql") then
            service = "mysql"
            confidence = "high"
        elseif string.find(banner_lower, "redis") or string.find(banner_lower, "+pong") then
            service = "redis"
            confidence = "high"
        elseif string.find(banner_lower, "mongodb") or string.find(banner_lower, "mongo") then
            service = "mongodb"
            confidence = "high"
        end
    end
    
    return service, version, confidence
end

-- Enhanced risk assessment
local function assess_service_risk_enhanced(service, port, version, confidence)
    local risk_level = "MEDIUM"
    local risk_reasons = {}
    
    -- Get base risk from service definition
    local service_def = service_definitions[port]
    if service_def then
        risk_level = service_def.risk
    end
    
    -- Risk factors
    local risk_factors = {
        -- Critical risks
        telnet = "CRITICAL",
        ftp = "HIGH",
        http = "MEDIUM",
        vnc = "HIGH",
        
        -- Database risks
        mysql = "HIGH",
        mongodb = "HIGH", 
        redis = "HIGH",
        elasticsearch = "HIGH",
        
        -- Unencrypted protocols
        pop3 = "HIGH",
        imap = "HIGH",
        smtp = "MEDIUM"
    }
    
    if risk_factors[service] then
        risk_level = risk_factors[service]
    end
    
    -- Additional risk factors
    if service == "telnet" then
        table.insert(risk_reasons, "Unencrypted legacy protocol")
    elseif service == "ftp" then
        table.insert(risk_reasons, "Unencrypted file transfer")
    elseif string.find(service, "vnc") then
        table.insert(risk_reasons, "Unencrypted remote desktop access")
    elseif string.find(service, "database") or service == "mysql" or service == "mongodb" or service == "redis" then
        table.insert(risk_reasons, "Database service exposed")
    end
    
    -- Non-standard ports increase risk
    local standard_ports = {22, 25, 53, 80, 110, 143, 443, 993, 995}
    local is_standard = false
    for _, std_port in ipairs(standard_ports) do
        if port == std_port then
            is_standard = true
            break
        end
    end
    
    if not is_standard then
        table.insert(risk_reasons, "Non-standard port")
    end
    
    -- Low confidence identification increases risk
    if confidence == "low" then
        table.insert(risk_reasons, "Service identification uncertain")
        if risk_level == "LOW" then
            risk_level = "MEDIUM"
        end
    end
    
    return risk_level, risk_reasons
end

-- Main detection logic
local function detect_services_enhanced()
    local services_detected = 0
    local high_risk_services = 0
    local critical_risk_services = 0
    local unknown_services = 0
    
    local target_host = asset.value
    local ports_to_scan = {}
    
    -- Determine target host and ports
    if asset.type == "service" then
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
        -- Comprehensive port list including demo environment services
        ports_to_scan = {
            21, 22, 23, 25, 53, 80, 110, 143, 161, 389, 443, 587, 636,
            993, 995, 1433, 2222, 3306, 3389, 5432, 5900, 5901, 6379, 
            6901, 8080, 8081, 8443, 9200, 9300, 11211, 27017
        }
    end
    
    log("Performing enhanced service detection on " .. #ports_to_scan .. " ports")
    
    -- Detect services on each port
    for _, port in ipairs(ports_to_scan) do
        -- Check if port is open
        if scan_port(target_host, port, 2) then
            log("Detecting service on " .. target_host .. ":" .. port)
            
            local banner, banner_err = enhanced_banner_grab(target_host, port, 5)
            local service, version, confidence = identify_service_enhanced(banner, port)
            local risk_level, risk_reasons = assess_service_risk_enhanced(service, port, version, confidence)
            
            services_detected = services_detected + 1
            
            if service == "unknown" then
                unknown_services = unknown_services + 1
            end
            
            -- Set comprehensive metadata
            set_metadata("service_" .. port .. "_type", service)
            set_metadata("service_" .. port .. "_confidence", confidence)
            set_metadata("service_" .. port .. "_banner", banner or "")
            set_metadata("service_" .. port .. "_risk", risk_level)
            
            if version then
                set_metadata("service_" .. port .. "_version", version)
            end
            
            if #risk_reasons > 0 then
                set_metadata("service_" .. port .. "_risk_reasons", table.concat(risk_reasons, "; "))
            end
            
            -- Add comprehensive tags
            add_tag("service-detected")
            add_tag("service-" .. service)
            add_tag("port-" .. port .. "-open")
            
            -- Add service definition tags if available
            local service_def = service_definitions[port]
            if service_def and service_def.tags then
                for _, tag in ipairs(service_def.tags) do
                    add_tag(tag)
                end
            end
            
            -- Risk-based tags
            if risk_level == "CRITICAL" then
                critical_risk_services = critical_risk_services + 1
                add_tag("critical-service")
                add_tag("critical-service-" .. port)
                add_tag("article-11-critical-exposure")
            elseif risk_level == "HIGH" then
                high_risk_services = high_risk_services + 1
                add_tag("high-risk-service")
                add_tag("high-risk-service-" .. port)
                add_tag("article-11-high-exposure")
            end
            
            -- Category-based tags
            if service_def then
                add_tag("service-category-" .. service_def.category)
            end
            
            -- Log findings
            local log_msg = string.format("Service: %s on port %d (confidence: %s, risk: %s)", 
                service, port, confidence, risk_level)
            if version then
                log_msg = log_msg .. " version: " .. version
            end
            if banner and banner ~= "" then
                log_msg = log_msg .. " banner: " .. string.sub(banner, 1, 50)
                if #banner > 50 then
                    log_msg = log_msg .. "..."
                end
            end
            log(log_msg)
            
            -- Rate limiting
            sleep(0.1)
        end
    end
    
    return services_detected, high_risk_services, critical_risk_services, unknown_services
end

-- Execute enhanced service detection
local detected, high_risk, critical_risk, unknown = detect_services_enhanced()

-- Set summary metadata
set_metadata("services_detected_count", detected)
set_metadata("high_risk_services_count", high_risk)
set_metadata("critical_risk_services_count", critical_risk)
set_metadata("unknown_services_count", unknown)

-- Final assessment
if detected == 0 then
    log("No services detected")
    na()
elseif critical_risk > 0 then
    reject("Critical risk services detected: " .. critical_risk .. " critical, " .. high_risk .. " high risk services")
elseif high_risk > 0 then
    reject("High risk services detected: " .. high_risk .. " high risk services")
elseif unknown > detected / 2 then
    reject("Many unidentified services: " .. unknown .. " out of " .. detected .. " services could not be identified")
else
    pass()
end

log("Enhanced service detection completed: " .. detected .. " services detected, " .. critical_risk .. " critical, " .. high_risk .. " high risk, " .. unknown .. " unknown")
