-- @title Port Security Checklist Validation with High Port Exposure Assessment
-- @description Checks open ports, validates security compliance, and assesses high port exposure risks
-- @category Network Security
-- @author RegTech Scanner
-- @version 2.0
-- @asset_types service
-- @compliance_article Article 11 - Security Measures

-- Only run on service assets
if asset.type ~= "service" then
    log("Skipping port security checklist - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    na_checklist("open-ports-review-014", "Invalid service format")
    na_checklist("high-risk-port-exposure-025", "Invalid service format")
    return
end

port = tonumber(port)
log("Checking port security and exposure for " .. host .. ":" .. port .. "/" .. protocol)

-- Set metadata about the port
set_metadata("port.number", port)
set_metadata("port.protocol", protocol)
set_metadata("port.host", host)

-- Define secure and risky ports (expanded definitions)
local secure_ports = {80, 443, 22, 25, 53, 110, 143, 993, 995, 587, 465, 123}
local risky_ports = {21, 23, 135, 139, 445, 1433, 1521, 3306, 3389, 5432, 6379, 27017}
local critical_risk_ports = {23, 135, 139, 445, 3389}  -- Telnet, RPC, NetBIOS, SMB, RDP

-- High port categories (ports > 1024)
local common_high_ports = {
    -- Web development ports
    [3000] = {service = "Node.js/React Dev", risk = "HIGH", category = "development"},
    [3001] = {service = "Development Server", risk = "HIGH", category = "development"}, 
    [4000] = {service = "Development Server", risk = "HIGH", category = "development"},
    [5000] = {service = "Flask/Python Dev", risk = "HIGH", category = "development"},
    [8000] = {service = "HTTP Alt/Django", risk = "MEDIUM", category = "web"},
    [8080] = {service = "HTTP Proxy/Alt", risk = "MEDIUM", category = "web"},
    [8443] = {service = "HTTPS Alt", risk = "MEDIUM", category = "web"},
    [8888] = {service = "HTTP Alt/Jupyter", risk = "HIGH", category = "development"},
    
    -- Database and cache high ports
    [5432] = {service = "PostgreSQL", risk = "CRITICAL", category = "database"},
    [6379] = {service = "Redis", risk = "HIGH", category = "database"},
    [27017] = {service = "MongoDB", risk = "HIGH", category = "database"},
    [9200] = {service = "Elasticsearch", risk = "HIGH", category = "database"},
    
    -- Monitoring and admin
    [9090] = {service = "Prometheus", risk = "HIGH", category = "monitoring"},
    [9091] = {service = "Prometheus Pushgateway", risk = "HIGH", category = "monitoring"},
    [3000] = {service = "Grafana", risk = "HIGH", category = "monitoring"},
    [5601] = {service = "Kibana", risk = "HIGH", category = "monitoring"},
    [8081] = {service = "Jenkins", risk = "CRITICAL", category = "ci_cd"},
    
    -- Remote access high ports
    [5900] = {service = "VNC", risk = "CRITICAL", category = "remote_access"},
    [5901] = {service = "VNC", risk = "CRITICAL", category = "remote_access"},
    [5902] = {service = "VNC", risk = "CRITICAL", category = "remote_access"},
}

-- Function to assess high port exposure risk
local function assess_high_port_risk(port_num)
    if port_num <= 1024 then
        return nil  -- Not a high port
    end
    
    -- Check if it's a known high port
    if common_high_ports[port_num] then
        return common_high_ports[port_num]
    end
    
    -- Assess based on port ranges
    if port_num >= 49152 and port_num <= 65535 then
        return {service = "Dynamic/Private Port", risk = "LOW", category = "ephemeral"}
    elseif port_num >= 32768 and port_num <= 49151 then
        return {service = "Dynamic Port Range", risk = "LOW", category = "dynamic"}
    elseif port_num >= 8000 and port_num <= 8999 then
        return {service = "HTTP Alternative", risk = "MEDIUM", category = "web"}
    elseif port_num >= 9000 and port_num <= 9999 then
        return {service = "Network Service", risk = "MEDIUM", category = "network"}
    else
        return {service = "Unknown High Port", risk = "MEDIUM", category = "unknown"}
    end
end

-- Check if port is in secure list
local is_secure_port = false
for _, secure_port in ipairs(secure_ports) do
    if port == secure_port then
        is_secure_port = true
        break
    end
end

-- Check if port is in risky list
local is_risky_port = false
for _, risky_port in ipairs(risky_ports) do
    if port == risky_port then
        is_risky_port = true
        break
    end
end

-- Check if port is critical risk
local is_critical_risk = false
for _, critical_port in ipairs(critical_risk_ports) do
    if port == critical_port then
        is_critical_risk = true
        break
    end
end

-- Assess high port exposure
local high_port_assessment = assess_high_port_risk(port)
local is_high_port = (port > 1024)

-- Try to connect to the port to verify it's actually open
local fd, err = tcp.connect(host, port, 5)

if err then
    log("Port connection failed: " .. err)
    set_metadata("port.accessible", false)
    
    -- Port is not accessible, so it's not a security risk
    pass_checklist("open-ports-review-014", "Port " .. port .. " is not accessible")
    pass_checklist("high-risk-port-exposure-025", "Port " .. port .. " is not exposed")
    
    reject("Port not accessible")
    return
end

-- Port is accessible
log("Port " .. port .. " is accessible")
set_metadata("port.accessible", true)

-- Close the connection
tcp.close(fd)

-- Try to grab banner for additional information
local banner_fd, banner_err = tcp.connect(host, port, 3)
local service_banner = ""
if not banner_err then
    local banner, recv_err = tcp.recv(banner_fd, 1024, 3)
    if banner and banner ~= "" then
        service_banner = string.sub(banner, 1, 100)
        log("Service banner: " .. service_banner)
        set_metadata("port.banner", service_banner)
    end
    tcp.close(banner_fd)
end

-- Set additional metadata based on assessment
if is_high_port and high_port_assessment then
    set_metadata("port.risk_level", high_port_assessment.risk)
    set_metadata("port.service_type", high_port_assessment.service)
    set_metadata("port.category", high_port_assessment.category)
end

-- Determine overall compliance status
local compliance_status = "COMPLIANT"
local compliance_reasons = {}

-- Evaluate port security and exposure based on comprehensive assessment
if is_critical_risk then
    log("CRITICAL: Port " .. port .. " poses critical security risk")
    compliance_status = "NON_COMPLIANT"
    table.insert(compliance_reasons, "Critical risk port exposed")
    
    fail_checklist("open-ports-review-014", "Critical risk port " .. port .. " is accessible")
    fail_checklist("high-risk-port-exposure-025", "Critical high-risk port " .. port .. " exposed")
    
    -- Tag for critical exposure
    add_tag("critical-port-exposure")
    add_tag("article-11-violation")
    
    reject("Critical risk port exposure detected")
    
elseif is_risky_port then
    log("HIGH RISK: Port " .. port .. " is considered high risk")
    compliance_status = "NON_COMPLIANT"
    table.insert(compliance_reasons, "High-risk port exposed")
    
    fail_checklist("open-ports-review-014", "High-risk port " .. port .. " is accessible")
    fail_checklist("high-risk-port-exposure-025", "High-risk port " .. port .. " exposed")
    
    -- Also fail service authentication for database/admin ports
    if port == 1433 or port == 1521 or port == 3306 or port == 5432 or port == 3389 or port == 6379 or port == 27017 then
        fail_checklist("service-authentication-020", "Database/admin port " .. port .. " exposed without proper protection")
    end
    
    add_tag("high-risk-port-exposure")
    add_tag("article-11-risk")
    
    reject("High-risk port exposure detected")
    
elseif is_secure_port then
    log("SECURE: Port " .. port .. " is a standard secure service port")
    
    -- Additional checks for specific secure ports
    if port == 22 then
        pass_checklist("open-ports-review-014", "SSH port 22 is accessible (standard secure service)")
        pass_checklist("high-risk-port-exposure-025", "SSH on standard port (acceptable)")
    elseif port == 80 or port == 443 then
        pass_checklist("open-ports-review-014", "HTTP/HTTPS port " .. port .. " is accessible (standard web service)")
        pass_checklist("high-risk-port-exposure-025", "Web service on standard port (acceptable)")
        
        -- For web services, pass service authentication checklist
        pass_checklist("service-authentication-020", "Web service on standard port " .. port)
    else
        pass_checklist("open-ports-review-014", "Standard secure service port " .. port .. " is accessible")
        pass_checklist("high-risk-port-exposure-025", "Standard service port (acceptable)")
    end
    
    add_tag("secure-port-configuration")
    pass()
    
elseif is_high_port and high_port_assessment then
    -- High port exposure assessment
    local risk_level = high_port_assessment.risk
    local service_type = high_port_assessment.service
    local category = high_port_assessment.category
    
    log("HIGH PORT: " .. port .. " (" .. service_type .. ") - Risk: " .. risk_level .. " - Category: " .. category)
    
    if risk_level == "CRITICAL" then
        compliance_status = "NON_COMPLIANT"
        table.insert(compliance_reasons, "Critical high port service exposed")
        
        fail_checklist("open-ports-review-014", "Critical high port service " .. port .. " (" .. service_type .. ") exposed")
        fail_checklist("high-risk-port-exposure-025", "Critical high port exposure: " .. service_type .. " on port " .. port)
        
        add_tag("critical-high-port-exposure")
        add_tag("high-port-" .. category)
        
        reject("Critical high port service exposure")
        
    elseif risk_level == "HIGH" then
        compliance_status = "NON_COMPLIANT"
        table.insert(compliance_reasons, "High-risk high port service exposed")
        
        fail_checklist("open-ports-review-014", "High-risk high port service " .. port .. " (" .. service_type .. ") exposed")
        fail_checklist("high-risk-port-exposure-025", "High-risk high port exposure: " .. service_type .. " on port " .. port)
        
        add_tag("high-risk-high-port-exposure")
        add_tag("high-port-" .. category)
        
        reject("High-risk high port service exposure")
        
    elseif risk_level == "MEDIUM" then
        -- Medium risk high ports require review but may be acceptable
        log("MEDIUM RISK: High port " .. port .. " requires security review")
        
        pass_checklist("open-ports-review-014", "Medium-risk high port " .. port .. " (" .. service_type .. ") requires review")
        pass_checklist("high-risk-port-exposure-025", "Medium-risk high port acceptable with monitoring")
        
        add_tag("medium-risk-high-port")
        add_tag("high-port-" .. category)
        add_tag("requires-monitoring")
        
        pass()
        
    else -- LOW risk
        log("LOW RISK: High port " .. port .. " is low risk")
        
        pass_checklist("open-ports-review-014", "Low-risk high port " .. port .. " (acceptable)")
        pass_checklist("high-risk-port-exposure-025", "Low-risk high port (acceptable)")
        
        add_tag("low-risk-high-port")
        add_tag("high-port-" .. category)
        
        pass()
    end
    
else
    -- Non-standard low port (not in secure or risky lists)
    log("UNKNOWN: Non-standard low port " .. port .. " requires investigation")
    compliance_status = "NON_COMPLIANT"
    table.insert(compliance_reasons, "Unknown low port requires security review")
    
    fail_checklist("open-ports-review-014", "Non-standard low port " .. port .. " requires security review")
    fail_checklist("high-risk-port-exposure-025", "Unknown low port exposure requires investigation")
    
    add_tag("unknown-port-exposure")
    add_tag("requires-investigation")
    
    reject("Unknown low port requires security review")
end

-- Set final compliance metadata
set_metadata("port.compliance_status", compliance_status)
if #compliance_reasons > 0 then
    set_metadata("port.compliance_reasons", table.concat(compliance_reasons, "; "))
end

-- Log final compliance determination
if compliance_status == "COMPLIANT" then
    log("COMPLIANCE: Port " .. port .. " exposure is COMPLIANT with security requirements")
    add_tag("port-security-compliant")
else
    log("COMPLIANCE: Port " .. port .. " exposure is NON-COMPLIANT - " .. table.concat(compliance_reasons, "; "))
    add_tag("port-security-non-compliant")
end
