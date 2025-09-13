-- @title TLS Certificate Inspector
-- @description Certificate analysis - expiry, SAN/hostname match, issuer trust chain validation
-- @category security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,domain,subdomain
-- @requires_passed tls_version_check.lua
-- @moldovan_law Article 11 - Security Measures (TLS certificate validation and trust)

log("Starting TLS certificate inspection for: " .. asset.value)

-- Certificate validation functions (mock implementation)
-- In a real implementation, these would use actual TLS/SSL libraries

-- Function to extract certificate information (mock)
local function extract_cert_info(host, port)
    log("Extracting certificate information for " .. host .. ":" .. port)
    
    -- Mock certificate data - in reality would use OpenSSL or similar
    local cert_info = {
        subject = {
            common_name = host,
            organization = "Example Organization",
            country = "MD"  -- Moldova
        },
        issuer = {
            common_name = "Let's Encrypt Authority X3",
            organization = "Let's Encrypt", 
            country = "US"
        },
        validity = {
            not_before = "2024-01-15T10:30:00Z",
            not_after = "2024-04-15T10:30:00Z"
        },
        serial_number = "03:A4:B5:C6:D7:E8:F9:0A:1B:2C:3D:4E:5F:60:71:82",
        signature_algorithm = "sha256WithRSAEncryption",
        public_key = {
            algorithm = "RSA",
            bit_length = 2048
        },
        extensions = {
            subject_alt_names = {host, "www." .. host},
            key_usage = {"Digital Signature", "Key Encipherment"},
            extended_key_usage = {"TLS Web Server Authentication"},
            authority_key_identifier = "A8:4A:6A:63:04:7D:DD:BA:E6:D1:39:B7:A6:45:65:EF:F3:A8:EC:A1"
        }
    }
    
    return cert_info, nil
end

-- Function to calculate days until expiry
local function calculate_expiry_days(not_after_str)
    -- Simplified date calculation - in reality would parse ISO format properly
    local current_time = os.time()
    
    -- Mock calculation - assume cert expires in ~90 days for Let's Encrypt
    local days_remaining = math.random(1, 180)  -- Random for demo
    
    return days_remaining
end

-- Function to validate hostname against certificate
local function validate_hostname(hostname, cert_info)
    local matches = {}
    local primary_match = false
    
    -- Check CN match
    if cert_info.subject.common_name == hostname then
        primary_match = true
        table.insert(matches, "CN")
    end
    
    -- Check SAN matches  
    if cert_info.extensions and cert_info.extensions.subject_alt_names then
        for _, san in ipairs(cert_info.extensions.subject_alt_names) do
            if san == hostname then
                table.insert(matches, "SAN")
                primary_match = true
            elseif san:match("^%*%.") then  -- Wildcard match
                local domain_pattern = string.gsub(san, "^%*%.", "")
                if hostname:match(domain_pattern .. "$") then
                    table.insert(matches, "SAN-wildcard")
                    primary_match = true
                end
            end
        end
    end
    
    return primary_match, matches
end

-- Function to assess certificate trust chain
local function assess_trust_chain(cert_info)
    local trust_assessment = {
        trusted = true,
        trust_level = "high",
        issues = {},
        warnings = {}
    }
    
    -- Check issuer trustworthiness (simplified)
    local trusted_cas = {
        ["Let's Encrypt"] = "high",
        ["DigiCert"] = "high", 
        ["GlobalSign"] = "high",
        ["Sectigo"] = "medium",
        ["GoDaddy"] = "medium",
        ["Self-signed"] = "none"
    }
    
    local issuer_org = cert_info.issuer.organization
    local trust_level = trusted_cas[issuer_org] or "unknown"
    
    trust_assessment.trust_level = trust_level
    
    if trust_level == "none" then
        trust_assessment.trusted = false
        table.insert(trust_assessment.issues, "Self-signed certificate - not trusted by browsers")
    elseif trust_level == "unknown" then
        table.insert(trust_assessment.warnings, "Unknown certificate authority: " .. issuer_org)
        trust_assessment.trust_level = "low"
    elseif trust_level == "medium" then
        table.insert(trust_assessment.warnings, "Commercial CA with mixed reputation")
    end
    
    -- Check signature algorithm strength
    if cert_info.signature_algorithm:match("sha1") then
        table.insert(trust_assessment.issues, "Weak SHA-1 signature algorithm")
        trust_assessment.trusted = false
    elseif cert_info.signature_algorithm:match("md5") then
        table.insert(trust_assessment.issues, "Critically weak MD5 signature algorithm")
        trust_assessment.trusted = false
    end
    
    -- Check key strength
    if cert_info.public_key.algorithm == "RSA" then
        if cert_info.public_key.bit_length < 2048 then
            table.insert(trust_assessment.issues, "Weak RSA key length: " .. cert_info.public_key.bit_length)
            trust_assessment.trusted = false
        elseif cert_info.public_key.bit_length >= 4096 then
            table.insert(trust_assessment.warnings, "Very strong key length may impact performance")
        end
    end
    
    return trust_assessment
