-- @description Basic asset information gathering
-- @category information
-- @author Asset Scanner Team
-- @version 1.0
-- @asset_types domain,subdomain,ip,service

log("Starting basic information gathering for: " .. asset.value)
log("Asset type: " .. asset.type)
log("Asset ID: " .. asset.id)

if asset.type == "domain" or asset.type == "subdomain" then
    log("Processing domain/subdomain asset")
    
    -- Set some metadata
    set_metadata("processed_at", os.date("%Y-%m-%d %H:%M:%S"))
    set_metadata("asset_length", string.len(asset.value))
    
    -- Check for interesting patterns
    if string.match(asset.value, "admin") then
        log("INTERESTING: Asset contains 'admin' keyword")
        set_metadata("has_admin_keyword", true)
    end
    
    if string.match(asset.value, "test") or string.match(asset.value, "dev") then
        log("INTERESTING: Asset appears to be a development/test environment")
        set_metadata("is_dev_environment", true)
    end

elseif asset.type == "ip" then
    log("Processing IP asset")
    
    -- Check for private IP ranges
    if string.match(asset.value, "^192%.168%.") or 
       string.match(asset.value, "^10%.") or 
       string.match(asset.value, "^172%.1[6-9]%.") or
       string.match(asset.value, "^172%.2[0-9]%.") or
       string.match(asset.value, "^172%.3[0-1]%.") then
        log("WARNING: Private IP address detected")
        set_metadata("is_private_ip", true)
    else
        log("Public IP address")
        set_metadata("is_private_ip", false)
    end

elseif asset.type == "service" then
    log("Processing service asset")
    
    -- Extract port information if available
    if asset.properties and asset.properties.port then
        local port = asset.properties.port
        log("Service running on port: " .. tostring(port))
        
        -- Flag interesting ports
        if port == 22 then
            log("SSH service detected")
            set_metadata("service_type", "ssh")
        elseif port == 80 or port == 443 then
            log("Web service detected")
            set_metadata("service_type", "web")
        elseif port == 21 then
            log("FTP service detected")
            set_metadata("service_type", "ftp")
        end
    end
end

log("Basic information gathering completed")
