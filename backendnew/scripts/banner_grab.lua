-- @title Service Banner & Fingerprint Analysis
-- @description Comprehensive service detection, version extraction, and banner analysis for all service assets
-- @category service_detection
-- @author RegTech
-- @version 2.0
-- @asset_types service

if asset.type ~= "service" then
    log("Skipping banner analysis - not a service asset")
    return
end

-- Parse service asset value (expected format: "host:port/proto")
local host, rest = asset.value:match("^([^:]+):(.+)$")
if not host or not rest then
    log("Could not parse service format: " .. asset.value)
    return
end

local port = tonumber(rest:match("^(%d+)") or "")
if not port then
    log("Could not extract port from: " .. asset.value)
    return
end

-- Utility functions
local function trim(s)
    if not s then return "" end
    s = s:gsub("\r", " "):gsub("\n", " "):gsub("%s+", " ")
    return s:match("^%s*(.-)%s*$") or ""
end

local function safe_tcp_recv(fd, max_bytes, timeout)
    local data = tcp.recv(fd, max_bytes or 1024, timeout or 1.5)
    if data and #data > 0 then
        return trim(data)
    end
    return nil
end

-- Comprehensive service detection database
local service_patterns = {
    -- SSH Services
    {pattern = "SSH%-([%d%.]+)", service = "ssh", version_capture = 1, confidence = "high"},
    {pattern = "OpenSSH_([%d%.%w%-]+)", service = "openssh", version_capture = 1, confidence = "high"},
    
    -- HTTP Services
    {pattern = "HTTP/([%d%.]+)", service = "http", version_capture = 1, confidence = "high"},
    {pattern = "Server:%s*([^\r\n]+)", service = "http", version_capture = 1, confidence = "medium"},
    {pattern = "nginx/([%d%.]+)", service = "nginx", version_capture = 1, confidence = "high"},
    {pattern = "Apache/([%d%.]+)", service = "apache", version_capture = 1, confidence = "high"},
    {pattern = "Microsoft%-IIS/([%d%.]+)", service = "iis", version_capture = 1, confidence = "high"},
    
    -- Mail Services
    {pattern = "220 .* SMTP", service = "smtp", version_capture = nil, confidence = "medium"},
    {pattern = "220%-([%w%.%-]+) ESMTP", service = "smtp", version_capture = 1, confidence = "high"},
    {pattern = "Postfix", service = "postfix", version_capture = nil, confidence = "medium"},
    {pattern = "Exim ([%d%.]+)", service = "exim", version_capture = 1, confidence = "high"},
    
    -- POP3/IMAP
    {pattern = "%+OK .* POP3", service = "pop3", version_capture = nil, confidence = "medium"},
    {pattern = "%* OK .* IMAP", service = "imap", version_capture = nil, confidence = "medium"},
    {pattern = "Dovecot", service = "dovecot", version_capture = nil, confidence = "medium"},
    
    -- FTP Services
    {pattern = "220 .* FTP", service = "ftp", version_capture = nil, confidence = "medium"},
    {pattern = "vsftpd ([%d%.]+)", service = "vsftpd", version_capture = 1, confidence = "high"},
    {pattern = "ProFTPD ([%d%.]+)", service = "proftpd", version_capture = 1, confidence = "high"},
    
    -- Database Services
    {pattern = "mysql_native_password", service = "mysql", version_capture = nil, confidence = "medium"},
    {pattern = "PostgreSQL", service = "postgresql", version_capture = nil, confidence = "medium"},
    {pattern = "MongoDB", service = "mongodb", version_capture = nil, confidence = "medium"},
    
    -- Redis
    {pattern = "%+PONG", service = "redis", version_capture = nil, confidence = "high"},
    {pattern = "redis_version:([%d%.]+)", service = "redis", version_capture = 1, confidence = "high"},
    
    -- Other Services
    {pattern = "Telnet", service = "telnet", version_capture = nil, confidence = "medium"},
    {pattern = "SNMP", service = "snmp", version_capture = nil, confidence = "medium"},
}

