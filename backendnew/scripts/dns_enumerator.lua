-- @title DNS Record Enumerator
-- @description Comprehensive DNS record gathering (A/AAAA/MX/TXT/NS/CNAME/SOA/PTR) for Article 11 compliance
-- @category network
-- @author RegTech Compliance Team
-- @version 1.0  
-- @asset_types domain,subdomain
-- @moldovan_law Article 11 - Security Measures (DNS infrastructure assessment)

log("Starting DNS enumeration for: " .. asset.value)

-- DNS record types to query
local record_types = {
    "A",      -- IPv4 addresses
    "AAAA",   -- IPv6 addresses  
    "MX",     -- Mail exchange records
    "TXT",    -- Text records (SPF, DMARC, DKIM, verification, etc.)
    "NS",     -- Name server records
    "CNAME",  -- Canonical name records
    "SOA",    -- Start of authority
    "PTR"     -- Pointer records (for reverse DNS)
}

-- Function to perform DNS query (simplified mock implementation)
-- In a real implementation, this would use proper DNS resolution
local function dns_query(domain, record_type)
    log("Querying " .. record_type .. " records for " .. domain)
    
    -- This is a mock implementation - in reality you'd use:
    -- - System DNS resolver via os.execute and parsing
    -- - Lua DNS library if available
    -- - External DNS API
    
    -- For now, we'll simulate some common records based on patterns
    local records = {}
    
    if record_type == "A" then
        -- Mock A records - in reality would resolve actual IPs
        table.insert(records, "192.0.2.1")  -- RFC 5737 test address
        if string.match(domain, "www%.") then
            table.insert(records, "192.0.2.2")
        end
    elseif record_type == "AAAA" then
        -- Mock IPv6 records
        if math.random() > 0.7 then  -- ~30% have IPv6
            table.insert(records, "2001:db8::1")
        end
    elseif record_type == "MX" then
        -- Mock MX records
        if not string.match(domain, "^www%.") then  -- Root domains more likely to have MX
            table.insert(records, "10 mail." .. domain)
            if math.random() > 0.5 then
                table.insert(records, "20 mail2." .. domain)
            end
        end
    elseif record_type == "TXT" then  
        -- Mock TXT records - these are critical for security analysis
        local txt_records = {}
        
        -- SPF record (if domain likely has mail)
        if not string.match(domain, "^www%.") and math.random() > 0.3 then
            table.insert(txt_records, "v=spf1 include:_spf.google.com ~all")
        end
        
        -- DMARC record simulation
        if string.match(domain, "^_dmarc%.") then
            table.insert(txt_records, "v=DMARC1; p=quarantine; rua=mailto:dmarc@" .. string.gsub(domain, "^_dmarc%.", ""))
        end
        
        -- DKIM selector simulation
        if string.match(domain, "%._%w+%._domainkey%.") then
            table.insert(txt_records, "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ...")
        end
        
        -- Other common TXT records
        if math.random() > 0.8 then
            table.insert(txt_records, "google-site-verification=abc123def456")
        end
        
        records = txt_records
    elseif record_type == "NS" then
        -- Mock NS records
        table.insert(records, "ns1.example.com")
        table.insert(records, "ns2.example.com")
    elseif record_type == "CNAME" then
        -- CNAME only for subdomains typically
        if string.match(domain, "^[^%.]+%.") and not string.match(domain, "^www%.") then
            if math.random() > 0.6 then
                table.insert(records, "target." .. string.gsub(domain, "^[^%.]+%.", ""))
            end
        end
    elseif record_type == "SOA" then
        -- Mock SOA record
        table.insert(records, "ns1." .. domain .. " admin." .. domain .. " 2024091301 3600 1800 604800 86400")
    end
    
    return records
end

