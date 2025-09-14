-- @title Information Disclosure Security Check
-- @description Detects exposed sensitive files, backup files, configuration files, and directory listings
-- @category web_security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,domain,subdomain,ip
-- @requires_passed http_probe.lua
-- @moldovan_law Article 11 - Security Measures (Information protection and access control)

log("Starting information disclosure check for: " .. asset.value)

-- Sensitive file patterns to check
local sensitive_paths = {
    -- Backup files
    {path = "/backup.sql", risk = "CRITICAL", type = "Database Backup", description = "SQL database backup file exposed"},
    {path = "/backup.sql.bak", risk = "CRITICAL", type = "Database Backup", description = "SQL backup file with .bak extension"},
    {path = "/database.sql", risk = "CRITICAL", type = "Database Backup", description = "Database dump file exposed"},
    {path = "/dump.sql", risk = "CRITICAL", type = "Database Backup", description = "Database dump file exposed"},
    {path = "/backup.tar.gz", risk = "HIGH", type = "Archive Backup", description = "Compressed backup archive exposed"},
    {path = "/backup.zip", risk = "HIGH", type = "Archive Backup", description = "ZIP backup archive exposed"},
    {path = "/site-backup.tar.gz", risk = "HIGH", type = "Site Backup", description = "Website backup archive exposed"},
    
    -- Configuration files
    {path = "/.env", risk = "CRITICAL", type = "Environment Config", description = "Environment configuration file exposed"},
    {path = "/.env.bak", risk = "CRITICAL", type = "Environment Config", description = "Environment config backup exposed"},
    {path = "/config.env.backup", risk = "CRITICAL", type = "Environment Config", description = "Environment config backup exposed"},
    {path = "/config.php", risk = "HIGH", type = "Application Config", description = "PHP configuration file exposed"},
    {path = "/config.ini", risk = "HIGH", type = "Application Config", description = "INI configuration file exposed"},
    {path = "/config.xml", risk = "HIGH", type = "Application Config", description = "XML configuration file exposed"},
    {path = "/config.json", risk = "HIGH", type = "Application Config", description = "JSON configuration file exposed"},
    {path = "/settings.php", risk = "HIGH", type = "Application Config", description = "Application settings file exposed"},
    {path = "/wp-config.php", risk = "CRITICAL", type = "WordPress Config", description = "WordPress configuration file exposed"},
    {path = "/wp-config.php.bak", risk = "CRITICAL", type = "WordPress Config", description = "WordPress config backup exposed"},
    
    -- Version control
    {path = "/.git/", risk = "HIGH", type = "Git Repository", description = "Git repository exposed"},
    {path = "/.git/config", risk = "HIGH", type = "Git Config", description = "Git configuration file exposed"},
    {path = "/.git/HEAD", risk = "MEDIUM", type = "Git HEAD", description = "Git HEAD file exposed"},
    {path = "/.svn/", risk = "HIGH", type = "SVN Repository", description = "SVN repository exposed"},
    {path = "/.hg/", risk = "MEDIUM", type = "Mercurial Repository", description = "Mercurial repository exposed"},
    
    -- Log files
    {path = "/error.log", risk = "MEDIUM", type = "Error Log", description = "Error log file exposed"},
    {path = "/access.log", risk = "MEDIUM", type = "Access Log", description = "Access log file exposed"},
    {path = "/debug.log", risk = "MEDIUM", type = "Debug Log", description = "Debug log file exposed"},
    {path = "/application.log", risk = "MEDIUM", type = "Application Log", description = "Application log file exposed"},
    {path = "/logs/", risk = "MEDIUM", type = "Log Directory", description = "Log directory exposed"},
    
    -- Administrative interfaces
    {path = "/admin/", risk = "HIGH", type = "Admin Interface", description = "Administrative interface exposed"},
    {path = "/administrator/", risk = "HIGH", type = "Admin Interface", description = "Administrator interface exposed"},
    {path = "/phpmyadmin/", risk = "HIGH", type = "Database Admin", description = "phpMyAdmin interface exposed"},
    {path = "/adminer/", risk = "HIGH", type = "Database Admin", description = "Adminer interface exposed"},
    {path = "/server-info", risk = "MEDIUM", type = "Server Info", description = "Server information page exposed"},
    {path = "/server-status", risk = "MEDIUM", type = "Server Status", description = "Server status page exposed"},
    {path = "/info.php", risk = "HIGH", type = "PHP Info", description = "PHP information page exposed"},
    {path = "/phpinfo.php", risk = "HIGH", type = "PHP Info", description = "PHP information page exposed"},
    
    -- API documentation and endpoints
    {path = "/api/", risk = "MEDIUM", type = "API Endpoint", description = "API endpoint exposed"},
    {path = "/api/v1/", risk = "MEDIUM", type = "API Endpoint", description = "API v1 endpoint exposed"},
    {path = "/swagger/", risk = "MEDIUM", type = "API Documentation", description = "Swagger API documentation exposed"},
    {path = "/docs/", risk = "LOW", type = "Documentation", description = "Documentation directory exposed"},
    
    -- Temporary and test files
    {path = "/test.php", risk = "MEDIUM", type = "Test File", description = "Test PHP file exposed"},
    {path = "/test.html", risk = "LOW", type = "Test File", description = "Test HTML file exposed"},
    {path = "/temp/", risk = "MEDIUM", type = "Temporary Directory", description = "Temporary directory exposed"},
    {path = "/tmp/", risk = "MEDIUM", type = "Temporary Directory", description = "Temporary directory exposed"},
    {path = "/upload/", risk = "MEDIUM", type = "Upload Directory", description = "Upload directory exposed"},
    {path = "/uploads/", risk = "MEDIUM", type = "Upload Directory", description = "Uploads directory exposed"},
    
    -- Common sensitive files
    {path = "/robots.txt", risk = "LOW", type = "Robots File", description = "Robots.txt file (may reveal sensitive paths)"},
    {path = "/sitemap.xml", risk = "LOW", type = "Sitemap", description = "XML sitemap exposed"},
    {path = "/.htaccess", risk = "MEDIUM", type = "Apache Config", description = "Apache .htaccess file exposed"},
    {path = "/web.config", risk = "MEDIUM", type = "IIS Config", description = "IIS web.config file exposed"},
    
    -- SSH and SSL keys
    {path = "/id_rsa", risk = "CRITICAL", type = "SSH Private Key", description = "SSH private key exposed"},
    {path = "/id_dsa", risk = "CRITICAL", type = "SSH Private Key", description = "DSA private key exposed"},
    {path = "/private.key", risk = "CRITICAL", type = "Private Key", description = "Private key file exposed"},
    {path = "/server.key", risk = "CRITICAL", type = "SSL Private Key", description = "SSL private key exposed"},
    {path = "/cert.pem", risk = "MEDIUM", type = "Certificate", description = "Certificate file exposed"},
    
    -- Database files
    {path = "/database.sqlite", risk = "CRITICAL", type = "SQLite Database", description = "SQLite database file exposed"},
    {path = "/db.sqlite3", risk = "CRITICAL", type = "SQLite Database", description = "SQLite3 database file exposed"},
    {path = "/users.db", risk = "CRITICAL", type = "User Database", description = "User database file exposed"}
}

