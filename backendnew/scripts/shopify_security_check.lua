-- @name Shopify Security Misconfiguration Check
-- @description Detects common security misconfigurations in Shopify stores
-- @author RegTech Security Team
-- @version 1.0
-- @category web_security
-- @asset_types domain,subdomain,service

log("Starting Shopify security misconfiguration analysis")

-- Shopify-specific patterns and indicators
local shopify_patterns = {
    -- Domain patterns that indicate Shopify
    domains = {
        "%.myshopify%.com",
        "shopify%-cloud%.com",
        "cdn%.shopify%.com"
    },
    
    -- Secret patterns to look for in responses
    secrets = {
        "shopify_api_key",
        "shopify_secret_key", 
        "shopify_access_token",
        "shopify_webhook_secret",
        "SHOPIFY_API_KEY",
        "shpss_[0-9a-zA-Z]+",
        "shpat_[0-9a-zA-Z]+",
        "shppa_[0-9a-zA-Z]+",
        "whsec_[0-9a-zA-Z]+",
        "api_key.*['\"][0-9a-f]{8,}['\"]",
        "secret.*['\"][0-9a-zA-Z]{8,}['\"]",
        "token.*['\"][0-9a-zA-Z]{20,}['\"]"
    },
    
    -- JSON endpoints to test
    json_endpoints = {
        "/products.json",
        "/collections.json", 
        "/cart.json",
        "/checkout.json",
        "/customer.json",
        "/orders.json"
    },
    
    -- Redirect parameters to test
    redirect_params = {
        "redirect",
        "return_to", 
        "next",
        "url",
        "redirect_url",
        "callback"
    }
}

-- Function to detect if target is a Shopify store
local function is_shopify_store(host)
    log("Checking if " .. host .. " is a Shopify store")
    
    -- Check for Shopify domain patterns first
    for _, pattern in ipairs(shopify_patterns.domains) do
        if string.match(host, pattern) then
            log("Matched Shopify domain pattern: " .. pattern)
            return true, "Shopify domain detected: " .. pattern
        end
    end
    
    -- Try both HTTP and HTTPS
    local protocols = {"https://", "http://"}
    
    for _, protocol in ipairs(protocols) do
        local url = protocol .. host
        log("Testing " .. url .. " for Shopify indicators")
        
        local status, body, headers, err = http.get(url, {
            ["User-Agent"] = "RegTech-Shopify-Scanner/1.0"
        }, 10)
        
        if status and status >= 200 and status < 400 then
            log("Got response " .. status .. " from " .. url)
            
            -- Check headers for Shopify indicators
            if headers then
                for header_name, header_value in pairs(headers) do
                    local header_lower = string.lower(header_name)
                    local value_lower = string.lower(tostring(header_value))
                    
                    if string.match(header_lower, "shopify") or 
                       string.match(value_lower, "shopify") or
                       header_name == "x-shopify-stage" or
                       header_name == "x-shopify-shop-id" or
                       header_name == "server" and string.match(value_lower, "nginx") then
                        log("Found Shopify indicator in headers: " .. header_name .. " = " .. tostring(header_value))
                        return true, "Shopify headers detected: " .. header_name
                    end
                end
            end
            
            -- Check body for Shopify indicators
            if body then
                local body_indicators = {
                    "shopify%.com",
                    "Shopify%.theme", 
                    "shopify%-analytics",
                    "cdn%.shopify%.com",
                    "myshopify%.com",
                    "ShopifyAnalytics",
                    "window%.Shopify",
                    "Shopify%.shop",
                    "shopify_pay",
                    "shopify%-section",
                    "powered[^>]*shopify"
                }
                
                for _, indicator in ipairs(body_indicators) do
                    if string.match(body, indicator) then
                        log("Found Shopify indicator in body: " .. indicator)
                        return true, "Shopify content detected: " .. indicator
                    end
                end
                
                -- Check for Shopify-specific meta tags
                if string.match(body, '<meta[^>]*shopify') or 
                   string.match(body, 'generator[^>]*shopify') then
                    log("Found Shopify meta tags")
                    return true, "Shopify meta tags detected"
                end
            end
            
            -- If we got a successful response from HTTPS, don't try HTTP
            if protocol == "https://" then
                break
            end
        else
            log("Failed to get response from " .. url .. ": " .. tostring(err))
        end
    end
    
    log("No Shopify indicators found for " .. host)
    return false, "No Shopify indicators found"
end

