-- @title Port Security Checklist Validation
-- @description Checks open ports and validates security compliance
-- @category Network Security
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service

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
    return
end

port = tonumber(port)
log("Checking port security for " .. host .. ":" .. port .. "/" .. protocol)

-- Set metadata about the port
set_metadata("port.number", port)
set_metadata("port.protocol", protocol)
set_metadata("port.host", host)

-- Define secure and risky ports
local secure_ports = {80, 443, 22, 25, 53, 110, 143, 993, 995}
local risky_ports = {21, 23, 135, 139, 445, 1433, 1521, 3306, 3389, 5432}

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

-- Try to connect to the port to verify it's actually open
local fd, err = tcp.connect(host, port, 5)

if err then
    log("Port connection failed: " .. err)
    set_metadata("port.accessible", false)
    
    -- Port is not accessible, so it's not a security risk
    pass_checklist("open-ports-review-014", "Port " .. port .. " is not accessible")
    
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
if not banner_err then
    local banner, recv_err = tcp.recv(banner_fd, 1024, 3)
    if banner and banner ~= "" then
        log("Service banner: " .. string.sub(banner, 1, 100))
        set_metadata("port.banner", banner)
    end
    tcp.close(banner_fd)
end

-- Evaluate port security based on port number and protocol
if is_risky_port then
    log("Warning: Port " .. port .. " is considered risky")
    fail_checklist("open-ports-review-014", "Risky port " .. port .. " is accessible")
    
    -- Also fail service authentication if it's a database or admin port
    if port == 1433 or port == 1521 or port == 3306 or port == 5432 or port == 3389 then
        fail_checklist("service-authentication-020", "Database/admin port " .. port .. " exposed")
    end
    
    reject("Risky port is accessible")
    
elseif is_secure_port then
    log("Port " .. port .. " is a standard secure service port")
    
    -- Additional checks for specific ports
    if port == 22 then
        pass_checklist("open-ports-review-014", "SSH port 22 is accessible (standard)")
    elseif port == 80 or port == 443 then
        pass_checklist("open-ports-review-014", "HTTP/HTTPS port " .. port .. " is accessible (standard)")
        
        -- For web services, pass service authentication checklist (assuming web auth is in place)
        pass_checklist("service-authentication-020", "Web service on standard port " .. port)
    else
        pass_checklist("open-ports-review-014", "Standard service port " .. port .. " is accessible")
    end
    
    pass()
    
else
    -- Non-standard port
    log("Non-standard port " .. port .. " is accessible")
    
    if port > 1024 then
        -- High ports are generally less risky
        pass_checklist("open-ports-review-014", "Non-standard high port " .. port .. " (low risk)")
        pass()
    else
        -- Low ports that aren't in our secure list might be risky
        fail_checklist("open-ports-review-014", "Non-standard low port " .. port .. " requires review")
        reject("Non-standard low port requires security review")
    end
end
