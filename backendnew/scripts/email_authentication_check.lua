-- @title Email Authentication Analysis (Article 11 Compliance)
-- @description Validates SPF, DKIM, and DMARC records for email security in compliance with Moldovan Cybersecurity Law Article 11 (Security Measures)
-- @category Email Security
-- @compliance_article Article 11 - Security Measures
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types domain,subdomain
-- @requires_passed basic_info.lua

-- Only run on domain assets
if asset.type ~= "domain" and asset.type ~= "subdomain" then
    log("Skipping email authentication check - not a domain asset")
    return
end

-- Extract domain name
local domain = asset.value
log("Analyzing email authentication for domain: " .. domain)

-- Email authentication records configuration
local email_auth_records = {
    spf = {
        name = "SPF (Sender Policy Framework)",
        record_type = "TXT",
        lookup_domain = domain,
        score = 3,
        required = true,
        description = "Prevents email spoofing by specifying authorized mail servers"
    },
    dmarc = {
        name = "DMARC (Domain-based Message Authentication)",
        record_type = "TXT", 
        lookup_domain = "_dmarc." .. domain,
        score = 4,
        required = true,
        description = "Provides email authentication policy and reporting"
    },
    dkim = {
        name = "DKIM (DomainKeys Identified Mail)",
        record_type = "TXT",
        lookup_domain = "selector._domainkey." .. domain, -- We'll try common selectors
        score = 3,
        required = false, -- DKIM selectors are harder to discover without prior knowledge
        description = "Provides email message integrity and authenticity"
    }
}

-- Common DKIM selectors to check
local common_dkim_selectors = {
    "default", "google", "k1", "s1", "s2", "mail", "email", 
    "selector1", "selector2", "dkim", "key1", "key2"
}

-- Function to perform DNS lookup
local function dns_lookup(lookup_domain, record_type)
    log("Looking up " .. record_type .. " record for: " .. lookup_domain)
    
    -- Use a simple HTTP-based DNS lookup since we don't have direct DNS access
    -- This is a simplified approach - in production you'd want proper DNS resolution
    local lookup_url = "https://dns.google/resolve?name=" .. lookup_domain .. "&type=" .. record_type
    
    local status, body, headers, err = http.get(lookup_url, {
        ["Accept"] = "application/dns-json"
    }, 10)
    
    if err then
        log("DNS lookup failed for " .. lookup_domain .. ": " .. err)
        return false, err, nil
    end
    
    if status ~= 200 then
        log("DNS lookup returned status " .. status .. " for " .. lookup_domain)
        return false, "HTTP " .. status, nil
    end
    
    -- Parse JSON response (simplified parsing)
    local records = {}
    
    -- Look for TXT records in the response
    if string.match(body, '"Status":0') then
        -- Extract TXT record data
        for record_data in string.gmatch(body, '"data":"([^"]+)"') do
            table.insert(records, record_data)
            log("Found DNS record: " .. record_data)
        end
    end
    
    return true, nil, records
end

-- Function to analyze SPF record
local function analyze_spf_record(spf_record)
    local analysis = {
        valid = false,
        version = nil,
        mechanisms = {},
        qualifiers = {},
        issues = {},
        score_multiplier = 1.0
    }
    
    -- Check SPF version
    if string.match(spf_record, "^v=spf1") then
        analysis.valid = true
        analysis.version = "spf1"
        log("Valid SPF record version found")
    else
        table.insert(analysis.issues, "Invalid or missing SPF version")
        analysis.score_multiplier = 0.2
        return analysis
    end
    
    -- Extract mechanisms
    for mechanism in string.gmatch(spf_record, "([%w%+%-~%.:/]+)") do
        if mechanism ~= "v=spf1" then
            table.insert(analysis.mechanisms, mechanism)
        end
    end
    
    -- Analyze common SPF elements
    local has_all = false
    local has_include = false
    local has_ip = false
    
    for _, mechanism in ipairs(analysis.mechanisms) do
        if string.match(mechanism, "^[%+%-~]?all$") then
            has_all = true
            if string.match(mechanism, "^%-all$") then
                log("SPF has hard fail policy (-all)")
            elseif string.match(mechanism, "^~all$") then
                log("SPF has soft fail policy (~all)")
                analysis.score_multiplier = analysis.score_multiplier * 0.9
            elseif string.match(mechanism, "^%+?all$") then
                table.insert(analysis.issues, "SPF allows all senders (+all)")
                analysis.score_multiplier = analysis.score_multiplier * 0.3
            end
            
        elseif string.match(mechanism, "^include:") then
            has_include = true
            log("SPF includes external domains")
            
        elseif string.match(mechanism, "^ip[46]:") or string.match(mechanism, "^a:") or string.match(mechanism, "^mx") then
            has_ip = true
            log("SPF specifies authorized servers")
        end
    end
    
    if not has_all then
        table.insert(analysis.issues, "SPF missing 'all' mechanism")
        analysis.score_multiplier = analysis.score_multiplier * 0.7
    end
    
    if not (has_include or has_ip) then
        table.insert(analysis.issues, "SPF doesn't specify any mail servers")
        analysis.score_multiplier = analysis.score_multiplier * 0.5
    end
    
    -- Check for too many DNS lookups (RFC limit is 10)
    local include_count = 0
    for _, mechanism in ipairs(analysis.mechanisms) do
        if string.match(mechanism, "^include:") then
            include_count = include_count + 1
        end
    end
    
    if include_count > 8 then
        table.insert(analysis.issues, "SPF may exceed DNS lookup limit")
        analysis.score_multiplier = analysis.score_multiplier * 0.8
    end
    
    return analysis