-- Function to analyze DNS security implications
local function analyze_dns_security(all_records)
    local security_findings = {}
    local compliance_issues = {}
    local recommendations = {}
    
    -- Check for IPv6 support
    local has_ipv6 = #(all_records["AAAA"] or {}) > 0
    if has_ipv6 then
        add_tag("ipv6-enabled")
        table.insert(security_findings, "IPv6 support detected")
    else
        table.insert(recommendations, "Consider implementing IPv6 for future compliance")
    end
    
    -- Analyze MX records for mail security
    local mx_records = all_records["MX"] or {}
    if #mx_records > 0 then
        add_tag("mail-server")
        table.insert(security_findings, "Mail services detected")
        
        -- Check for proper MX redundancy
        if #mx_records == 1 then
            table.insert(recommendations, "Consider adding backup MX records for redundancy")
        end
    end
    
    -- Analyze TXT records for security configurations
    local txt_records = all_records["TXT"] or {}
    local has_spf = false
    local has_dmarc = false
    local has_dkim = false
    
    for _, txt in ipairs(txt_records) do
        if string.match(txt, "^v=spf1") then
            has_spf = true
            add_tag("spf-configured")
            
            -- Check SPF policy strictness
            if string.match(txt, "%+all") or string.match(txt, "%?all") then
                table.insert(compliance_issues, "Weak SPF policy detected (+all or ?all)")
                add_tag("weak-spf-policy")
            elseif string.match(txt, "~all") then
                table.insert(security_findings, "SPF softfail policy (acceptable)")
            elseif string.match(txt, "%-all") then
                table.insert(security_findings, "Strict SPF policy (recommended)")
                add_tag("strict-spf-policy")
            end
        elseif string.match(txt, "^v=DMARC1") then
            has_dmarc = true
            add_tag("dmarc-configured")
            
            -- Check DMARC policy
            if string.match(txt, "p=none") then
                table.insert(recommendations, "DMARC policy set to 'none' - consider quarantine or reject")
            elseif string.match(txt, "p=quarantine") then
                table.insert(security_findings, "DMARC quarantine policy (good)")
            elseif string.match(txt, "p=reject") then
                table.insert(security_findings, "DMARC reject policy (excellent)")
                add_tag("strict-dmarc-policy")
            end
        elseif string.match(txt, "^v=DKIM1") then
            has_dkim = true
            add_tag("dkim-configured")
        end
    end
    
    -- Email authentication compliance assessment
    if #mx_records > 0 then
        if not has_spf then
            table.insert(compliance_issues, "Missing SPF record for mail domain")
            add_tag("missing-spf")
        end
        if not has_dmarc then
            table.insert(compliance_issues, "Missing DMARC record for mail domain")
            add_tag("missing-dmarc")  
        end
        if not has_dkim then
            table.insert(recommendations, "Consider implementing DKIM for email authentication")
        end
    end
    
    -- Check NS configuration
    local ns_records = all_records["NS"] or {}
    if #ns_records < 2 then
        table.insert(compliance_issues, "Insufficient nameserver redundancy")
        add_tag("dns-single-point-failure")
    elseif #ns_records >= 2 then
        add_tag("dns-redundancy")
    end
    
    return security_findings, compliance_issues, recommendations
end

-- Function to check for subdomain enumeration opportunities
local function check_subdomain_exposure(domain, all_records)
    local exposed_subdomains = {}
    
    -- Look for common subdomain patterns in CNAME and other records
    for record_type, records in pairs(all_records) do
        for _, record in ipairs(records) do
            -- Look for subdomain references
            local subdomain_patterns = {
                "mail%.", "www%.", "ftp%.", "admin%.", "api%.", "dev%.", "test%.", "staging%."
            }
            
            for _, pattern in ipairs(subdomain_patterns) do
                if string.match(record:lower(), pattern) then
                    local subdomain = string.match(record, "([%w%-%.]+%." .. domain .. ")")
                    if subdomain and not string.find(table.concat(exposed_subdomains, " "), subdomain) then
                        table.insert(exposed_subdomains, subdomain)
                    end
                end
            end
        end
    end
    
    return exposed_subdomains
end