-- Directory listing indicators
local directory_listing_patterns = {
    "<title>Index of /",
    "Directory Listing For /",
    "<h1>Index of ",
    "Parent Directory",
    "<pre><img",
    "Directory listing for",
    "<table><tr><th",
    "autoindex"
}

-- Sensitive content patterns in responses
local sensitive_content_patterns = {
    {pattern = "password%s*[=:]", risk = "HIGH", type = "Password Disclosure"},
    {pattern = "api[_-]?key%s*[=:]", risk = "HIGH", type = "API Key Disclosure"},
    {pattern = "secret[_-]?key%s*[=:]", risk = "HIGH", type = "Secret Key Disclosure"},
    {pattern = "database[_-]?password", risk = "HIGH", type = "Database Password"},
    {pattern = "mysql[_-]?password", risk = "HIGH", type = "MySQL Password"},
    {pattern = "aws[_-]?access[_-]?key", risk = "CRITICAL", type = "AWS Access Key"},
    {pattern = "aws[_-]?secret[_-]?key", risk = "CRITICAL", type = "AWS Secret Key"},
    {pattern = "private[_-]?key", risk = "CRITICAL", type = "Private Key"},
    {pattern = "-----BEGIN [A-Z]+ PRIVATE KEY-----", risk = "CRITICAL", type = "Private Key Block"},
    {pattern = "jwt[_-]?secret", risk = "HIGH", type = "JWT Secret"},
    {pattern = "session[_-]?secret", risk = "MEDIUM", type = "Session Secret"},
    {pattern = "encryption[_-]?key", risk = "HIGH", type = "Encryption Key"}
}

