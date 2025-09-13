-- @title TLS Compliance Checklist Evaluation
-- @description Evaluates overall TLS compliance against Moldovan Cybersecurity Law requirements
-- @category Compliance
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed tls_security_headers.lua

-- Only run on service assets that completed security headers analysis
if asset.type ~= "service" then
    log("Skipping TLS compliance evaluation - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    return
end

port = tonumber(port)

-- Only check services that should have TLS
local secure_ports = {443, 8443, 993, 995, 465, 587, 636, 989, 990, 992, 5061}
local web_ports = {80, 443, 8080, 8443, 8000, 8008, 3000, 5000}

local is_secure_service = false
local is_web_service = false

for _, secure_port in ipairs(secure_ports) do
    if port == secure_port then
        is_secure_service = true
        break
    end
end

for _, web_port in ipairs(web_ports) do
    if port == web_port then
        is_web_service = true
        break
    end
end

if not is_secure_service and not is_web_service then
    log("Skipping TLS compliance - not a TLS or web service port: " .. port)
    return
end

log("Evaluating overall TLS compliance for: " .. host .. ":" .. port)

-- Function to collect TLS analysis results from previous scans
local function collect_tls_results()
    local results = {
        tls_supported = false,
        certificate_valid = false,
        hsts_configured = false,
        security_headers_present = false,
        cipher_security = "unknown",
        compliance_scores = {},
        total_issues = {}
    }
    
    -- Collect TLS version check results
    if asset.scan_metadata and asset.scan_metadata["tls.supported"] then
        results.tls_supported = asset.scan_metadata["tls.supported"]
        if asset.scan_metadata["tls.compliance_level"] then
            results.tls_compliance_level = asset.scan_metadata["tls.compliance_level"]
        end
        if asset.scan_metadata["tls.modern_indicators_count"] then
            results.compliance_scores.tls_version = asset.scan_metadata["tls.modern_indicators_count"]
        end
        if asset.scan_metadata["tls.security_issues"] then
            table.insert(results.total_issues, "TLS Version: " .. asset.scan_metadata["tls.security_issues"])
        end
    end
    
    -- Collect certificate validation results
    if asset.scan_metadata and asset.scan_metadata["certificate.valid"] then
        results.certificate_valid = asset.scan_metadata["certificate.valid"]
        if asset.scan_metadata["certificate.compliance_level"] then
            results.certificate_compliance_level = asset.scan_metadata["certificate.compliance_level"]
        end
        if asset.scan_metadata["certificate.security_score"] then
            results.compliance_scores.certificate = asset.scan_metadata["certificate.security_score"]
        end
        if asset.scan_metadata["certificate.security_issues"] then
            table.insert(results.total_issues, "Certificate: " .. asset.scan_metadata["certificate.security_issues"])
        end
    end
    
    -- Collect HSTS validation results
    if asset.scan_metadata and asset.scan_metadata["hsts.has_hsts_header"] then
        results.hsts_configured = asset.scan_metadata["hsts.has_hsts_header"]
        if asset.scan_metadata["hsts.compliance_level"] then
            results.hsts_compliance_level = asset.scan_metadata["hsts.compliance_level"]
        end
        if asset.scan_metadata["hsts.score"] then
            results.compliance_scores.hsts = asset.scan_metadata["hsts.score"]
        end
        if asset.scan_metadata["hsts.issues"] then
            table.insert(results.total_issues, "HSTS: " .. asset.scan_metadata["hsts.issues"])
        end
    end
    
    -- Collect security headers results
    if asset.scan_metadata and asset.scan_metadata["security_headers.compliance_percentage"] then
        results.security_headers_percentage = asset.scan_metadata["security_headers.compliance_percentage"]
        if asset.scan_metadata["security_headers.compliance_level"] then
            results.security_headers_compliance_level = asset.scan_metadata["security_headers.compliance_level"]
        end
        if asset.scan_metadata["security_headers.total_score"] then
            results.compliance_scores.security_headers = asset.scan_metadata["security_headers.total_score"]
        end
        if asset.scan_metadata["security_headers.issues"] then
            table.insert(results.total_issues, "Security Headers: " .. asset.scan_metadata["security_headers.issues"])
        end
        
        results.security_headers_present = (asset.scan_metadata["security_headers.found_count"] or 0) > 0
    end
    
    -- Collect cipher analysis results
    if asset.scan_metadata and asset.scan_metadata["cipher.strength"] then
        results.cipher_security = asset.scan_metadata["cipher.strength"]
        if asset.scan_metadata["cipher.compliance_status"] then
            results.cipher_compliance_status = asset.scan_metadata["cipher.compliance_status"]
        end
        if asset.scan_metadata["cipher.modern_score"] then
            results.compliance_scores.cipher = asset.scan_metadata["cipher.modern_score"]
        end
        if asset.scan_metadata["cipher.vulnerabilities"] then
            table.insert(results.total_issues, "Cipher: " .. asset.scan_metadata["cipher.vulnerabilities"])
        end
    end
    
    return results
end

-- Function to evaluate Moldovan Cybersecurity Law Article 11 compliance
local function evaluate_article_11_compliance(tls_results)
    local compliance_evaluation = {
        transport_security = "fail",        -- Article 11.1.a - Transport layer security
        data_encryption = "fail",           -- Article 11.1.b - Data encryption in transit
        secure_protocols = "fail",          -- Article 11.1.c - Use of secure protocols
        certificate_management = "fail",    -- Article 11.1.d - Certificate management
        security_monitoring = "fail",       -- Article 11.1.e - Security monitoring capabilities
        
        overall_score = 0,
        critical_failures = {},
        recommendations = {},
        compliance_level = "non-compliant"
    }
    
    -- Evaluate Transport Security (Article 11.1.a)
    if tls_results.tls_supported then
        if tls_results.tls_compliance_level == "modern" then
            compliance_evaluation.transport_security = "excellent"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 3
        elseif tls_results.tls_compliance_level == "intermediate" then
            compliance_evaluation.transport_security = "acceptable"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 2
        else
            compliance_evaluation.transport_security = "basic"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 1
            table.insert(compliance_evaluation.critical_failures, "Weak transport security configuration")
        end
    else
        table.insert(compliance_evaluation.critical_failures, "TLS not properly supported")
        table.insert(compliance_evaluation.recommendations, "Implement proper TLS/HTTPS support")
    end
    
    -- Evaluate Data Encryption (Article 11.1.b)
    if tls_results.cipher_security == "strong" then
        compliance_evaluation.data_encryption = "excellent"
        compliance_evaluation.overall_score = compliance_evaluation.overall_score + 3
    elseif tls_results.cipher_security == "acceptable" then
        compliance_evaluation.data_encryption = "acceptable"
        compliance_evaluation.overall_score = compliance_evaluation.overall_score + 2
    elseif tls_results.cipher_security == "weak" then
        compliance_evaluation.data_encryption = "weak"
        compliance_evaluation.overall_score = compliance_evaluation.overall_score + 1
        table.insert(compliance_evaluation.critical_failures, "Weak encryption ciphers in use")
    else
        table.insert(compliance_evaluation.critical_failures, "Encryption strength cannot be determined")
        table.insert(compliance_evaluation.recommendations, "Upgrade to strong cipher suites (AES-GCM, ChaCha20)")
    end
    
    -- Evaluate Secure Protocols (Article 11.1.c)
    if tls_results.certificate_valid then
        if tls_results.certificate_compliance_level == "excellent" or tls_results.certificate_compliance_level == "good" then
            compliance_evaluation.secure_protocols = "excellent"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 3
        elseif tls_results.certificate_compliance_level == "acceptable" then
            compliance_evaluation.secure_protocols = "acceptable"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 2
        else
            compliance_evaluation.secure_protocols = "weak"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 1
        end
    else
        table.insert(compliance_evaluation.critical_failures, "Invalid or missing SSL/TLS certificate")
        table.insert(compliance_evaluation.recommendations, "Obtain valid SSL/TLS certificate from trusted CA")
    end
    
    -- Evaluate Certificate Management (Article 11.1.d)
    if tls_results.hsts_configured then
        if tls_results.hsts_compliance_level == "excellent" or tls_results.hsts_compliance_level == "good" then
            compliance_evaluation.certificate_management = "excellent"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 3
        elseif tls_results.hsts_compliance_level == "acceptable" then
            compliance_evaluation.certificate_management = "acceptable"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 2
        else
            compliance_evaluation.certificate_management = "basic"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 1
        end
    else
        table.insert(compliance_evaluation.critical_failures, "HSTS not configured")
        table.insert(compliance_evaluation.recommendations, "Implement HTTP Strict Transport Security (HSTS)")
    end
    
    -- Evaluate Security Monitoring (Article 11.1.e)
    if tls_results.security_headers_present then
        local headers_percentage = tls_results.security_headers_percentage or 0
        if headers_percentage >= 85 then
            compliance_evaluation.security_monitoring = "excellent"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 3
        elseif headers_percentage >= 70 then
            compliance_evaluation.security_monitoring = "good"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 2
        elseif headers_percentage >= 50 then
            compliance_evaluation.security_monitoring = "basic"
            compliance_evaluation.overall_score = compliance_evaluation.overall_score + 1
        else
            table.insert(compliance_evaluation.critical_failures, "Insufficient security headers")
        end
    else
        table.insert(compliance_evaluation.critical_failures, "No security headers implemented")
        table.insert(compliance_evaluation.recommendations, "Implement comprehensive HTTP security headers")
    end
    
    -- Determine overall compliance level
    local max_score = 15 -- 5 categories × 3 points each
    local compliance_percentage = math.floor((compliance_evaluation.overall_score / max_score) * 100)
    
    if compliance_evaluation.overall_score >= 13 and #compliance_evaluation.critical_failures == 0 then
        compliance_evaluation.compliance_level = "fully-compliant"
    elseif compliance_evaluation.overall_score >= 10 and #compliance_evaluation.critical_failures <= 1 then
        compliance_evaluation.compliance_level = "largely-compliant"
    elseif compliance_evaluation.overall_score >= 7 and #compliance_evaluation.critical_failures <= 2 then
        compliance_evaluation.compliance_level = "partially-compliant"
    else
        compliance_evaluation.compliance_level = "non-compliant"
    end
    
    compliance_evaluation.compliance_percentage = compliance_percentage
    
    return compliance_evaluation
end

-- Collect TLS analysis results
local tls_results = collect_tls_results()

-- Set metadata about collected results
set_metadata("tls_compliance.tls_supported", tls_results.tls_supported)
set_metadata("tls_compliance.certificate_valid", tls_results.certificate_valid)
set_metadata("tls_compliance.hsts_configured", tls_results.hsts_configured)
set_metadata("tls_compliance.security_headers_present", tls_results.security_headers_present)
set_metadata("tls_compliance.cipher_security", tls_results.cipher_security)

if #tls_results.total_issues > 0 then
    set_metadata("tls_compliance.total_issues", table.concat(tls_results.total_issues, "; "))
end

-- Evaluate Article 11 compliance
local compliance_eval = evaluate_article_11_compliance(tls_results)

-- Set comprehensive compliance metadata
set_metadata("tls_compliance.article_11.transport_security", compliance_eval.transport_security)
set_metadata("tls_compliance.article_11.data_encryption", compliance_eval.data_encryption)
set_metadata("tls_compliance.article_11.secure_protocols", compliance_eval.secure_protocols)
set_metadata("tls_compliance.article_11.certificate_management", compliance_eval.certificate_management)
set_metadata("tls_compliance.article_11.security_monitoring", compliance_eval.security_monitoring)

set_metadata("tls_compliance.overall_score", compliance_eval.overall_score)
set_metadata("tls_compliance.compliance_percentage", compliance_eval.compliance_percentage)
set_metadata("tls_compliance.compliance_level", compliance_eval.compliance_level)

if #compliance_eval.critical_failures > 0 then
    set_metadata("tls_compliance.critical_failures", table.concat(compliance_eval.critical_failures, "; "))
end

if #compliance_eval.recommendations > 0 then
    set_metadata("tls_compliance.recommendations", table.concat(compliance_eval.recommendations, "; "))
end

log("TLS Compliance Evaluation:")
log("- Transport Security: " .. compliance_eval.transport_security)
log("- Data Encryption: " .. compliance_eval.data_encryption)
log("- Secure Protocols: " .. compliance_eval.secure_protocols)
log("- Certificate Management: " .. compliance_eval.certificate_management)
log("- Security Monitoring: " .. compliance_eval.security_monitoring)
log("Overall Score: " .. compliance_eval.overall_score .. "/15 (" .. compliance_eval.compliance_percentage .. "%)")
log("Compliance Level: " .. compliance_eval.compliance_level)

-- Update compliance checklists based on evaluation
if compliance_eval.compliance_level == "fully-compliant" then
    pass_checklist("transport-layer-security-019", "Fully compliant with Article 11 requirements (" .. compliance_eval.compliance_percentage .. "%)")
    pass_checklist("cryptographic-controls-017", "TLS implementation fully compliant")
    pass_checklist("data-protection-measures-021", "Data in transit properly protected")
    
    log("TLS Compliance: FULLY COMPLIANT")
    pass()
    
elseif compliance_eval.compliance_level == "largely-compliant" then
    local message = "Largely compliant with minor issues"
    if #compliance_eval.critical_failures > 0 then
        message = message .. ": " .. table.concat(compliance_eval.critical_failures, "; ")
    end
    message = message .. " (" .. compliance_eval.compliance_percentage .. "%)"
    
    pass_checklist("transport-layer-security-019", message)
    pass_checklist("cryptographic-controls-017", "TLS implementation largely compliant")
    
    if #compliance_eval.critical_failures == 0 then
        pass_checklist("data-protection-measures-021", "Data in transit adequately protected")
    else
        fail_checklist("data-protection-measures-021", "Data protection has minor issues")
    end
    
    log("TLS Compliance: LARGELY COMPLIANT")
    pass()
    
elseif compliance_eval.compliance_level == "partially-compliant" then
    local message = "Partially compliant - significant issues need attention"
    if #compliance_eval.critical_failures > 0 then
        message = message .. ": " .. table.concat(compliance_eval.critical_failures, "; ")
    end
    message = message .. " (" .. compliance_eval.compliance_percentage .. "%)"
    
    fail_checklist("transport-layer-security-019", message)
    fail_checklist("cryptographic-controls-017", "TLS implementation has significant issues")
    fail_checklist("data-protection-measures-021", "Data protection insufficient")
    
    log("TLS Compliance: PARTIALLY COMPLIANT - requires attention")
    reject("TLS configuration requires significant improvements")
    
else
    local message = "Non-compliant with Article 11 requirements"
    if #compliance_eval.critical_failures > 0 then
        message = message .. ": " .. table.concat(compliance_eval.critical_failures, "; ")
    end
    message = message .. " (" .. compliance_eval.compliance_percentage .. "%)"
    
    fail_checklist("transport-layer-security-019", message)
    fail_checklist("cryptographic-controls-017", "TLS implementation non-compliant")
    fail_checklist("data-protection-measures-021", "Data protection inadequate")
    
    log("TLS Compliance: NON-COMPLIANT")
    reject("TLS configuration does not meet legal requirements")
end

-- Add descriptive tags based on compliance level
if compliance_eval.compliance_level == "fully-compliant" then
    add_tag("tls-fully-compliant")
    add_tag("article-11-compliant")
elseif compliance_eval.compliance_level == "largely-compliant" then
    add_tag("tls-largely-compliant")
    add_tag("article-11-mostly-compliant")
elseif compliance_eval.compliance_level == "partially-compliant" then
    add_tag("tls-partially-compliant")
    add_tag("article-11-needs-work")
else
    add_tag("tls-non-compliant")
    add_tag("article-11-non-compliant")
end

-- Add specific compliance area tags
if compliance_eval.transport_security == "excellent" then
    add_tag("excellent-transport-security")
end

if compliance_eval.data_encryption == "excellent" then
    add_tag("excellent-encryption")
end

if compliance_eval.certificate_management == "excellent" then
    add_tag("excellent-certificates")
end

if #compliance_eval.critical_failures > 0 then
    add_tag("tls-critical-issues")
end

-- Log final recommendations if any
if #compliance_eval.recommendations > 0 then
    log("Recommendations for improvement:")
    for _, recommendation in ipairs(compliance_eval.recommendations) do
        log("- " .. recommendation)
    end
end