-- @title TCP Port Scanner
-- @description TCP port sweep on targets/ranges; record open ports for Article 11 network exposure assessment
-- @category network
-- @author RegTech Compliance Team  
-- @version 1.0
-- @asset_types ip,domain,subdomain
-- @moldovan_law Article 11 - Security Measures (Network exposure inventory)

log("Starting TCP port scan for: " .. asset.value)

-- Common port lists for different scan types
local common_ports = {
    21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 993, 995, 1723, 3306, 3389, 5432, 5900, 6379, 8080, 8443
}

local critical_ports = {
    22,    -- SSH
    23,    -- Telnet (insecure)
    80,    -- HTTP
    443,   -- HTTPS
    3389,  -- RDP
    21,    -- FTP
    25,    -- SMTP
    110,   -- POP3 (insecure)
    143,   -- IMAP (insecure)
    993,   -- IMAPS
    995,   -- POP3S
    53,    -- DNS
    111,   -- RPC
    135,   -- Windows RPC
    139,   -- NetBIOS
    445,   -- SMB
    1433,  -- SQL Server
    3306,  -- MySQL
    5432,  -- PostgreSQL
    6379,  -- Redis
    27017  -- MongoDB
}

-- Service guessing based on common ports
local port_services = {
    [21] = "ftp",
    [22] = "ssh", 
    [23] = "telnet",
    [25] = "smtp",
    [53] = "dns",
    [80] = "http",
    [110] = "pop3",
    [111] = "rpc",
    [135] = "msrpc",
    [139] = "netbios-ssn",
    [143] = "imap",
    [443] = "https",
    [445] = "microsoft-ds",
    [993] = "imaps",
    [995] = "pop3s",
    [1433] = "mssql",
    [1521] = "oracle",
    [3306] = "mysql",
    [3389] = "rdp",
    [5432] = "postgresql", 
    [5900] = "vnc",
    [6379] = "redis",
    [8080] = "http-alt",
    [8443] = "https-alt",
    [27017] = "mongodb"
}

-- Risk levels for different services
local port_risk_levels = {
    [21] = "HIGH",      -- FTP - often insecure
    [23] = "CRITICAL",  -- Telnet - plaintext
    [110] = "HIGH",     -- POP3 - often unencrypted 
    [143] = "HIGH",     -- IMAP - often unencrypted
    [1433] = "HIGH",    -- Database exposed
    [3306] = "HIGH",    -- MySQL exposed
    [3389] = "HIGH",    -- RDP exposed
    [5432] = "HIGH",    -- PostgreSQL exposed
    [6379] = "HIGH",    -- Redis exposed
    [27017] = "HIGH"    -- MongoDB exposed
}

-- Function to perform TCP port scan
local function scan_port(host, port, timeout)
    timeout = timeout or 3
    
    local fd, err = tcp.connect(host, port, timeout)
    if fd then
        tcp.close(fd)
        return true
    end
    return false
end