-- Findings tracker
local findings = {}
local exposed_files = {}
local directory_listings = {}
local total_tests = 0
local exposed_count = 0

-- Helper function to add finding
local function add_finding(path, risk, type, description, details)
    table.insert(findings, {
        path = path,
        risk = risk,
        type = type,
        description = description,
        details = details or {}
    })
    
    log(string.format("[%s] %s: %s - %s", risk, type, path, description))
end

-- Check if response indicates directory listing
local function is_directory_listing(body)
    for _, pattern in ipairs(directory_listing_patterns) do
        if string.find(body, pattern) then
            return true
        end
    end
    return false
end

-- Analyze response content for sensitive information
local function analyze_content(body, path)
    local content_findings = {}
    
    for _, pattern_info in ipairs(sensitive_content_patterns) do
        if string.find(string.lower(body), string.lower(pattern_info.pattern)) then
            table.insert(content_findings, {
                pattern = pattern_info.pattern,
                risk = pattern_info.risk,
                type = pattern_info.type
            })
            
            add_finding(path, pattern_info.risk, pattern_info.type,
                string.format("Sensitive content detected: %s", pattern_info.type),
                {pattern = pattern_info.pattern, content_length = string.len(body)})
        end
    end
    
    return content_findings
end

-- Test a single path for exposure
local function test_path(base_url, path_info)
    local full_url = base_url .. path_info.path
    total_tests = total_tests + 1
    
    log("Testing path: " .. full_url)
    
    local response, err = http_get(full_url, {["User-Agent"] = "RegTech-Scanner/1.0"}, 10)
    
    if err then
        log("Request failed for " .. full_url .. ": " .. err)
        return
    end
    
    -- Check response status
    if response.status_code == 200 then
        exposed_count = exposed_count + 1
        
        -- File is accessible
        add_finding(path_info.path, path_info.risk, path_info.type, path_info.description,
            {
                status_code = response.status_code,
                content_length = string.len(response.body),
                content_type = response.headers["Content-Type"] or "unknown"
            })
        
        table.insert(exposed_files, {
            path = path_info.path,
            risk = path_info.risk,
            type = path_info.type,
            size = string.len(response.body)
        })
        
        -- Check for directory listing
        if is_directory_listing(response.body) then
            add_finding(path_info.path, "HIGH", "Directory Listing",
                "Directory listing enabled for " .. path_info.path,
                {listing_detected = true})
            
            table.insert(directory_listings, path_info.path)
            add_tag("directory-listing-enabled")
        end
        
        -- Analyze content for sensitive information
        local content_findings = analyze_content(response.body, path_info.path)
        if #content_findings > 0 then
            add_tag("sensitive-content-exposed")
        end
        
        -- Add specific tags based on file type
        if path_info.type == "Database Backup" then
            add_tag("database-backup-exposed")
        elseif path_info.type == "Environment Config" then
            add_tag("config-file-exposed")
        elseif path_info.type == "Private Key" or path_info.type == "SSH Private Key" then
            add_tag("private-key-exposed")
        elseif path_info.type == "Git Repository" then
            add_tag("git-repository-exposed")
        end
        
    elseif response.status_code == 403 then
        -- Forbidden - file exists but access denied
        add_finding(path_info.path, "MEDIUM", "File Exists (Forbidden)",
            string.format("File %s exists but access is forbidden", path_info.path),
            {status_code = response.status_code})
            
    elseif response.status_code == 401 then
        -- Unauthorized - file exists but requires authentication
        add_finding(path_info.path, "LOW", "File Exists (Auth Required)",
            string.format("File %s exists but requires authentication", path_info.path),
            {status_code = response.status_code})
    end
