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

-- Function to detect development/test store indicators
local function check_development_indicators(host, body, headers)
    local dev_indicators = {}
    
    -- Check domain patterns for development indicators
    local dev_patterns = {
        "test[%-_]", "dev[%-_]", "demo[%-_]", "staging[%-_]", "local[%-_]",
        "[%-_]test", "[%-_]dev", "[%-_]demo", "[%-_]staging", "[%-_]local",
        "sandbox", "preview", "trial", "temp"
    }
    
    for _, pattern in ipairs(dev_patterns) do
        if string.match(string.lower(host), pattern) then
            table.insert(dev_indicators, "Development domain pattern: " .. pattern)
        end
    end
    
    -- Check for development content in body
    if body then
        local dev_content_patterns = {
            "debug[%s=:]", "development[%s=:]", "staging[%s=:]", "test[%s=:]",
            "console%.log", "console%.debug", "console%.error",
            "TODO:", "FIXME:", "XXX:", "HACK:",
            "localhost", "127%.0%.0%.1", "192%.168%.",
            "password.*123", "password.*test", "password.*admin",
            "admin.*admin", "test.*test", "demo.*demo",
            "under[%s_%-]?construction", "coming[%s_%-]?soon",
            "placeholder", "lorem ipsum",
            "<!-- DEBUG", "<!-- TODO", "<!-- FIXME"
        }
        
        local body_lower = string.lower(body)
        for _, pattern in ipairs(dev_content_patterns) do
            if string.match(body_lower, pattern) then
                table.insert(dev_indicators, "Development content: " .. pattern)
            end
        end
    end
    
    -- Check headers for development indicators
    if headers then
        for header_name, header_value in pairs(headers) do
            local header_lower = string.lower(header_name)
            local value_lower = string.lower(tostring(header_value))
            
            if string.match(header_lower, "debug") or 
               string.match(header_lower, "test") or
               string.match(value_lower, "development") or
               string.match(value_lower, "staging") then
                table.insert(dev_indicators, "Development header: " .. header_name .. " = " .. tostring(header_value))
            end
        end
    end
    
    return dev_indicators
end

-- Function to detect if target is a Shopify store
local function is_shopify_store(host)
    log("Checking if " .. host .. " is a Shopify store")
    
    -- Check for Shopify domain patterns first
    for _, pattern in ipairs(shopify_patterns.domains) do
        if string.match(host, pattern) then
            log("Matched Shopify domain pattern: " .. pattern)
            return true, "Shopify domain detected: " .. pattern, {}
        end
    end
    
    -- Try both HTTP and HTTPS
    local protocols = {"https://", "http://"}
    local dev_indicators = {}
    
    for _, protocol in ipairs(protocols) do
        local url = protocol .. host
        log("Testing " .. url .. " for Shopify indicators")
        
        local status, body, headers, err = http.get(url, {
            ["User-Agent"] = "RegTech-Shopify-Scanner/1.0"
        }, 10)
        
        if status and status >= 200 and status < 400 then
            log("Got response " .. status .. " from " .. url)
            
            -- Check for development indicators
            local current_dev_indicators = check_development_indicators(host, body, headers)
            for _, indicator in ipairs(current_dev_indicators) do
                table.insert(dev_indicators, indicator)
            end
            
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
                        return true, "Shopify headers detected: " .. header_name, dev_indicators
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
                        return true, "Shopify content detected: " .. indicator, dev_indicators
                    end
                end
                
                -- Check for Shopify-specific meta tags
                if string.match(body, '<meta[^>]*shopify') or 
                   string.match(body, 'generator[^>]*shopify') then
                    log("Found Shopify meta tags")
                    return true, "Shopify meta tags detected", dev_indicators
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
    return false, "No Shopify indicators found", dev_indicators
end