-- Port-based service inference
local well_known_ports = {
    [21] = {service = "ftp", version = "standard", description = "File Transfer Protocol"},
    [22] = {service = "ssh", version = "standard", description = "Secure Shell"},
    [23] = {service = "telnet", version = "standard", description = "Telnet Protocol"},
    [25] = {service = "smtp", version = "standard", description = "Simple Mail Transfer Protocol"},
    [53] = {service = "dns", version = "standard", description = "Domain Name System"},
    [80] = {service = "http", version = "standard", description = "Hypertext Transfer Protocol"},
    [110] = {service = "pop3", version = "standard", description = "Post Office Protocol v3"},
    [143] = {service = "imap", version = "standard", description = "Internet Message Access Protocol"},
    [443] = {service = "https", version = "tls", description = "HTTP over TLS/SSL"},
    [993] = {service = "imaps", version = "tls", description = "IMAP over TLS/SSL"},
    [995] = {service = "pop3s", version = "tls", description = "POP3 over TLS/SSL"},
    [3306] = {service = "mysql", version = "standard", description = "MySQL Database"},
    [5432] = {service = "postgresql", version = "standard", description = "PostgreSQL Database"},
    [6379] = {service = "redis", version = "standard", description = "Redis In-Memory Database"},
    [27017] = {service = "mongodb", version = "standard", description = "MongoDB Database"},
    [3389] = {service = "rdp", version = "standard", description = "Remote Desktop Protocol"},
    [631] = {service = "ipp", version = "standard", description = "Internet Printing Protocol"},
    [8080] = {service = "http-alt", version = "standard", description = "Alternative HTTP Port"},
    [8443] = {service = "https-alt", version = "tls", description = "Alternative HTTPS Port"},
}

-- Advanced banner analysis
local function analyze_banner(banner, port)
    local results = {
        service = nil,
        version = nil,
        confidence = "unknown",
        details = {},
        security_notes = {}
    }
    
    if not banner or #banner == 0 then
        -- No banner available, infer from port
        local port_info = well_known_ports[port]
        if port_info then
            results.service = port_info.service
            results.version = port_info.version
            results.confidence = "port-based"
            results.details.description = port_info.description
            results.details.inference_method = "well-known port mapping"
        else
            results.service = "unknown"
            results.version = "unknown"
            results.confidence = "none"
            results.details.inference_method = "no banner, unknown port"
        end
        return results
    end
    
    -- Analyze banner against patterns
    local best_match = nil
    local highest_confidence = "none"
    
    for _, pattern_info in ipairs(service_patterns) do
        local match = banner:match(pattern_info.pattern)
        if match then
            if not best_match or pattern_info.confidence == "high" then
                best_match = pattern_info
                if pattern_info.version_capture then
                    results.version = match
                else
                    results.version = "detected"
                end
                results.service = pattern_info.service
                results.confidence = pattern_info.confidence
                highest_confidence = pattern_info.confidence
            end
        end
    end
    
    -- If no pattern matched, try port-based inference
    if not best_match then
        local port_info = well_known_ports[port]
        if port_info then
            results.service = port_info.service
            results.version = "inferred"
            results.confidence = "port-based"
            results.details.description = port_info.description
        else
            results.service = "unknown-tcp"
            results.version = "unidentified"
            results.confidence = "low"
        end
    end
    
    -- Add security analysis
    if results.service == "telnet" then
        table.insert(results.security_notes, "Unencrypted protocol")
    elseif results.service == "ftp" and not banner:match("FTPS") then
        table.insert(results.security_notes, "Unencrypted file transfer")
    elseif results.service == "http" then
        table.insert(results.security_notes, "Unencrypted web traffic")
    elseif results.service:match("tls$") or results.service:match("ssl$") or results.service == "https" then
        table.insert(results.security_notes, "Encrypted connection")
    end
    
    return results
end

-- Protocol-specific probes
local function probe_http(host, port)
    local request = "HEAD / HTTP/1.1\r\nHost: " .. host .. "\r\nConnection: close\r\nUser-Agent: RegTech-Scanner/2.0\r\n\r\n"
    local fd, err = tcp.connect(host, port, 3)
    if fd then
        tcp.send(fd, request)
        local response = safe_tcp_recv(fd, 2048, 3)
        tcp.close(fd)
        if response and response:match("HTTP/") then
            return response
        end
    end
    return nil
end

local function probe_redis(host, port)
    local fd, err = tcp.connect(host, port, 2)
    if fd then
        tcp.send(fd, "PING\r\n")
        local response = safe_tcp_recv(fd, 512, 2)
        tcp.close(fd)
        if response and response:match("PONG") then
            -- Try to get version info
            local fd2, err2 = tcp.connect(host, port, 2)
            if fd2 then
                tcp.send(fd2, "INFO server\r\n")
                local info = safe_tcp_recv(fd2, 1024, 2)
                tcp.close(fd2)
                if info then
                    return "Redis server info: " .. info:sub(1, 200)
                end
            end
            return response
        end
    end
    return nil