end

-- Main execution logic
local function main()
    local target_host = asset.value
    local base_url = ""
    
    -- Determine base URL based on asset type
    if asset.type == "service" then
        local host, port_str, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
        if not host or not port_str then
            host, port_str = string.match(asset.value, "([^:]+):(%d+)")
            protocol = "http"
        end
        
        if host and port_str then
            local port = tonumber(port_str)
            local scheme = "http"
            
            -- Determine scheme based on port
            if port == 443 or port == 8443 then
                scheme = "https"
            end
            
            base_url = scheme .. "://" .. host .. ":" .. port
        else
            log("Invalid service format: " .. asset.value)
            na()
            return
        end
    elseif asset.type == "domain" or asset.type == "subdomain" then
        -- Try both HTTP and HTTPS
        base_url = "http://" .. asset.value
        -- Note: In a full implementation, would test both HTTP and HTTPS
    elseif asset.type == "ip" then
        base_url = "http://" .. asset.value
    else
        log("Asset type not suitable for information disclosure check: " .. asset.type)
        na()
        return
    end
    
    log("Testing information disclosure on: " .. base_url)
    
    -- Test all sensitive paths
    for _, path_info in ipairs(sensitive_paths) do
        test_path(base_url, path_info)
        
        -- Rate limiting to avoid overwhelming the target
        if total_tests % 10 == 0 then
            sleep(0.5)
        end
    end
    
    -- Set comprehensive metadata
    set_metadata("info_disclosure.total_tests", total_tests)
    set_metadata("info_disclosure.exposed_files", exposed_count)
    set_metadata("info_disclosure.findings_count", #findings)
    set_metadata("info_disclosure.exposed_file_list", exposed_files)
    set_metadata("info_disclosure.directory_listings", directory_listings)
    set_metadata("info_disclosure.findings", findings)
    
    -- Calculate security score
    local security_score = 100
    if total_tests > 0 then
        security_score = math.max(0, 100 - (exposed_count * 100 / total_tests))
    end
    set_metadata("info_disclosure.security_score", security_score)
    
    -- Count findings by risk level
    local critical_count = 0
    local high_count = 0
    local medium_count = 0
    
    for _, finding in ipairs(findings) do
        if finding.risk == "CRITICAL" then
            critical_count = critical_count + 1
        elseif finding.risk == "HIGH" then
            high_count = high_count + 1
        elseif finding.risk == "MEDIUM" then
            medium_count = medium_count + 1
        end
    end
    
    -- Add summary tags
    if critical_count > 0 then
        add_tag("critical-info-disclosure")
        add_tag("article-11-violation")
    end
    
    if high_count > 0 then
        add_tag("high-info-disclosure")
    end
    
    if exposed_count > 0 then
        add_tag("sensitive-files-exposed")
        add_tag("information-disclosure")
    end
    
    if #directory_listings > 0 then
        add_tag("directory-browsing-enabled")
    end
    
    -- Final decision
    if critical_count > 0 then
        reject(string.format("Critical information disclosure: %d critical findings, %d files exposed", 
            critical_count, exposed_count))
    elseif high_count > 0 then
        reject(string.format("High-risk information disclosure: %d high-risk findings, %d files exposed", 
            high_count, exposed_count))
    elseif medium_count > 0 then
        reject(string.format("Medium-risk information disclosure: %d medium-risk findings", medium_count))
    elseif exposed_count > 0 then
        reject(string.format("Information disclosure detected: %d files exposed", exposed_count))
    else
        pass()
    end
    
    log(string.format("Information disclosure check completed: %d/%d files exposed, %d findings", 
        exposed_count, total_tests, #findings))
end

-- Execute main function
main()