end

-- Function to analyze DMARC record
local function analyze_dmarc_record(dmarc_record)
    local analysis = {
        valid = false,
        version = nil,
        policy = nil,
        subdomain_policy = nil,
        percentage = nil,
        alignment = {},
        issues = {},
        score_multiplier = 1.0
    }
    
    -- Check DMARC version
    if string.match(dmarc_record, "v=DMARC1") then
        analysis.valid = true
        analysis.version = "DMARC1"
        log("Valid DMARC record version found")
    else
        table.insert(analysis.issues, "Invalid or missing DMARC version")
        analysis.score_multiplier = 0.2
        return analysis
    end
    
    -- Extract policy
    local policy = string.match(dmarc_record, "p=([^;]+)")
    if policy then
        analysis.policy = policy
        if policy == "reject" then
            log("DMARC policy: reject (strongest)")
        elseif policy == "quarantine" then
            log("DMARC policy: quarantine (moderate)")
            analysis.score_multiplier = analysis.score_multiplier * 0.9
        elseif policy == "none" then
            log("DMARC policy: none (monitoring only)")
            analysis.score_multiplier = analysis.score_multiplier * 0.6
        end
    else
        table.insert(analysis.issues, "DMARC missing policy")
        analysis.score_multiplier = analysis.score_multiplier * 0.4
    end
    
    -- Extract subdomain policy
    local sp = string.match(dmarc_record, "sp=([^;]+)")
    if sp then
        analysis.subdomain_policy = sp
        log("DMARC subdomain policy: " .. sp)
    end
    
    -- Extract percentage
    local pct = string.match(dmarc_record, "pct=([^;]+)")
    if pct then
        analysis.percentage = tonumber(pct)
        if analysis.percentage < 100 then
            log("DMARC percentage: " .. pct .. "% (gradual deployment)")
            if analysis.percentage < 50 then
                analysis.score_multiplier = analysis.score_multiplier * 0.8
            end
        end
    else
        analysis.percentage = 100 -- Default is 100%
    end
    
    -- Check for reporting addresses
    local has_rua = string.match(dmarc_record, "rua=")
    local has_ruf = string.match(dmarc_record, "ruf=")
    
    if has_rua then
        log("DMARC has aggregate reporting configured")
    else
        table.insert(analysis.issues, "DMARC missing aggregate reporting (rua)")
        analysis.score_multiplier = analysis.score_multiplier * 0.9
    end
    
    if has_ruf then
        log("DMARC has forensic reporting configured")
    end
    
    -- Check alignment modes
    local aspf = string.match(dmarc_record, "aspf=([^;]+)")
    local adkim = string.match(dmarc_record, "adkim=([^;]+)")
    
    analysis.alignment.spf = aspf or "r" -- Default is relaxed
    analysis.alignment.dkim = adkim or "r" -- Default is relaxed
    
    if aspf == "s" then
        log("DMARC SPF alignment: strict")
    end
    
    if adkim == "s" then
        log("DMARC DKIM alignment: strict")
    end
    
    return analysis
end