-- Function to check for hardcoded secrets and information disclosure
local function check_hardcoded_secrets(host)
    local secrets_found = {}
    local endpoints_to_check = {
        "/", 
        "/assets/theme.js", 
        "/assets/application.js", 
        "/assets/constants.js",
        "/assets/theme.css",
        "/assets/theme.min.js",
        "/assets/shopify_common.js",
        "/assets/api.js",
        "/assets/config.js",
        "/checkout",
        "/checkout.json",
        "/cart/add.js",
        "/cart/update.js",
        "/.git/config",
        "/.env",
        "/config.json",
        "/package.json",
        "/composer.json",
        "/webpack.config.js",
        "/gulpfile.js",
        "/Gruntfile.js",
        "/assets/app.js.map",
        "/assets/theme.css.map",
        "/debug",
        "/admin/debug",
        "/test",
        "/staging"
    }
    
    log("Checking for hardcoded secrets and information disclosure on " .. host)
    
    for _, endpoint in ipairs(endpoints_to_check) do
        -- Try both HTTPS and HTTP
        for _, protocol in ipairs({"https://", "http://"}) do
            local url = protocol .. host .. endpoint
            log("Checking endpoint: " .. url)
            
            local status, body, headers, err = http.get(url, {
                ["User-Agent"] = "RegTech-Shopify-Scanner/1.0"
            }, 10)
            
            if status and status >= 200 and status < 500 and body then
                log("Got response from " .. url .. " (status: " .. status .. ", size: " .. #body .. " bytes)")
                
                -- Check for secret patterns
                for _, pattern in ipairs(shopify_patterns.secrets) do
                    for match in string.gmatch(body, pattern) do
                        table.insert(secrets_found, {
                            endpoint = endpoint,
                            pattern = pattern,
                            value = match,
                            url = url,
                            severity = "HIGH"
                        })
                        log("Found API token/secret: " .. pattern .. " = " .. match .. " at " .. url)
                    end
                end
                
                -- Enhanced patterns for comprehensive detection
                local vulnerability_patterns = {
                    -- API Keys and Tokens
                    {pattern = "api[_%-]?key%s*[:=]%s*['\"]([^'\"]{16,})['\"]", severity = "HIGH", type = "API Key"},
                    {pattern = "secret[_%-]?key%s*[:=]%s*['\"]([^'\"]{16,})['\"]", severity = "HIGH", type = "Secret Key"},
                    {pattern = "access[_%-]?token%s*[:=]%s*['\"]([^'\"]{20,})['\"]", severity = "HIGH", type = "Access Token"},
                    {pattern = "webhook[_%-]?secret%s*[:=]%s*['\"]([^'\"]{16,})['\"]", severity = "HIGH", type = "Webhook Secret"},
                    {pattern = "(sk_[a-zA-Z0-9_]{20,})", severity = "CRITICAL", type = "Stripe Secret Key"},
                    {pattern = "(pk_[a-zA-Z0-9_]{20,})", severity = "MEDIUM", type = "Stripe Public Key"},
                    
                    -- Development and Debug Information
                    {pattern = "debug%s*[:=]%s*true", severity = "MEDIUM", type = "Debug Mode Enabled"},
                    {pattern = "development%s*[:=]%s*true", severity = "MEDIUM", type = "Development Mode"},
                    {pattern = "console%.log%s*%([^)]+%)", severity = "LOW", type = "Debug Console Output"},
                    {pattern = "alert%s*%([^)]+%)", severity = "LOW", type = "Debug Alert"},
                    
                    -- Exposed Configuration
                    {pattern = "password%s*[:=]%s*['\"]([^'\"]{4,})['\"]", severity = "CRITICAL", type = "Password"},
                    {pattern = "username%s*[:=]%s*['\"]([^'\"]{3,})['\"]", severity = "MEDIUM", type = "Username"},
                    {pattern = "database[_%-]?url%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "CRITICAL", type = "Database URL"},
                    {pattern = "redis[_%-]?url%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "HIGH", type = "Redis URL"},
                    
                    -- Email and Contact Information
                    {pattern = "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]{2,})", severity = "LOW", type = "Email Address"},
                    {pattern = "phone%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "LOW", type = "Phone Number"},
                    
                    -- Internal URLs and Endpoints  
                    {pattern = "localhost[:0-9]*", severity = "MEDIUM", type = "Localhost Reference"},
                    {pattern = "192%.168%.[0-9]+%.[0-9]+", severity = "MEDIUM", type = "Internal IP Address"},
                    {pattern = "10%.[0-9]+%.[0-9]+%.[0-9]+", severity = "MEDIUM", type = "Internal IP Address"},
                    
                    -- Source Maps and Build Info
                    {pattern = "sourceMappingURL", severity = "LOW", type = "Source Map Exposed"},
                    {pattern = "webpack://", severity = "LOW", type = "Webpack Source Path"},
                    {pattern = "node_modules", severity = "LOW", type = "Node Modules Path"},
                    
                    -- Shopify-specific sensitive data
                    {pattern = "shop[_%-]?domain%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "MEDIUM", type = "Shop Domain"},
                    {pattern = "customer[_%-]?token%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "HIGH", type = "Customer Token"},
                    {pattern = "cart[_%-]?token%s*[:=]%s*['\"]([^'\"]+)['\"]", severity = "MEDIUM", type = "Cart Token"}
                }
                
                for _, vuln in ipairs(vulnerability_patterns) do
                    for match in string.gmatch(body, vuln.pattern) do
                        table.insert(secrets_found, {
                            endpoint = endpoint,
                            pattern = vuln.type,
                            value = match,
                            url = url,
                            severity = vuln.severity
                        })
                        log("Found " .. vuln.severity .. " issue: " .. vuln.type .. " = " .. match .. " at " .. url)
                    end
                end
                
                -- Check for error messages that reveal system information
                local error_patterns = {
                    "Warning:", "Notice:", "Fatal error:", "Parse error:", "Call to undefined",
                    "mysql_", "postgresql", "ORA-[0-9]+", "Microsoft OLE DB", 
                    "Stack trace:", "Exception in thread", "NullPointerException",
                    "Uncaught exception", "syntax error", "undefined method"
                }
                
                for _, error_pattern in ipairs(error_patterns) do
                    if string.match(body, error_pattern) then
                        table.insert(secrets_found, {
                            endpoint = endpoint,
                            pattern = "Error Message Disclosure",
                            value = error_pattern,
                            url = url,
                            severity = "MEDIUM"
                        })
                        log("Found error disclosure: " .. error_pattern .. " at " .. url)
                    end
                end
                
                -- Check for version information
                local version_patterns = {
                    "version['\"]?%s*[:=]%s*['\"]([0-9.]+)['\"]",
                    "jQuery%s+v?([0-9.]+)",
                    "Bootstrap%s+v?([0-9.]+)",
                    "React%s+([0-9.]+)"
                }
                
                for _, version_pattern in ipairs(version_patterns) do
                    for match in string.gmatch(body, version_pattern) do
                        table.insert(secrets_found, {
                            endpoint = endpoint,
                            pattern = "Version Disclosure",
                            value = match,
                            url = url,
                            severity = "LOW"
                        })
                        log("Found version info: " .. match .. " at " .. url)
                    end
                end
                
                break -- If HTTPS worked, don't try HTTP
            else
                log("No response from " .. url .. " (status: " .. tostring(status) .. ", error: " .. tostring(err) .. ")")
                
                -- Log interesting status codes
                if status and (status == 403 or status == 401 or status == 500) then
                    table.insert(secrets_found, {
                        endpoint = endpoint,
                        pattern = "Interesting Status Code",
                        value = "HTTP " .. status,
                        url = url,
                        severity = "LOW"
                    })
                    log("Interesting status code " .. status .. " at " .. url)
                end
            end
        end
        
        -- Rate limiting
        sleep(0.3)
    end
    
    log("Found " .. #secrets_found .. " potential vulnerabilities and information disclosures")
    return secrets_found
end

-- Function to check JSON endpoint exposure and data leakage
local function check_json_endpoints(host)
    local exposed_endpoints = {}
    
    -- Extended list of endpoints to check
    local extended_endpoints = {
        "/products.json", "/collections.json", "/cart.json", "/checkout.json",
        "/customer.json", "/orders.json", "/customers.json", "/pages.json",
        "/blogs.json", "/articles.json", "/metafields.json", "/variants.json",
        "/recommendations/products.json", "/search.json", "/localization.json",
        "/cart/add.js", "/cart/update.js", "/cart/change.js", "/cart/clear.js",
        "/search/suggest.json", "/products/recommendations.json",
        "/account.json", "/addresses.json", "/orders/tracking.json",
        -- Admin endpoints that might be exposed
        "/admin/products.json", "/admin/orders.json", "/admin/customers.json",
        "/admin/themes.json", "/admin/webhooks.json", "/admin/shop.json",
        -- API endpoints
        "/api/products", "/api/collections", "/api/customers", "/api/orders",
        "/storefront-api/products", "/storefront-api/collections",
        -- Development/staging endpoints
        "/dev/products.json", "/staging/products.json", "/test/products.json",
        "/debug/cart.json", "/debug/products.json"
    }
    
    log("Checking JSON endpoints and data exposure on " .. host)
    
    for _, endpoint in ipairs(extended_endpoints) do
        -- Try both HTTPS and HTTP
        for _, protocol in ipairs({"https://", "http://"}) do
            local url = protocol .. host .. endpoint
            log("Testing JSON endpoint: " .. url)
            
            local status, body, headers, err = http.get(url, {
                ["User-Agent"] = "RegTech-Shopify-Scanner/1.0",
                ["Accept"] = "application/json, text/javascript, */*"
            }, 8)
            
            if status and status >= 200 and status < 400 and body and #body > 0 then
                log("Got response from " .. url .. " (status: " .. status .. ", size: " .. #body .. " bytes)")
                
                local info = {
                    endpoint = endpoint,
                    status = status,
                    size = #body,
                    has_data = false,
                    sensitive_fields = {},
                    risk_level = "LOW",
                    data_types = {},
                    url = url
                }
                
                -- Try to parse as JSON
                local success, parsed = pcall(function()
                    return json.decode(body)
                end)
                
                if success and parsed then
                    log("Successfully parsed JSON from " .. url)
                    
                    -- Analyze data structure
                    if type(parsed) == "table" then
                        -- Count items
                        if parsed.products and type(parsed.products) == "table" then
                            local count = #parsed.products
                            info.has_data = count > 0
                            info.product_count = count
                            table.insert(info.data_types, "products(" .. count .. ")")
                            if count > 100 then info.risk_level = "HIGH" end
                        end
                        
                        if parsed.collections and type(parsed.collections) == "table" then
                            local count = #parsed.collections
                            info.has_data = count > 0
                            info.collection_count = count
                            table.insert(info.data_types, "collections(" .. count .. ")")
                        end
                        
                        if parsed.customers and type(parsed.customers) == "table" then
                            local count = #parsed.customers
                            info.has_data = count > 0
                            info.customer_count = count
                            table.insert(info.data_types, "customers(" .. count .. ")")
                            info.risk_level = "CRITICAL"
                        end
                        
                        if parsed.orders and type(parsed.orders) == "table" then
                            local count = #parsed.orders
                            info.has_data = count > 0
                            info.order_count = count
                            table.insert(info.data_types, "orders(" .. count .. ")")
                            info.risk_level = "HIGH"
                        end
                    end
                    
                    -- Check for sensitive information in response body
                    local body_lower = string.lower(body)
                    local sensitive_checks = {
                        {pattern = "email", severity = "HIGH", desc = "Email addresses"},
                        {pattern = "phone", severity = "MEDIUM", desc = "Phone numbers"},
                        {pattern = "address", severity = "MEDIUM", desc = "Physical addresses"},
                        {pattern = "customer", severity = "HIGH", desc = "Customer data"},
                        {pattern = "order", severity = "HIGH", desc = "Order information"},
                        {pattern = "price", severity = "LOW", desc = "Pricing data"},
                        {pattern = "inventory", severity = "MEDIUM", desc = "Inventory levels"},
                        {pattern = "discount", severity = "LOW", desc = "Discount codes"},
                        {pattern = "api[_%-]?key", severity = "CRITICAL", desc = "API keys"},
                        {pattern = "token", severity = "HIGH", desc = "Access tokens"},
                        {pattern = "secret", severity = "CRITICAL", desc = "Secrets"},
                        {pattern = "password", severity = "CRITICAL", desc = "Passwords"},
                        {pattern = "credit[_%-]?card", severity = "CRITICAL", desc = "Credit card data"},
                        {pattern = "payment", severity = "HIGH", desc = "Payment information"},
                        {pattern = "billing", severity = "HIGH", desc = "Billing data"},
                        {pattern = "social[_%-]?security", severity = "CRITICAL", desc = "SSN data"},
                        {pattern = "tax[_%-]?id", severity = "HIGH", desc = "Tax IDs"},
                        {pattern = "bank", severity = "CRITICAL", desc = "Banking information"}
                    }
                    
                    for _, check in ipairs(sensitive_checks) do
                        if string.match(body_lower, check.pattern) then
                            table.insert(info.sensitive_fields, {
                                type = check.desc,
                                severity = check.severity
                            })
                            
                            -- Escalate risk level
                            if check.severity == "CRITICAL" and info.risk_level ~= "CRITICAL" then
                                info.risk_level = "CRITICAL"
                            elseif check.severity == "HIGH" and info.risk_level == "LOW" then
                                info.risk_level = "HIGH"
                            elseif check.severity == "MEDIUM" and info.risk_level == "LOW" then
                                info.risk_level = "MEDIUM"
                            end
                            
                            log("Found sensitive data (" .. check.severity .. "): " .. check.desc .. " in " .. url)
                        end
                    end
                    
                    -- Check for overly detailed product/inventory information
                    if string.match(body_lower, "inventory[_%-]?quantity") or 
                       string.match(body_lower, "stock[_%-]?level") or
                       string.match(body_lower, "cost[_%-]?price") then
                        info.risk_level = "MEDIUM"
                        table.insert(info.sensitive_fields, {
                            type = "Detailed inventory data",
                            severity = "MEDIUM"
                        })
                    end
                    
                else
                    -- Even if not valid JSON, check if it contains data
                    if #body > 100 then
                        info.has_data = true
                        table.insert(info.data_types, "non-json-data")
                    end
                end
                
                -- Special handling for .js endpoints (JSONP)
                if string.match(endpoint, "%.js$") then
                    if string.match(body, "^[a-zA-Z_][a-zA-Z0-9_]*%s*%(") then
                        info.has_data = true
                        table.insert(info.data_types, "jsonp")
                        log("Found JSONP endpoint: " .. url)
                    end
                end
                
                -- Log findings
                if info.has_data or #info.sensitive_fields > 0 then
                    log("EXPOSURE DETECTED: " .. url .. " - Risk: " .. info.risk_level .. 
                        " - Data types: " .. table.concat(info.data_types, ", ") .. 
                        " - Sensitive fields: " .. #info.sensitive_fields)
                end
                
                table.insert(exposed_endpoints, info)
                break -- If HTTPS worked, don't try HTTP
            else
                log("No data from " .. url .. " (status: " .. tostring(status) .. ")")
            end
        end
        
        -- Rate limiting
        sleep(0.2)
    end
    
    log("Found " .. #exposed_endpoints .. " exposed JSON/data endpoints")
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
    local is_shopify, shopify_reason, dev_indicators = is_shopify_store(target_host)
    
    local analysis = {
        is_shopify_store = is_shopify,
        shopify_detection_reason = shopify_reason,
        development_indicators = dev_indicators,
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
    
    -- Development store detection affects scoring
    if #dev_indicators > 0 then
        log("DEVELOPMENT STORE DETECTED - Enhanced security scanning")
        for _, indicator in ipairs(dev_indicators) do
            log("Dev indicator: " .. indicator)
        end
        
        analysis.security_score = analysis.security_score - (5 * #dev_indicators)
        if #dev_indicators >= 3 then
            analysis.risk_level = "MEDIUM"
            table.insert(analysis.compliance_issues, "Multiple development environment indicators detected")
            table.insert(analysis.recommendations, "Remove development indicators before production deployment")
        end
        
        set_metadata("shopify_development_indicators", #dev_indicators)
        set_metadata("shopify_development_details", table.concat(dev_indicators, "; "))
    end
    
    -- Check for hardcoded secrets and information disclosure
    analysis.hardcoded_secrets = check_hardcoded_secrets(target_host)
    if #analysis.hardcoded_secrets > 0 then
        local critical_count = 0
        local high_count = 0
        local medium_count = 0
        local low_count = 0
        
        for _, secret in ipairs(analysis.hardcoded_secrets) do
            if secret.severity == "CRITICAL" then
                critical_count = critical_count + 1
            elseif secret.severity == "HIGH" then
                high_count = high_count + 1
            elseif secret.severity == "MEDIUM" then
                medium_count = medium_count + 1
            else
                low_count = low_count + 1
            end
        end
        
        -- Score based on severity
        analysis.security_score = analysis.security_score - (critical_count * 40) - (high_count * 25) - (medium_count * 10) - (low_count * 3)
        
        if critical_count > 0 then
            analysis.risk_level = "CRITICAL"
            table.insert(analysis.compliance_issues, "Critical secrets/information disclosed (" .. critical_count .. " findings)")
            table.insert(analysis.recommendations, "URGENT: Remove all API keys, passwords, and secrets from client-side code")
        elseif high_count > 0 then
            if analysis.risk_level ~= "CRITICAL" then analysis.risk_level = "HIGH" end
            table.insert(analysis.compliance_issues, "Sensitive information disclosed (" .. high_count .. " findings)")
            table.insert(analysis.recommendations, "Remove sensitive data exposure from public endpoints")
        elseif medium_count > 0 then
            if analysis.risk_level == "LOW" then analysis.risk_level = "MEDIUM" end
        end
        
        log("SECURITY FINDINGS: " .. #analysis.hardcoded_secrets .. " total (" .. 
            critical_count .. " critical, " .. high_count .. " high, " .. 
            medium_count .. " medium, " .. low_count .. " low)")
        
        set_metadata("shopify_secrets_critical", critical_count)
        set_metadata("shopify_secrets_high", high_count)
        set_metadata("shopify_secrets_medium", medium_count)
        set_metadata("shopify_secrets_low", low_count)
    end
    
    -- Check JSON endpoint exposure
    analysis.exposed_json_endpoints = check_json_endpoints(target_host)
    if #analysis.exposed_json_endpoints > 0 then
        local critical_endpoints = 0
        local high_endpoints = 0
        local medium_endpoints = 0
        
        for _, endpoint in ipairs(analysis.exposed_json_endpoints) do
            if endpoint.risk_level == "CRITICAL" then
                critical_endpoints = critical_endpoints + 1
                analysis.security_score = analysis.security_score - 30
                analysis.risk_level = "CRITICAL"
                table.insert(analysis.compliance_issues, "CRITICAL data exposure: " .. endpoint.endpoint)
            elseif endpoint.risk_level == "HIGH" then
                high_endpoints = high_endpoints + 1
                analysis.security_score = analysis.security_score - 20
                if analysis.risk_level ~= "CRITICAL" then analysis.risk_level = "HIGH" end
                table.insert(analysis.compliance_issues, "Sensitive data exposed: " .. endpoint.endpoint)
            elseif endpoint.risk_level == "MEDIUM" then
                medium_endpoints = medium_endpoints + 1
                analysis.security_score = analysis.security_score - 10
                if analysis.risk_level == "LOW" then analysis.risk_level = "MEDIUM" end
            elseif endpoint.has_data then
                analysis.security_score = analysis.security_score - 5
            end
        end
        
        if critical_endpoints > 0 or high_endpoints > 0 then
            table.insert(analysis.recommendations, "Restrict access to sensitive JSON endpoints")
        end
        
        log("JSON ENDPOINTS: " .. #analysis.exposed_json_endpoints .. " exposed (" .. 
            critical_endpoints .. " critical, " .. high_endpoints .. " high, " .. 
            medium_endpoints .. " medium)")
        
        set_metadata("shopify_endpoints_critical", critical_endpoints)
        set_metadata("shopify_endpoints_high", high_endpoints)
        set_metadata("shopify_endpoints_medium", medium_endpoints)
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