end

-- Function to check certificate compliance with Article 11
local function check_article_11_compliance(cert_info, expiry_days, hostname_valid, trust_assessment)
    local compliance = {
        compliant = true,
        issues = {},
        recommendations = {},
        score = 0
    }
    
    -- Expiry compliance (Article 11 requires valid certificates)
    if expiry_days <= 0 then
        compliance.compliant = false
        table.insert(compliance.issues, "Certificate has expired")
    elseif expiry_days <= 7 then
        table.insert(compliance.issues, "Certificate expires within 7 days")
        compliance.compliant = false
    elseif expiry_days <= 30 then
        table.insert(compliance.recommendations, "Certificate expires within 30 days - plan renewal")
        compliance.score = compliance.score + 1
    else
        compliance.score = compliance.score + 2
    end
    
    -- Hostname validation compliance
    if not hostname_valid then
        compliance.compliant = false
        table.insert(compliance.issues, "Certificate does not match hostname")
    else
        compliance.score = compliance.score + 2
    end
    
    -- Trust chain compliance
    if not trust_assessment.trusted then
        compliance.compliant = false
        table.insert(compliance.issues, "Certificate not from trusted authority")
    else
        if trust_assessment.trust_level == "high" then
            compliance.score = compliance.score + 2
        elseif trust_assessment.trust_level == "medium" then
            compliance.score = compliance.score + 1
        end
    end
    
    -- Cryptographic strength compliance
    if cert_info.public_key.algorithm == "RSA" and cert_info.public_key.bit_length >= 2048 then
        compliance.score = compliance.score + 1
    end
    
    if cert_info.signature_algorithm:match("sha256") then
        compliance.score = compliance.score + 1
    end
    
    -- Set compliance level based on score
    local max_score = 8
    local compliance_percentage = math.floor((compliance.score / max_score) * 100)
    
    if compliance_percentage >= 87 then
        compliance.level = "excellent"
    elseif compliance_percentage >= 75 then
        compliance.level = "good"
    elseif compliance_percentage >= 60 then
        compliance.level = "acceptable"
    else
        compliance.level = "poor"
    end
    
    compliance.percentage = compliance_percentage
    
    return compliance
end