-- Function to analyze DKIM record
local function analyze_dkim_record(dkim_record)
    local analysis = {
        valid = false,
        version = nil,
        key_type = nil,
        hash_algorithm = nil,
        public_key = nil,
        issues = {},
        score_multiplier = 1.0
    }
    
    -- Check DKIM version
    if string.match(dkim_record, "v=DKIM1") then
        analysis.valid = true
        analysis.version = "DKIM1"
        log("Valid DKIM record version found")
    else
        table.insert(analysis.issues, "Invalid or missing DKIM version")
        analysis.score_multiplier = 0.2
        return analysis
    end
    
    -- Extract key type
    local k = string.match(dkim_record, "k=([^;]+)")
    if k then
        analysis.key_type = k
        if k == "rsa" then
            log("DKIM key type: RSA")
        elseif k == "ed25519" then
            log("DKIM key type: Ed25519 (modern)")
        end
    else
        analysis.key_type = "rsa" -- Default
    end
    
    -- Extract hash algorithms
    local h = string.match(dkim_record, "h=([^;]+)")
    if h then
        analysis.hash_algorithm = h
        if string.match(h, "sha256") then
            log("DKIM supports SHA-256")
        else
            table.insert(analysis.issues, "DKIM should support SHA-256")
            analysis.score_multiplier = analysis.score_multiplier * 0.8
        end
    end
    
    -- Check for public key
    local p = string.match(dkim_record, "p=([^;]+)")
    if p and p ~= "" then
        analysis.public_key = p
        log("DKIM public key present")
        
        -- Basic key length check for RSA keys
        if analysis.key_type == "rsa" then
            local key_length = string.len(p)
            if key_length < 200 then -- Rough estimate for 1024-bit keys
                table.insert(analysis.issues, "DKIM RSA key may be too short")
                analysis.score_multiplier = analysis.score_multiplier * 0.7
            end
        end
    else
        table.insert(analysis.issues, "DKIM missing or revoked public key")
        analysis.score_multiplier = 0.1
    end
    
    return analysis
end

-- Main analysis function
local function analyze_email_authentication()
    local results = {
        domain = domain,
        spf = { found = false, records = {}, analysis = nil },
        dmarc = { found = false, records = {}, analysis = nil },
        dkim = { found = false, records = {}, analysis = nil, selectors_checked = {} },
        total_score = 0,
        max_possible_score = 10, -- SPF(3) + DMARC(4) + DKIM(3)
        compliance_issues = {}
    }
    
    -- Check SPF record
    log("Checking SPF record for " .. domain)
    local spf_ok, spf_err, spf_records = dns_lookup(domain, "TXT")
    
    if spf_ok and spf_records then
        for _, record in ipairs(spf_records) do
            if string.match(record, "^v=spf1") then
                results.spf.found = true
                table.insert(results.spf.records, record)
                results.spf.analysis = analyze_spf_record(record)
                
                results.total_score = results.total_score + (3 * results.spf.analysis.score_multiplier)
                
                for _, issue in ipairs(results.spf.analysis.issues) do
                    table.insert(results.compliance_issues, "SPF: " .. issue)
                end
                
                break -- Use first SPF record found
            end
        end
    end
    
    if not results.spf.found then
        table.insert(results.compliance_issues, "SPF record not found")
        log("No SPF record found for " .. domain)
    end
    
    -- Check DMARC record
    log("Checking DMARC record for _dmarc." .. domain)
    local dmarc_ok, dmarc_err, dmarc_records = dns_lookup("_dmarc." .. domain, "TXT")
    
    if dmarc_ok and dmarc_records then
        for _, record in ipairs(dmarc_records) do
            if string.match(record, "v=DMARC1") then
                results.dmarc.found = true
                table.insert(results.dmarc.records, record)
                results.dmarc.analysis = analyze_dmarc_record(record)
                
                results.total_score = results.total_score + (4 * results.dmarc.analysis.score_multiplier)
                
                for _, issue in ipairs(results.dmarc.analysis.issues) do
                    table.insert(results.compliance_issues, "DMARC: " .. issue)
                end
                
                break -- Use first DMARC record found
            end
        end
    end
    
    if not results.dmarc.found then
        table.insert(results.compliance_issues, "DMARC record not found")
        log("No DMARC record found for _dmarc." .. domain)
    end
    
    -- Check DKIM records (try common selectors)
    log("Checking DKIM records with common selectors")
    for _, selector in ipairs(common_dkim_selectors) do
        local dkim_domain = selector .. "._domainkey." .. domain
        table.insert(results.dkim.selectors_checked, selector)
        
        local dkim_ok, dkim_err, dkim_records = dns_lookup(dkim_domain, "TXT")
        
        if dkim_ok and dkim_records then
            for _, record in ipairs(dkim_records) do
                if string.match(record, "v=DKIM1") or string.match(record, "p=") then
                    results.dkim.found = true
                    table.insert(results.dkim.records, record)
                    results.dkim.analysis = analyze_dkim_record(record)
                    
                    results.total_score = results.total_score + (3 * results.dkim.analysis.score_multiplier)
                    
                    for _, issue in ipairs(results.dkim.analysis.issues) do
                        table.insert(results.compliance_issues, "DKIM: " .. issue)
                    end
                    
                    log("Found DKIM record for selector: " .. selector)
                    break -- Use first valid DKIM record found
                end
            end
            
            if results.dkim.found then
                break -- Stop checking selectors once we find one
            end
        end
    end
    
    if not results.dkim.found then
        table.insert(results.compliance_issues, "DKIM record not found (checked common selectors)")
        log("No DKIM records found for common selectors")
    end
    
    return results
