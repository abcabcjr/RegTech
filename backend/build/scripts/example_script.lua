-- Example Lua script for processing assets
-- The current asset is available as a global 'asset' table with all properties

log("Starting Lua script processing for asset: " .. asset.value)
log("Asset type: " .. asset.type .. ", ID: " .. asset.id)

-- Process different asset types
if asset.type == "domain" then
    log("Processing domain: " .. asset.value)
    
    -- Check subdomains
    if asset.subdomains then
        log("Domain has " .. #asset.subdomains .. " subdomains")
        
        -- Iterate through subdomains
        for i, subdomain in ipairs(asset.subdomains) do
            log("  Subdomain " .. i .. ": " .. subdomain)
        end
    end
    
    -- Check resolved IPs
    if asset.ips then
        log("Domain resolves to " .. #asset.ips .. " IP addresses")
        for i, ip in ipairs(asset.ips) do
            log("  IP " .. i .. ": " .. ip)
        end
    end
    
    -- Check if proxied
    if asset.proxied ~= nil then
        if asset.proxied then
            log("Domain is behind CDN/proxy")
        else
            log("Domain is not proxied")
        end
    end
    
    -- Check DNS records
    if asset.dns_records then
        if asset.dns_records.mx then
            log("Found " .. #asset.dns_records.mx .. " MX records")
            for i, mx in ipairs(asset.dns_records.mx) do
                log("  MX " .. i .. ": " .. mx)
            end
        end
        
        if asset.dns_records.txt then
            log("Found " .. #asset.dns_records.txt .. " TXT records")
            for i, txt in ipairs(asset.dns_records.txt) do
                log("  TXT " .. i .. ": " .. txt)
            end
        end
    end
    
elseif asset.type == "ip" then
    log("Processing IP address: " .. asset.value)
    
    -- Check ASN information
    if asset.asn then
        log("ASN: " .. asset.asn)
        if asset.asn_org then
            log("ASN Organization: " .. asset.asn_org)
        end
    end
    
    -- Check for services
    if asset.service_ids then
        log("IP has " .. #asset.service_ids .. " services")
        for i, service_id in ipairs(asset.service_ids) do
            log("  Service ID " .. i .. ": " .. service_id)
        end
    end
    
    -- Example: Flag private IP ranges
    if string.match(asset.value, "^192%.168%.") or 
       string.match(asset.value, "^10%.") or 
       string.match(asset.value, "^172%.1[6-9]%.") or
       string.match(asset.value, "^172%.2[0-9]%.") or
       string.match(asset.value, "^172%.3[0-1]%.") then
        log("WARNING: " .. asset.value .. " is in a private IP range")
    end
    
elseif asset.type == "service" then
    log("Processing service: " .. asset.value)
    
    if asset.port and asset.protocol then
        log("Service running on port " .. asset.port .. "/" .. asset.protocol)
        
        if asset.service then
            log("Service type: " .. asset.service)
        end
        
        if asset.version then
            log("Service version: " .. asset.version)
        end
        
        if asset.state then
            log("Service state: " .. asset.state)
        end
        
        if asset.source_ip then
            log("Source IP: " .. asset.source_ip)
        end
        
        -- Flag interesting services
        if asset.port == 22 then
            log("SSH service detected - potential entry point")
        elseif asset.port == 80 or asset.port == 443 then
            log("Web service detected - potential attack surface")
        elseif asset.port == 21 then
            log("FTP service detected - check for anonymous access")
        elseif asset.port == 3389 then
            log("RDP service detected - high-value target")
        elseif asset.port == 23 then
            log("Telnet service detected - insecure protocol")
        elseif asset.port == 25 then
            log("SMTP service detected - mail server")
        elseif asset.port == 53 then
            log("DNS service detected - name server")
        elseif asset.port == 110 then
            log("POP3 service detected - mail retrieval")
        elseif asset.port == 143 then
            log("IMAP service detected - mail access")
        elseif asset.port == 993 then
            log("IMAPS service detected - secure mail access")
        elseif asset.port == 995 then
            log("POP3S service detected - secure mail retrieval")
        end
    end
    
elseif asset.type == "subdomain" then
    log("Processing subdomain: " .. asset.value)
    
    -- Check resolved IPs
    if asset.ips then
        log("Subdomain resolves to " .. #asset.ips .. " IP addresses")
        for i, ip in ipairs(asset.ips) do
            log("  IP " .. i .. ": " .. ip)
        end
    end
    
    -- Check if proxied
    if asset.proxied ~= nil then
        if asset.proxied then
            log("Subdomain is behind CDN/proxy")
        else
            log("Subdomain is not proxied")
        end
    end
    
    -- Example: Check for interesting subdomain patterns
    local interesting_patterns = {
        "admin", "test", "dev", "staging", "api", "www", "mail", "ftp", 
        "vpn", "remote", "secure", "login", "portal", "dashboard",
        "internal", "intranet", "private", "beta", "demo"
    }
    
    for _, pattern in ipairs(interesting_patterns) do
        if string.match(asset.value, pattern) then
            log("INTERESTING: " .. asset.value .. " contains '" .. pattern .. "' - may be worth investigating")
            break
        end
    end
    
    -- Check DNS records
    if asset.dns_records then
        if asset.dns_records.cname then
            log("Found " .. #asset.dns_records.cname .. " CNAME records")
            for i, cname in ipairs(asset.dns_records.cname) do
                log("  CNAME " .. i .. ": " .. cname)
            end
        end
    end
end

-- Example: Custom processing based on multiple conditions
if asset.type == "service" and asset.port and asset.service then
    if (asset.port == 80 or asset.port == 443) and asset.service == "http" then
        log("ANALYSIS: Web server found - consider directory enumeration")
    elseif asset.port == 22 and asset.service == "ssh" then
        log("ANALYSIS: SSH server found - consider brute force protection check")
    end
end

-- Example of using sleep function (be careful with this in production)
-- sleep(0.01)  -- Sleep for 10ms

log("Finished processing asset: " .. asset.value)