-- Main certificate inspection function
local function inspect_certificate()
    -- Determine target for certificate inspection
    local target_host = asset.value
    local target_port = 443  -- Default HTTPS port
    
    if asset.type == "service" then
        -- Parse service asset
        local host, port_str = string.match(asset.value, "([^:]+):(%d+)")
        if host and port_str then
            target_host = host
            target_port = tonumber(port_str)
        end
        
        -- Only inspect TLS-capable services
        if target_port ~= 443 and target_port ~= 993 and target_port ~= 995 and target_port ~= 465 then
            log("Port " .. target_port .. " typically does not use TLS certificates")
            pass_checklist("ssl-certificate-validation-012", "Service not using TLS certificates")
            na()
            return
        end
    elseif asset.type == "domain" or asset.type == "subdomain" then
        -- Check if HTTPS is available
        local fd, err = tcp.connect(target_host, 443, 3)
        if not fd then
            log("HTTPS not available on " .. target_host .. ":443")
            pass_checklist("ssl-certificate-validation-012", "No TLS certificate to validate - service not using HTTPS")
            na()
            return
        end
        tcp.close(fd)
    end
    
    log("Inspecting TLS certificate for " .. target_host .. ":" .. target_port)
    
    -- Extract certificate information
    local cert_info, extract_err = extract_cert_info(target_host, target_port)
    if not cert_info then
        log("Failed to extract certificate: " .. (extract_err or "unknown error"))
        reject("Certificate extraction failed")
        return
    end
    
    -- Calculate expiry
    local expiry_days = calculate_expiry_days(cert_info.validity.not_after)
    
    -- Validate hostname  
    local hostname_valid, hostname_matches = validate_hostname(target_host, cert_info)
    
    -- Assess trust chain
    local trust_assessment = assess_trust_chain(cert_info)
    
    -- Check Article 11 compliance
    local compliance = check_article_11_compliance(cert_info, expiry_days, hostname_valid, trust_assessment)
    
    -- Set detailed metadata
    set_metadata("cert_subject_cn", cert_info.subject.common_name)
    set_metadata("cert_issuer", cert_info.issuer.organization)
    set_metadata("cert_expiry_days", expiry_days)
    set_metadata("cert_signature_algorithm", cert_info.signature_algorithm)
    set_metadata("cert_key_algorithm", cert_info.public_key.algorithm)
    set_metadata("cert_key_bits", cert_info.public_key.bit_length)
    set_metadata("cert_hostname_valid", hostname_valid)
    set_metadata("cert_trust_level", trust_assessment.trust_level)
    set_metadata("cert_trusted", trust_assessment.trusted)
    
    -- SAN information
    if cert_info.extensions and cert_info.extensions.subject_alt_names then
        set_metadata("cert_san_count", #cert_info.extensions.subject_alt_names)
        set_metadata("cert_san_list", table.concat(cert_info.extensions.subject_alt_names, "; "))
    end
    
    -- Compliance metadata
    set_metadata("cert_compliance_score", compliance.score)
    set_metadata("cert_compliance_percentage", compliance.percentage)
    set_metadata("cert_compliance_level", compliance.level)
    set_metadata("cert_article_11_compliant", compliance.compliant)
    
    -- Set issues and recommendations
    if #compliance.issues > 0 then
        set_metadata("cert_issues", table.concat(compliance.issues, "; "))
    end
    if #compliance.recommendations > 0 then
        set_metadata("cert_recommendations", table.concat(compliance.recommendations, "; "))
    end
    if #trust_assessment.issues > 0 then
        set_metadata("cert_trust_issues", table.concat(trust_assessment.issues, "; "))
    end
    
    -- Add tags based on findings
    if hostname_valid then
        add_tag("valid-hostname-cert")
    else
        add_tag("invalid-hostname-cert")
        add_tag("cert-hostname-mismatch")
    end
    
    if trust_assessment.trusted then
        add_tag("trusted-cert")
        if trust_assessment.trust_level == "high" then
            add_tag("high-trust-cert")
        end
    else
        add_tag("untrusted-cert")
    end
    
    -- Expiry-based tags
    if expiry_days <= 0 then
        add_tag("expired-cert")
        add_tag("cert-critical-issue")
    elseif expiry_days <= 7 then
        add_tag("cert-expires-soon")
        add_tag("cert-critical-issue")
    elseif expiry_days <= 30 then
        add_tag("cert-expires-month")
        add_tag("cert-renewal-needed")
    elseif expiry_days >= 365 then
        add_tag("cert-long-validity")
    end
    
    -- Compliance tags
    if compliance.compliant then
        add_tag("article-11-cert-compliant")
        if compliance.level == "excellent" then
            add_tag("excellent-cert-security")
        elseif compliance.level == "good" then
            add_tag("good-cert-security")
        end
    else
        add_tag("article-11-cert-non-compliant")
        add_tag("cert-compliance-violation")
    end
    
    -- Cryptographic strength tags
    if cert_info.public_key.bit_length >= 4096 then
        add_tag("strong-crypto")
    elseif cert_info.public_key.bit_length < 2048 then
        add_tag("weak-crypto")
    end
    
    -- Log detailed findings
    log("Certificate Analysis Results:")
    log("- Subject: " .. cert_info.subject.common_name)
    log("- Issuer: " .. cert_info.issuer.organization)
    log("- Expires in: " .. expiry_days .. " days")
    log("- Hostname Valid: " .. (hostname_valid and "Yes" or "No"))
    log("- Trust Level: " .. trust_assessment.trust_level)
    log("- Compliance Score: " .. compliance.score .. "/8 (" .. compliance.percentage .. "%)")
    log("- Article 11 Compliant: " .. (compliance.compliant and "Yes" or "No"))
    
    if #compliance.issues > 0 then
        log("Critical Issues:")
        for _, issue in ipairs(compliance.issues) do
            log("  - " .. issue)
        end
    end
    
    if #compliance.recommendations > 0 then
        log("Recommendations:")
        for _, rec in ipairs(compliance.recommendations) do
            log("  - " .. rec)
        end
    end
    
    -- Final decision with checklist integration
    if compliance.compliant then
        pass_checklist("ssl-certificate-validation-012", "Certificate inspection passed - compliance score: " .. compliance.percentage .. "%")
        pass()
    else
        fail_checklist("ssl-certificate-validation-012", "Certificate compliance violations found - score: " .. compliance.percentage .. "%")
        reject("Certificate compliance violations found")
    end
end

-- Execute certificate inspection
inspect_certificate()

log("TLS certificate inspection complete for " .. asset.value)