-- Function to check for hardcoded secrets
local function check_hardcoded_secrets(host)
    local secrets_found = {}
    local endpoints_to_check = {
        "/", 
        "/assets/theme.js", 
        "/assets/application.js", 
        "/assets/constants.js",
        "/assets/theme.css",
        "/checkout"
    }
    
    log("Checking for hardcoded secrets on " .. host)
    
    for _, endpoint in ipairs(endpoints_to_check) do
        -- Try both HTTPS and HTTP
        for _, protocol in ipairs({"https://", "http://"}) do
            local url = protocol .. host .. endpoint
            log("Checking endpoint: " .. url)
            
            local status, body, headers, err = http.get(url, {
                ["User-Agent"] = "RegTech-Shopify-Scanner/1.0"
            }, 10)
            
            if status and status >= 200 and status < 400 and body then
                log("Got response from " .. url .. " (status: " .. status .. ", size: " .. #body .. " bytes)")
                
                -- Check for secret patterns
                for _, pattern in ipairs(shopify_patterns.secrets) do
                    local matches = {}
                    
                    -- Use more flexible pattern matching
                    if pattern == "shopify_api_key" then
                        for match in string.gmatch(body, "['\"]?shopify_api_key['\"]?%s*[:=]%s*['\"]([^'\"]+)['\"]") do
                            table.insert(matches, match)
                        end
                        for match in string.gmatch(body, "shopify_api_key[^'\"]*['\"]([^'\"]+)['\"]") do
                            table.insert(matches, match)
                        end
                    elseif string.match(pattern, "^[a-z_]+$") then
                        -- Simple string patterns
                        for match in string.gmatch(body, pattern) do
                            table.insert(matches, match)
                        end
                    else
                        -- Regex patterns
                        for match in string.gmatch(body, pattern) do
                            table.insert(matches, match)
                        end
                    end
                end
                
                -- Additional patterns for comprehensive detection
                local additional_patterns = {
                    "api[_%-]?key%s*[:=]%s*['\"]([^'\"]{16,})['\"]",
                    "secret[_%-]?key%s*[:=]%s*['\"]([^'\"]{16,})['\"]", 
                    "access[_%-]?token%s*[:=]%s*['\"]([^'\"]{20,})['\"]",
                    "webhook[_%-]?secret%s*[:=]%s*['\"]([^'\"]{16,})['\"]",
                    "(sk_[a-zA-Z0-9_]{20,})",
                    "(pk_[a-zA-Z0-9_]{20,})"
                }
                
                for _, pattern in ipairs(additional_patterns) do
                    for match in string.gmatch(body, pattern) do
                        table.insert(secrets_found, {
                            endpoint = endpoint,
                            pattern = "additional_pattern",
                            matches = {match},
                            url = url
                        })
                        log("Found potential secret: " .. match .. " at " .. url)
                    end
                end
                
                break -- If HTTPS worked, don't try HTTP
            else
                log("No response from " .. url .. " (status: " .. tostring(status) .. ", error: " .. tostring(err) .. ")")
            end
        end
        
        -- Rate limiting
        sleep(0.5)
    end
    
    log("Found " .. #secrets_found .. " potential secrets")
    return secrets_found
end

-- Function to check JSON endpoint exposure
local function check_json_endpoints(host)
    local exposed_endpoints = {}
    
    for _, endpoint in ipairs(shopify_patterns.json_endpoints) do
        local url = "https://" .. host .. endpoint
        local status, body, headers, err = http.get(url, {
            ["User-Agent"] = "RegTech-Shopify-Scanner/1.0"
        }, 5)
        
        if status == 200 and body then
            -- Try to parse as JSON
            local json_data = nil
            local success, parsed = pcall(function()
                return json.decode(body)
            end)
            
            if success and parsed then
                local info = {
                    endpoint = endpoint,
                    status = status,
                    size = #body,
                    has_data = false,
                    sensitive_fields = {}
                }
                
                -- Check for sensitive information
                if parsed.products and #parsed.products > 0 then
                    info.has_data = true
                    info.product_count = #parsed.products
                end
                
                if parsed.collections and #parsed.collections > 0 then
                    info.has_data = true
                    info.collection_count = #parsed.collections
                end
                
                -- Check for potentially sensitive fields
                local body_lower = string.lower(body)
                local sensitive_patterns = {"email", "phone", "address", "customer", "order", "price", "inventory"}
                for _, pattern in ipairs(sensitive_patterns) do
                    if string.match(body_lower, pattern) then
                        table.insert(info.sensitive_fields, pattern)
                    end
                end
                
                table.insert(exposed_endpoints, info)
            end
        end
        
        -- Rate limiting
        sleep(0.3)
    end
    
    return exposed_endpoints
end

-- Function to check for open redirects
local function check_open_redirects(host)
    local redirect_vulnerabilities = {}
    local test_urls = {
        "https://evil-site.com",
        "http://evil-site.com", 
        "//evil-site.com",
        "javascript:alert(1)"
    }
    
    for _, param in ipairs(shopify_patterns.redirect_params) do
        for _, test_url in ipairs(test_urls) do
            local check_url = "https://" .. host .. "/?" .. param .. "=" .. test_url
            local status, body, headers, err = http.get(check_url, {
                ["User-Agent"] = "RegTech-Shopify-Scanner/1.0",
                follow_redirects = false
            }, 5)
            
            if status and (status == 301 or status == 302 or status == 307 or status == 308) then
                local location = headers and headers["Location"]
                if location and string.match(location, "evil%-site%.com") then
                    table.insert(redirect_vulnerabilities, {
                        parameter = param,
                        test_url = test_url,
                        redirect_location = location,
                        status_code = status
                    })
                end
            end
            
            -- Rate limiting
            sleep(0.2)
        end
    end
    
    return redirect_vulnerabilities
end

-- Main analysis function
local function analyze_shopify_security()
    local target_host = asset.value
    
    -- Handle different asset types
    if asset.type == "service" then
        local host, port = string.match(asset.value, "([^:]+):(%d+)")
        if host then
            target_host = host
        end
    elseif asset.type == "domain" or asset.type == "subdomain" then
        target_host = asset.value
    end
    
    -- Remove protocol if present
    target_host = string.gsub(target_host, "^https?://", "")
    target_host = string.gsub(target_host, "/$", "")
    
    log("=== Starting Shopify Security Analysis ===")
    log("Target: " .. target_host)
    log("Asset type: " .. asset.type)
    
    -- Check if this is a Shopify store
    local is_shopify, shopify_reason = is_shopify_store(target_host)
    
    local analysis = {
        is_shopify_store = is_shopify,
        shopify_detection_reason = shopify_reason,
        hardcoded_secrets = {},
        exposed_json_endpoints = {},
        redirect_vulnerabilities = {},
        security_score = 100,
        risk_level = "LOW",
        compliance_issues = {},
        recommendations = {}
    }
    
    if not is_shopify then
        log("Target is not a Shopify store, skipping specific checks")
        set_metadata("shopify_analysis", "not_applicable")
        return analysis
    end
    
    log("Shopify store detected: " .. shopify_reason)
    set_metadata("shopify_store_detected", true)
    set_metadata("shopify_detection_reason", shopify_reason)
    
    -- Check for hardcoded secrets
    analysis.hardcoded_secrets = check_hardcoded_secrets(target_host)
    if #analysis.hardcoded_secrets > 0 then
        analysis.security_score = analysis.security_score - 30
        analysis.risk_level = "CRITICAL"
        table.insert(analysis.compliance_issues, "Hardcoded secrets found in theme files")
        table.insert(analysis.recommendations, "Remove all API keys and secrets from client-side code")
        log("CRITICAL: Found " .. #analysis.hardcoded_secrets .. " potential hardcoded secrets")
    end
    
    -- Check JSON endpoint exposure
    analysis.exposed_json_endpoints = check_json_endpoints(target_host)
    if #analysis.exposed_json_endpoints > 0 then
        for _, endpoint in ipairs(analysis.exposed_json_endpoints) do
            if endpoint.has_data and #endpoint.sensitive_fields > 0 then
                analysis.security_score = analysis.security_score - 15
                if analysis.risk_level == "LOW" then analysis.risk_level = "MEDIUM" end
                table.insert(analysis.compliance_issues, "Sensitive data exposed via JSON endpoint: " .. endpoint.endpoint)
            end
        end
        log("Found " .. #analysis.exposed_json_endpoints .. " exposed JSON endpoints")
    end
    
    -- Check for open redirects
    analysis.redirect_vulnerabilities = check_open_redirects(target_host)
    if #analysis.redirect_vulnerabilities > 0 then
        analysis.security_score = analysis.security_score - 20
        if analysis.risk_level ~= "CRITICAL" then analysis.risk_level = "HIGH" end
        table.insert(analysis.compliance_issues, "Open redirect vulnerabilities found")
        table.insert(analysis.recommendations, "Implement redirect URL validation and whitelisting")
        log("SECURITY ISSUE: Found " .. #analysis.redirect_vulnerabilities .. " open redirect vulnerabilities")
    end
    
    return analysis
end

-- Execute analysis
local analysis = analyze_shopify_security()

-- Set metadata
set_metadata("shopify_security_analysis", analysis.is_shopify_store and "completed" or "not_applicable")
set_metadata("shopify_security_score", analysis.security_score)
set_metadata("shopify_risk_level", analysis.risk_level)

if analysis.is_shopify_store then
    set_metadata("shopify_secrets_found", #analysis.hardcoded_secrets)
    set_metadata("shopify_json_endpoints_exposed", #analysis.exposed_json_endpoints) 
    set_metadata("shopify_redirect_vulnerabilities", #analysis.redirect_vulnerabilities)
    
    if #analysis.compliance_issues > 0 then
        set_metadata("shopify_compliance_issues", table.concat(analysis.compliance_issues, "; "))
    end
    
    if #analysis.recommendations > 0 then
        set_metadata("shopify_recommendations", table.concat(analysis.recommendations, "; "))
    end
    
    -- Compliance assessment
    if analysis.security_score >= 90 then
        pass_checklist("web-service-security-021", "Shopify store security configuration acceptable (score: " .. analysis.security_score .. "%)")
        pass()
    elseif analysis.security_score >= 70 then
        pass_checklist("web-service-security-021", "Shopify store has minor security issues (score: " .. analysis.security_score .. "%)")
        pass()
    else
        fail_checklist("web-service-security-021", "Shopify store has significant security issues (score: " .. analysis.security_score .. "%)")
        reject("Critical Shopify security misconfigurations detected")
    end
else
    pass_checklist("web-service-security-021", "Target is not a Shopify store")
    pass()
end

log("Shopify security analysis complete for " .. asset.value)