end

-- Perform email authentication analysis
log("Starting email authentication analysis for: " .. domain)
local email_results = analyze_email_authentication()

-- Set comprehensive metadata
set_metadata("email_auth.domain", email_results.domain)
set_metadata("email_auth.total_score", email_results.total_score)
set_metadata("email_auth.max_possible_score", email_results.max_possible_score)

-- Calculate compliance percentage
local compliance_percentage = 0
if email_results.max_possible_score > 0 then
    compliance_percentage = math.floor((email_results.total_score / email_results.max_possible_score) * 100)
end
set_metadata("email_auth.compliance_percentage", compliance_percentage)

-- SPF metadata
set_metadata("email_auth.spf.found", email_results.spf.found)
if email_results.spf.found then
    set_metadata("email_auth.spf.record", email_results.spf.records[1])
    if email_results.spf.analysis then
        set_metadata("email_auth.spf.valid", email_results.spf.analysis.valid)
        set_metadata("email_auth.spf.score_multiplier", email_results.spf.analysis.score_multiplier)
        if #email_results.spf.analysis.issues > 0 then
            set_metadata("email_auth.spf.issues", table.concat(email_results.spf.analysis.issues, "; "))
        end
    end
end

-- DMARC metadata
set_metadata("email_auth.dmarc.found", email_results.dmarc.found)
if email_results.dmarc.found then
    set_metadata("email_auth.dmarc.record", email_results.dmarc.records[1])
    if email_results.dmarc.analysis then
        set_metadata("email_auth.dmarc.valid", email_results.dmarc.analysis.valid)
        set_metadata("email_auth.dmarc.policy", email_results.dmarc.analysis.policy)
        set_metadata("email_auth.dmarc.percentage", email_results.dmarc.analysis.percentage)
        set_metadata("email_auth.dmarc.score_multiplier", email_results.dmarc.analysis.score_multiplier)
        if #email_results.dmarc.analysis.issues > 0 then
            set_metadata("email_auth.dmarc.issues", table.concat(email_results.dmarc.analysis.issues, "; "))
        end
    end
end

-- DKIM metadata
set_metadata("email_auth.dkim.found", email_results.dkim.found)
set_metadata("email_auth.dkim.selectors_checked", table.concat(email_results.dkim.selectors_checked, ", "))
if email_results.dkim.found then
    set_metadata("email_auth.dkim.record", email_results.dkim.records[1])
    if email_results.dkim.analysis then
        set_metadata("email_auth.dkim.valid", email_results.dkim.analysis.valid)
        set_metadata("email_auth.dkim.key_type", email_results.dkim.analysis.key_type)
        set_metadata("email_auth.dkim.score_multiplier", email_results.dkim.analysis.score_multiplier)
        if #email_results.dkim.analysis.issues > 0 then
            set_metadata("email_auth.dkim.issues", table.concat(email_results.dkim.analysis.issues, "; "))
        end
    end
end

-- Set compliance issues
if #email_results.compliance_issues > 0 then
    set_metadata("email_auth.compliance_issues", table.concat(email_results.compliance_issues, "; "))
end

log("Email authentication score: " .. email_results.total_score .. "/" .. email_results.max_possible_score .. " (" .. compliance_percentage .. "%)")

