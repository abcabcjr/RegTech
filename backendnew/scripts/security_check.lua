-- @description Basic security checks and vulnerability indicators
-- @category security
-- @author Asset Scanner Team
-- @version 1.0
-- @asset_types domain,subdomain,service

log("Starting security checks for: " .. asset.value)

if asset.type == "domain" or asset.type == "subdomain" then
    log("Performing domain security checks")
    
    -- Check for security-related subdomains
    local security_keywords = {
        "vpn", "mail", "webmail", "admin", "portal", "login", 
        "secure", "ssl", "api", "ftp", "ssh", "rdp"
    }
    
    for _, keyword in ipairs(security_keywords) do
        if string.match(asset.value:lower(), keyword) then
            log("SECURITY: Found security-related keyword: " .. keyword)
            set_metadata("security_keyword_" .. keyword, true)
        end
    end
    
    -- Check for development/staging indicators
    local dev_keywords = {"dev", "test", "staging", "stage", "beta", "demo"}
    for _, keyword in ipairs(dev_keywords) do
        if string.match(asset.value:lower(), keyword) then
            log("SECURITY: Development environment detected: " .. keyword)
            set_metadata("is_dev_environment", true)
            break
        end
    end

elseif asset.type == "service" then
    log("Performing service security checks")
    
    if asset.properties and asset.properties.port then
        local port = asset.properties.port
        
        -- Flag potentially insecure services
        if port == 21 then
            log("SECURITY: FTP service detected - potentially insecure")
            set_metadata("security_risk", "ftp_service")
        elseif port == 23 then
            log("SECURITY: Telnet service detected - insecure protocol")
            set_metadata("security_risk", "telnet_service")
        elseif port == 80 then
            log("SECURITY: HTTP service detected - unencrypted")
            set_metadata("security_risk", "unencrypted_http")
        elseif port == 3389 then
            log("SECURITY: RDP service detected - high-value target")
            set_metadata("security_risk", "rdp_service")
        elseif port == 445 then
            log("SECURITY: SMB service detected - potential vulnerability")
            set_metadata("security_risk", "smb_service")
        end
    end
end

log("Security checks completed")
