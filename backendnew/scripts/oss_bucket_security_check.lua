-- @title OSS Bucket Security Check
-- @description Check OSS buckets for permission misconfigurations and security issues
-- @category cloud_security
-- @author RegTech Security Team
-- @version 1.0
-- @asset_types domain,subdomain,service
-- @requires_passed oss_bucket_detector.lua

log("Starting OSS bucket security check for: " .. asset.value)

-- Only run if OSS bucket was detected
if not asset.tags then
    log("No tags available, skipping OSS security check")
    na()
    return
end

local is_oss_bucket = false
for _, tag in ipairs(asset.tags) do
    if tag == "oss-bucket" then
        is_oss_bucket = true
        break
    end
end

if not is_oss_bucket then
    log("Asset is not an OSS bucket, skipping security check")
    na()
    return
end

log("Confirmed OSS bucket detected, proceeding with security analysis")

-- Security test configurations for different OSS providers
local security_tests = {
    -- Common tests for all providers
    common = {
        {
            name = "Public Read Test",
            description = "Test if bucket contents are publicly readable",
            paths = {"/", "/?list-type=2", "/?list", "/?delimiter=/"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    -- Check for XML listing responses
                    if string.match(body, "<ListBucketResult") or 
                       string.match(body, "<EnumerationResults") or
                       string.match(body, "<Contents>") then
                        return "CRITICAL", "Bucket contents are publicly listable"
                    end
                    
                    -- Check for HTML directory listings
                    if string.match(body, "<title>Index of") or 
                       string.match(body, "Parent Directory") then
                        return "CRITICAL", "Directory listing is publicly accessible"
                    end
                    
                    -- Check for JSON responses with file listings
                    if string.match(body, '"name"') and string.match(body, '"size"') then
                        return "CRITICAL", "JSON file listing is publicly accessible"
                    end
                end
                return "PASS", "Public read access properly restricted"
            end
        },
        {
            name = "Public Write Test",
            description = "Test if bucket allows public write access",
            method = "PUT",
            paths = {"/test-write-" .. os.time() .. ".txt"},
            body = "test-content",
            check_function = function(status, body, headers)
                if status >= 200 and status < 300 then
                    return "CRITICAL", "Bucket allows public write access"
                elseif status == 403 or status == 401 then
                    return "PASS", "Public write access properly denied"
                elseif status == 405 then
                    return "PASS", "Write method not allowed (good security)"
                else
                    return "INFO", "Write test inconclusive (status: " .. status .. ")"
                end
            end
        },
        {
            name = "Anonymous Access Test",
            description = "Test various anonymous access scenarios",
            paths = {"/.git", "/.env", "/config", "/backup", "/admin", "/api"},
            check_function = function(status, body, headers)
                if status == 200 and body and #body > 0 then
                    return "HIGH", "Sensitive path accessible anonymously"
                elseif status == 403 then
                    return "PASS", "Anonymous access properly restricted"
                else
                    return "INFO", "Path not found or inaccessible"
                end
            end
        },
        {
            name = "CORS Configuration Test",
            description = "Check for overly permissive CORS settings",
            method = "OPTIONS",
            paths = {"/"},
            headers = {
                ["Origin"] = "https://evil.com",
                ["Access-Control-Request-Method"] = "GET"
            },
            check_function = function(status, body, headers)
                if headers then
                    local cors_origin = headers["Access-Control-Allow-Origin"]
                    if cors_origin == "*" then
                        return "HIGH", "CORS allows all origins (*)"
                    elseif cors_origin and cors_origin ~= "" then
                        return "MEDIUM", "CORS configured - review allowed origins"
                    end
                end
                return "PASS", "No overly permissive CORS detected"
            end
        }
    },
    
    -- S3-specific tests
    s3 = {
        {
            name = "S3 ACL Test",
            description = "Test S3 bucket ACL configuration",
            paths = {"/?acl"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    if string.match(body, 'URI="http://acs.amazonaws.com/groups/global/AllUsers"') then
                        return "CRITICAL", "S3 bucket allows public access via ACL"
                    elseif string.match(body, 'URI="http://acs.amazonaws.com/groups/global/AuthenticatedUsers"') then
                        return "HIGH", "S3 bucket allows authenticated user access"
                    end
                end
                return "PASS", "S3 ACL properly configured or inaccessible"
            end
        },
        {
            name = "S3 Policy Test",
            description = "Test S3 bucket policy configuration",
            paths = {"/?policy"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    if string.match(body, '"Principal": "*"') or 
                       string.match(body, '"Principal": {"AWS": "*"}') then
                        return "CRITICAL", "S3 bucket policy allows public access"
                    end
                end
                return "PASS", "S3 bucket policy properly configured or inaccessible"
            end
        },
        {
            name = "S3 Website Configuration Test",
            description = "Check if S3 bucket is configured as a website",
            paths = {"/?website"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    return "MEDIUM", "S3 bucket configured as static website"
                end
                return "PASS", "S3 bucket not configured as website"
            end
        }
    },
    
    -- Azure-specific tests
    azure_blob = {
        {
            name = "Azure Container ACL Test",
            description = "Test Azure container access level",
            paths = {"/?restype=container&comp=acl"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    if string.match(body, 'PublicAccess="container"') then
                        return "CRITICAL", "Azure container allows public access"
                    elseif string.match(body, 'PublicAccess="blob"') then
                        return "HIGH", "Azure blobs are publicly accessible"
                    end
                end
                return "PASS", "Azure container access properly restricted"
            end
        }
    },
    
    -- GCS-specific tests
    gcs = {
        {
            name = "GCS IAM Test",
            description = "Test Google Cloud Storage IAM configuration",
            paths = {"/?fields=items(name,size)"},
            check_function = function(status, body, headers)
                if status == 200 and body then
                    if string.match(body, '"items"') then
                        return "CRITICAL", "GCS bucket allows public listing"
                    end
                end
                return "PASS", "GCS bucket access properly restricted"
            end
        }
    }
}

-- Function to perform HTTP request with specific method
local function make_request(url, method, headers, body, timeout)
    method = method or "GET"
    timeout = timeout or 10
    headers = headers or {}
    
    -- Add default headers
    headers["User-Agent"] = headers["User-Agent"] or "RegTech-OSS-Security-Scanner/1.0"
    
    if method == "GET" then
        return http.get(url, headers, timeout)
    elseif method == "PUT" then
        return http.request("PUT", url, body or "", headers, timeout)
    elseif method == "POST" then
        return http.post(url, body or "", headers, timeout)
    elseif method == "OPTIONS" then
        return http.request("OPTIONS", url, "", headers, timeout)
    elseif method == "HEAD" then
        return http.request("HEAD", url, "", headers, timeout)
    else
        return nil, nil, nil, "Unsupported HTTP method: " .. method
    end
end

-- Function to run security tests
local function run_security_tests(base_url, service_type)
    local test_results = {}
    local critical_issues = 0
    local high_issues = 0
    local medium_issues = 0
    
    -- Get tests for this service type
    local tests_to_run = security_tests.common or {}
    if security_tests[service_type] then
        for _, test in ipairs(security_tests[service_type]) do
            table.insert(tests_to_run, test)
        end
    end
    
    log("Running " .. #tests_to_run .. " security tests for " .. service_type)
    
    for _, test in ipairs(tests_to_run) do
        log("Running test: " .. test.name)
        
        local test_passed = false
        local best_result = nil
        local best_severity = "PASS"
        
        for _, path in ipairs(test.paths) do
            local test_url = base_url .. path
            local method = test.method or "GET"
            local headers = test.headers or {}
            local body = test.body
            
            log("Testing: " .. method .. " " .. test_url)
            
            local status, response_body, response_headers, err = make_request(test_url, method, headers, body)
            
            if status then
                local severity, message = test.check_function(status, response_body, response_headers)
                
                log("Test result: " .. severity .. " - " .. message)
                
                -- Track the most severe result for this test
                if severity == "CRITICAL" and best_severity ~= "CRITICAL" then
                    best_result = {severity = severity, message = message, url = test_url, status = status}
                    best_severity = "CRITICAL"
                elseif severity == "HIGH" and best_severity ~= "CRITICAL" and best_severity ~= "HIGH" then
                    best_result = {severity = severity, message = message, url = test_url, status = status}
                    best_severity = "HIGH"
                elseif severity == "MEDIUM" and best_severity ~= "CRITICAL" and best_severity ~= "HIGH" and best_severity ~= "MEDIUM" then
                    best_result = {severity = severity, message = message, url = test_url, status = status}
                    best_severity = "MEDIUM"
                elseif not best_result then
                    best_result = {severity = severity, message = message, url = test_url, status = status}
                    best_severity = severity
                end
            else
                log("Request failed: " .. (err or "unknown error"))
            end
            
            -- Rate limiting between requests
            sleep(0.5)
        end
        
        -- Store the best (most severe) result for this test
        if best_result then
            table.insert(test_results, {
                test_name = test.name,
                description = test.description,
                result = best_result
            })
            
            -- Count issues by severity
            if best_result.severity == "CRITICAL" then
                critical_issues = critical_issues + 1
                add_tag("oss-critical-security-issue")
            elseif best_result.severity == "HIGH" then
                high_issues = high_issues + 1
                add_tag("oss-high-security-issue")
            elseif best_result.severity == "MEDIUM" then
                medium_issues = medium_issues + 1
                add_tag("oss-medium-security-issue")
            end
        end
    end
    
    return test_results, critical_issues, high_issues, medium_issues
end

-- Function to analyze bucket configuration
local function analyze_bucket_configuration(base_url, service_type)
    log("Analyzing bucket configuration")
    
    -- Common configuration endpoints to check
    local config_endpoints = {
        "/?versioning",
        "/?logging",
        "/?encryption",
        "/?lifecycle",
        "/?notification",
        "/?replication"
    }
    
    local config_found = {}
    
    for _, endpoint in ipairs(config_endpoints) do
        local url = base_url .. endpoint
        local status, body, headers, err = http.get(url)
        
        if status == 200 and body then
            local config_type = string.match(endpoint, "/?(%w+)")
            table.insert(config_found, config_type)
            log("Configuration found: " .. config_type)
            
            -- Analyze specific configurations
            if config_type == "versioning" and string.match(body, "<Status>Enabled</Status>") then
                set_metadata("oss_versioning_enabled", true)
                add_tag("oss-versioning-enabled")
            elseif config_type == "encryption" then
                set_metadata("oss_encryption_configured", true)
                add_tag("oss-encryption-configured")
            elseif config_type == "logging" then
                set_metadata("oss_logging_configured", true)
                add_tag("oss-logging-configured")
            end
        end
        
        sleep(0.3)
    end
    
    if #config_found > 0 then
        set_metadata("oss_configurations_found", table.concat(config_found, ","))
    end
end

-- Main security check function
local function perform_security_check()
    -- Get OSS service type from metadata or tags
    local service_type = "common"  -- default
    
    if asset.tags then
        for _, tag in ipairs(asset.tags) do
            if string.match(tag, "^oss%-(.+)$") then
                service_type = string.match(tag, "^oss%-(.+)$")
                break
            end
        end
    end
    
    log("Performing security check for OSS service type: " .. service_type)
    
    -- Construct base URLs for testing
    local base_urls = {}
    local target_value = asset.value
    
    if asset.type == "domain" or asset.type == "subdomain" then
        table.insert(base_urls, "https://" .. target_value)
        table.insert(base_urls, "http://" .. target_value)
    elseif asset.type == "service" then
        local host, port_str = string.match(target_value, "([^:]+):(%d+)")
        if host and port_str then
            local port = tonumber(port_str)
            local scheme = (port == 443 or port == 8443) and "https" or "http"
            table.insert(base_urls, scheme .. "://" .. host .. ":" .. port)
        end
    end
    
    if #base_urls == 0 then
        log("No valid URLs to test")
        na()
        return
    end
    
    local total_critical = 0
    local total_high = 0
    local total_medium = 0
    local all_results = {}
    
    -- Test each base URL
    for _, base_url in ipairs(base_urls) do
        log("Testing security for: " .. base_url)
        
        local results, critical, high, medium = run_security_tests(base_url, service_type)
        
        total_critical = total_critical + critical
        total_high = total_high + high
        total_medium = total_medium + medium
        
        for _, result in ipairs(results) do
            table.insert(all_results, result)
        end
        
        -- Analyze bucket configuration
        analyze_bucket_configuration(base_url, service_type)
        
        -- Only test the first working URL to avoid redundancy
        if #results > 0 then
            break
        end
    end
    
    -- Set security metadata
    set_metadata("oss_security_tests_run", #all_results)
    set_metadata("oss_critical_issues", total_critical)
    set_metadata("oss_high_issues", total_high)
    set_metadata("oss_medium_issues", total_medium)
    
    -- Log detailed results
    for _, result in ipairs(all_results) do
        local log_msg = result.test_name .. ": " .. result.result.severity .. " - " .. result.result.message
        if result.result.url then
            log_msg = log_msg .. " (URL: " .. result.result.url .. ")"
        end
        log(log_msg)
    end
    
    -- Overall security assessment
    local security_score = 100
    security_score = security_score - (total_critical * 30)  -- -30 points per critical issue
    security_score = security_score - (total_high * 15)     -- -15 points per high issue
    security_score = security_score - (total_medium * 5)    -- -5 points per medium issue
    security_score = math.max(0, security_score)
    
    set_metadata("oss_security_score", security_score)
    
    -- Final decision
    if total_critical > 0 then
        add_tag("oss-security-critical")
        log("CRITICAL: OSS bucket has " .. total_critical .. " critical security issues")
        fail()
    elseif total_high > 0 then
        add_tag("oss-security-high-risk")
        log("HIGH RISK: OSS bucket has " .. total_high .. " high-risk security issues")
        fail()
    elseif total_medium > 0 then
        add_tag("oss-security-medium-risk")
        log("MEDIUM RISK: OSS bucket has " .. total_medium .. " medium-risk security issues")
        pass()  -- Medium risk issues are noted but not a failure
    else
        add_tag("oss-security-good")
        log("OSS bucket security configuration appears to be properly configured")
        pass()
    end
    
    log("OSS security score: " .. security_score .. "/100")
end

-- Execute security check
perform_security_check()

log("OSS bucket security check complete for " .. asset.value)