-- Determine compliance status for Moldovan Cybersecurity Law Article 11
local compliance_level = "insufficient"
local compliance_status = "fail"
local required_records_found = 0

-- Count required records
if email_results.spf.found then required_records_found = required_records_found + 1 end
if email_results.dmarc.found then required_records_found = required_records_found + 1 end

-- Evaluate compliance level
if compliance_percentage >= 90 and required_records_found >= 2 and email_results.dmarc.found then
    compliance_level = "excellent"
    compliance_status = "pass"
    log("Excellent email authentication configuration")
    
elseif compliance_percentage >= 75 and required_records_found >= 2 then
    compliance_level = "good" 
    compliance_status = "pass"
    log("Good email authentication configuration")
    
elseif compliance_percentage >= 60 and required_records_found >= 1 then
    compliance_level = "acceptable"
    compliance_status = "conditional"
    log("Acceptable email authentication configuration with issues")
    
elseif required_records_found >= 1 then
    compliance_level = "minimal"
    compliance_status = "conditional"
    log("Minimal email authentication configuration")
    
else
    compliance_level = "insufficient"
    compliance_status = "fail"
    log("Insufficient email authentication configuration")
end

set_metadata("email_auth.compliance_level", compliance_level)
set_metadata("email_auth.compliance_status", compliance_status)
set_metadata("email_auth.required_records_found", required_records_found)

-- Update compliance checklists based on results
if compliance_status == "pass" then
    local pass_message = compliance_level:gsub("^%l", string.upper) .. " email authentication"
    pass_message = pass_message .. " (" .. compliance_percentage .. "% compliance)"
    
    pass_checklist("email-security-authentication-014", pass_message)
    pass_checklist("email-spoofing-prevention-020", "Email spoofing protection enabled")
    
    log("Email authentication compliance: PASS - " .. compliance_level)
    pass()
    
elseif compliance_status == "conditional" then
    local conditional_message = "Email authentication partially configured"
    if #email_results.compliance_issues > 0 then
        conditional_message = conditional_message .. ": " .. table.concat(email_results.compliance_issues, "; ")
    end
    conditional_message = conditional_message .. " (" .. compliance_percentage .. "% compliance)"
    
    pass_checklist("email-security-authentication-014", conditional_message)
    fail_checklist("email-spoofing-prevention-020", "Email authentication incomplete")
    
    log("Email authentication compliance: CONDITIONAL - " .. conditional_message)
    pass()
    
else
    local fail_message = "Email authentication insufficient or missing"
    if #email_results.compliance_issues > 0 then
        fail_message = fail_message .. ": " .. table.concat(email_results.compliance_issues, "; ")
    end
    fail_message = fail_message .. " (" .. compliance_percentage .. "% compliance)"
    
    fail_checklist("email-security-authentication-014", fail_message)
    fail_checklist("email-spoofing-prevention-020", "Email authentication not configured")
    
    log("Email authentication compliance: FAIL - " .. fail_message)
    reject("Email authentication insufficient")
end

-- Add descriptive tags
if compliance_level == "excellent" then
    add_tag("excellent-email-auth")
elseif compliance_level == "good" then
    add_tag("good-email-auth")
elseif compliance_level == "acceptable" or compliance_level == "minimal" then
    add_tag("basic-email-auth")
else
    add_tag("weak-email-auth")
end

-- Add specific record tags
if email_results.spf.found then
    add_tag("has-spf")
    if email_results.spf.analysis and email_results.spf.analysis.valid then
        add_tag("valid-spf")
    end
end

if email_results.dmarc.found then
    add_tag("has-dmarc")
    if email_results.dmarc.analysis and email_results.dmarc.analysis.valid then
        add_tag("valid-dmarc")
        if email_results.dmarc.analysis.policy == "reject" then
            add_tag("dmarc-reject-policy")
        elseif email_results.dmarc.analysis.policy == "quarantine" then
            add_tag("dmarc-quarantine-policy")
        end
    end
end

if email_results.dkim.found then
    add_tag("has-dkim")
    if email_results.dkim.analysis and email_results.dkim.analysis.valid then
        add_tag("valid-dkim")
    end
end

-- Add issue tags
if #email_results.compliance_issues > 0 then
    add_tag("email-auth-issues")
end

if required_records_found == 0 then
    add_tag("no-email-auth")
elseif required_records_found < 2 then
    add_tag("incomplete-email-auth")
end

log("Email authentication analysis completed for: " .. domain)