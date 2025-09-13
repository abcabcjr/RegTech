-- @title SSL Certificate Checklist Validation
-- @description Validates SSL certificates and updates compliance checklist items
-- @category Cryptography
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service

-- Only run on service assets
if asset_type ~= "service" then
    output("Skipping SSL checklist - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset_value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    output("Could not parse service format: " .. asset_value)
    return
end

port = tonumber(port)

-- Only check HTTPS services
if port ~= 443 and port ~= 8443 then
    output("Skipping non-HTTPS port: " .. port)
    return
end

local url = "https://" .. host .. ":" .. port

output("Checking SSL certificate for: " .. url)

-- Make HTTPS request to check SSL
local response, err = http.get(url, {["User-Agent"] = "RegTech-Scanner/1.0"}, 10)

if err then
    output("HTTPS request failed: " .. err)
    set_metadata("ssl.error", err)
    
    -- Fail the SSL certificate checklist
    fail_checklist("ssl-certificate-validation-012", "HTTPS connection failed: " .. err)
    
    reject("HTTPS connection failed")
    return
end

-- If we got here, SSL connection was successful
output("SSL connection successful")
set_metadata("ssl.connection_successful", true)
set_metadata("ssl.status_code", response.status_code)

-- Check for security headers as additional SSL/TLS security indicators
local has_hsts = response.headers["Strict-Transport-Security"] ~= nil
local has_secure_headers = false

if has_hsts then
    output("HSTS header present: " .. response.headers["Strict-Transport-Security"])
    set_metadata("ssl.hsts_enabled", true)
    has_secure_headers = true
else
    output("Warning: No HSTS header found")
    set_metadata("ssl.hsts_enabled", false)
end

-- Pass the SSL certificate validation checklist
if response.status_code >= 200 and response.status_code < 400 then
    if has_secure_headers then
        pass_checklist("ssl-certificate-validation-012", "SSL certificate valid with security headers")
    else
        pass_checklist("ssl-certificate-validation-012", "SSL certificate valid but missing security headers")
    end
    
    -- Also check HTTP security headers checklist if HSTS is present
    if has_hsts then
        pass_checklist("http-security-headers-013", "HSTS header present")
    end
    
    pass()
else
    fail_checklist("ssl-certificate-validation-012", "SSL connection returned error status: " .. response.status)
    reject("SSL service returned error status")
end