-- Function to scan a list of ports
local function scan_ports(host, ports)
    local open_ports = {}
    local total_scanned = 0
    local scan_start = os.time()
    
    log("Scanning " .. #ports .. " ports on " .. host)
    
    for _, port in ipairs(ports) do
        total_scanned = total_scanned + 1
        
        if scan_port(host, port, 2) then
            table.insert(open_ports, port)
            
            local service = port_services[port] or "unknown"
            local risk = port_risk_levels[port] or "MEDIUM"
            
            log("OPEN: " .. host .. ":" .. port .. " (" .. service .. ") - Risk: " .. risk)
            
            -- Set individual port metadata
            set_metadata("port_" .. port .. "_status", "open")
            set_metadata("port_" .. port .. "_service", service)
            set_metadata("port_" .. port .. "_risk", risk)
            
            -- Tag critical findings
            if risk == "CRITICAL" or risk == "HIGH" then
                add_tag("high-risk-port-" .. port)
                if port == 23 then
                    add_tag("telnet-exposed")
                    add_tag("article-11-violation")
                elseif port == 21 then
                    add_tag("ftp-exposed")
                elseif port == 3389 then
                    add_tag("rdp-exposed")
                    add_tag("remote-access-exposed")
                end
            end
        end
        
        -- Rate limiting to avoid overwhelming target
        if total_scanned % 10 == 0 then
            sleep(0.1)
        end
    end
    
    local scan_duration = os.time() - scan_start
    log("Port scan completed in " .. scan_duration .. " seconds")
    
    return open_ports
end

-- Determine target host
local target_host = asset.value

-- For domains/subdomains, we might want to resolve to IP first
-- But for now, we'll scan the hostname directly
if asset.type == "domain" or asset.type == "subdomain" then
    log("Scanning domain/subdomain: " .. target_host)
    -- Note: In production, you might want to resolve to IP first
elseif asset.type == "ip" then
    log("Scanning IP address: " .. target_host)
else
    log("Asset type not suitable for port scanning: " .. asset.type)
    na()
    return
end

-- Perform the scan - use critical ports for comprehensive coverage
local open_ports = scan_ports(target_host, critical_ports)

-- Analyze results
local total_open = #open_ports
if total_open == 0 then
    log("No open ports found on " .. target_host)
    set_metadata("open_ports_count", 0)
    set_metadata("port_scan_result", "no_open_ports")
    add_tag("no-open-ports")
    pass_checklist("open-ports-review-014", "No open ports detected - optimal security posture")
    pass_checklist("high-risk-port-exposure-025", "No port exposure detected")
    pass()
else
    log("Found " .. total_open .. " open ports on " .. target_host)
    
    -- Set summary metadata
    set_metadata("open_ports_count", total_open)
    set_metadata("open_ports_list", table.concat(open_ports, ","))
    set_metadata("port_scan_result", "open_ports_found")
    
    -- Determine exposure level
    local high_risk_count = 0
    local critical_risk_count = 0
    
    for _, port in ipairs(open_ports) do
        local risk = port_risk_levels[port] or "MEDIUM"
        if risk == "HIGH" then
            high_risk_count = high_risk_count + 1
        elseif risk == "CRITICAL" then
            critical_risk_count = critical_risk_count + 1
        end
    end
    
    set_metadata("high_risk_ports_count", high_risk_count)
    set_metadata("critical_risk_ports_count", critical_risk_count)
    
    -- Tag based on exposure level and checklist assessment
    if critical_risk_count > 0 then
        add_tag("critical-exposure")
        add_tag("article-11-high-risk")
        fail_checklist("high-risk-port-exposure-025", "Critical high-risk ports detected: " .. critical_risk_count .. " critical services exposed")
        fail_checklist("open-ports-review-014", "Open port security review failed due to critical risk exposure")
    elseif high_risk_count > 0 then
        add_tag("high-exposure")
        add_tag("article-11-medium-risk")
        fail_checklist("high-risk-port-exposure-025", "High-risk ports detected: " .. high_risk_count .. " high-risk services exposed")
        pass_checklist("open-ports-review-014", "Open ports detected but within acceptable risk levels (" .. total_open .. " ports)")
    elseif total_open > 10 then
        add_tag("extensive-exposure")
        pass_checklist("high-risk-port-exposure-025", "No high-risk ports detected")
        pass_checklist("open-ports-review-014", "Extensive port exposure requires review (" .. total_open .. " ports)")
    else
        pass_checklist("high-risk-port-exposure-025", "No high-risk ports detected")
        pass_checklist("open-ports-review-014", "Open port configuration acceptable (" .. total_open .. " ports)")
    end
    
    -- Article 11 compliance assessment
    local insecure_protocols = 0
    local secure_services = 0
    
    for _, port in ipairs(open_ports) do
        if port == 23 or port == 21 or port == 110 or port == 143 then
            insecure_protocols = insecure_protocols + 1
        elseif port == 443 or port == 993 or port == 995 or port == 22 then
            secure_services = secure_services + 1
        end
    end
    
    set_metadata("insecure_protocols_count", insecure_protocols)
    set_metadata("secure_services_count", secure_services)
    
    if insecure_protocols > 0 then
        set_metadata("article_11_compliance", "non-compliant")
        add_tag("article-11-insecure-protocols")
        log("COMPLIANCE WARNING: Found " .. insecure_protocols .. " insecure protocol(s) exposed")
    else
        set_metadata("article_11_compliance", "compliant")
        add_tag("article-11-compliant-protocols")
    end
    
    -- Generate service suggestions for further analysis
    local services_for_analysis = {}
    for _, port in ipairs(open_ports) do
        local service = port_services[port] or "unknown"
        table.insert(services_for_analysis, target_host .. ":" .. port .. ":" .. service)
    end
    
    set_metadata("services_for_analysis", table.concat(services_for_analysis, ";"))
    
    pass()
end

log("Port scan analysis complete for " .. asset.value)