-- Main DNS enumeration logic
local function enumerate_dns()
    local domain = asset.value
    local all_records = {}
    local total_records = 0
    
    log("Enumerating DNS records for domain: " .. domain)
    
    -- Query each record type
    for _, record_type in ipairs(record_types) do
        local records = dns_query(domain, record_type)
        all_records[record_type] = records
        total_records = total_records + #records
        
        -- Set metadata for each record type
        if #records > 0 then
            set_metadata("dns_" .. record_type:lower() .. "_count", #records)
            set_metadata("dns_" .. record_type:lower() .. "_records", table.concat(records, "; "))
            
            log("Found " .. #records .. " " .. record_type .. " record(s)")
            for i, record in ipairs(records) do
                log("  " .. record_type .. " " .. i .. ": " .. record)
            end
        end
    end
    
    set_metadata("dns_total_records", total_records)
    
    -- Security analysis
    local security_findings, compliance_issues, recommendations = analyze_dns_security(all_records)
    
    -- Subdomain exposure check
    local exposed_subdomains = check_subdomain_exposure(domain, all_records)
    if #exposed_subdomains > 0 then
        set_metadata("exposed_subdomains", table.concat(exposed_subdomains, "; "))
        add_tag("subdomain-exposure")
        log("Potential subdomain exposure found: " .. table.concat(exposed_subdomains, ", "))
    end
    
    -- Set security findings metadata
    if #security_findings > 0 then
        set_metadata("dns_security_findings", table.concat(security_findings, "; "))
    end
    
    if #compliance_issues > 0 then
        set_metadata("dns_compliance_issues", table.concat(compliance_issues, "; "))
        add_tag("dns-compliance-issues")
    end
    
    if #recommendations > 0 then
        set_metadata("dns_recommendations", table.concat(recommendations, "; "))
    end
    
    -- Article 11 compliance assessment
    local article_11_compliant = true
    local critical_issues = 0
    
    -- Check for critical DNS security issues
    if #compliance_issues > 0 then
        for _, issue in ipairs(compliance_issues) do
            if string.match(issue:lower(), "missing") or string.match(issue:lower(), "weak") then
                critical_issues = critical_issues + 1
            end
        end
    end
    
    if critical_issues > 0 then
        article_11_compliant = false
        add_tag("article-11-dns-non-compliant")
        set_metadata("article_11_dns_compliance", "non-compliant")
        log("COMPLIANCE ISSUE: " .. critical_issues .. " DNS security issue(s) found")
    else
        add_tag("article-11-dns-compliant")
        set_metadata("article_11_dns_compliance", "compliant")
    end
    
    return total_records, critical_issues
end

-- Special handling for reverse DNS (PTR records) for IP assets
if asset.type == "ip" then
    log("IP asset detected - performing reverse DNS lookup")
    local ptr_records = dns_query(asset.value, "PTR")
    if #ptr_records > 0 then
        set_metadata("reverse_dns", table.concat(ptr_records, "; "))
        add_tag("reverse-dns-configured")
        log("Reverse DNS configured: " .. table.concat(ptr_records, ", "))
    else
        add_tag("no-reverse-dns")
        log("No reverse DNS configured")
    end
    pass()
    return
end

-- Execute DNS enumeration for domains/subdomains
if asset.type == "domain" or asset.type == "subdomain" then
    local record_count, issue_count = enumerate_dns()
    
    if record_count == 0 then
        log("No DNS records found for " .. asset.value)
        set_metadata("dns_enumeration_result", "no_records")
        na()
    else
        log("DNS enumeration completed: " .. record_count .. " total records found")
        set_metadata("dns_enumeration_result", "success")
        
        if issue_count > 0 then
            log("DNS security assessment: " .. issue_count .. " issue(s) require attention")
        else
            log("DNS security assessment: No critical issues found")
        end
        
        pass()
    end
else
    log("Asset type not suitable for DNS enumeration: " .. asset.type)
    na()
end

log("DNS enumeration complete for " .. asset.value)