end

-- Main banner grabbing logic
log("Starting comprehensive service analysis for: " .. host .. ":" .. port)

local raw_banner = nil
local analysis_method = "tcp_connect"

-- Step 1: Try direct TCP connection for banner
local fd, err = tcp.connect(host, port, 3)
if fd then
    raw_banner = safe_tcp_recv(fd, 1024, 2)
    tcp.close(fd)
    
    if raw_banner and #raw_banner > 0 then
        log("Raw banner received (" .. #raw_banner .. " bytes): " .. raw_banner:sub(1, 150))
        analysis_method = "passive_banner"
    end
end

-- Step 2: If no banner, try protocol-specific probes
if not raw_banner or #raw_banner == 0 then
    -- Try HTTP probe for common web ports
    if port == 80 or port == 8080 or port == 8000 or port == 8008 or port == 3000 then
        raw_banner = probe_http(host, port)
        if raw_banner then
            analysis_method = "http_probe"
        end
    end
    
    -- Try Redis probe
    if port == 6379 and not raw_banner then
        raw_banner = probe_redis(host, port)
        if raw_banner then
            analysis_method = "redis_probe"
        end
    end
end

-- Step 3: Analyze the banner or infer from port
local analysis = analyze_banner(raw_banner, port)

-- Step 4: Set comprehensive metadata
set_metadata("service.port." .. port, analysis.service)
set_metadata("service.version.port." .. port, analysis.version or "unknown")
set_metadata("service.confidence.port." .. port, analysis.confidence)
set_metadata("service.analysis_method.port." .. port, analysis_method)

if raw_banner and #raw_banner > 0 then
    set_metadata("banner.port." .. port, raw_banner:sub(1, 500))  -- Limit banner size
    set_metadata("banner.length.port." .. port, #raw_banner)
else
    -- Always provide a meaningful banner description
    local port_info = well_known_ports[port]
    if port_info then
        set_metadata("banner.port." .. port, "No plaintext banner - " .. port_info.description .. " service detected on port " .. port)
    else
        set_metadata("banner.port." .. port, "No banner available - TCP service on port " .. port .. " (service type: " .. analysis.service .. ")")
    end
end

-- Step 5: Add detailed service information
if analysis.details.description then
    set_metadata("service.description.port." .. port, analysis.details.description)
end

if analysis.details.inference_method then
    set_metadata("service.inference.port." .. port, analysis.details.inference_method)
end

-- Step 6: Security analysis
if #analysis.security_notes > 0 then
    set_metadata("service.security_notes.port." .. port, table.concat(analysis.security_notes, "; "))
    
    for _, note in ipairs(analysis.security_notes) do
        if note:match("Unencrypted") then
            add_tag("unencrypted-service")
        elseif note:match("Encrypted") then
            add_tag("encrypted-service")
        end
    end
end

-- Step 7: Add service tags
add_tag(analysis.service)
if analysis.confidence == "high" then
    add_tag("high-confidence-detection")
elseif analysis.confidence == "medium" then
    add_tag("medium-confidence-detection")
else
    add_tag("low-confidence-detection")
end

-- Step 8: Generate comprehensive log output
local log_parts = {}
table.insert(log_parts, "Service Analysis Complete:")
table.insert(log_parts, "  Host: " .. host .. ":" .. port)
table.insert(log_parts, "  Service: " .. analysis.service)
table.insert(log_parts, "  Version: " .. (analysis.version or "unknown"))
table.insert(log_parts, "  Confidence: " .. analysis.confidence)
table.insert(log_parts, "  Method: " .. analysis_method)

if raw_banner and #raw_banner > 0 then
    table.insert(log_parts, "  Banner: \"" .. raw_banner:sub(1, 100) .. (#raw_banner > 100 and "..." or "") .. "\"")
else
    table.insert(log_parts, "  Banner: No plaintext banner detected")
end

if #analysis.security_notes > 0 then
    table.insert(log_parts, "  Security: " .. table.concat(analysis.security_notes, ", "))
end

log(table.concat(log_parts, "\n"))

-- Step 9: Final assessment
if analysis.confidence == "high" or analysis.confidence == "medium" then
    pass()
else
    -- Even for low confidence, we still pass since we provided useful information
    pass()
end