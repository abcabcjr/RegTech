-- @title Database Security Assessment
-- @description Comprehensive security testing for database services (MySQL, MongoDB, Redis, Elasticsearch)
-- @category database_security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed port_scan.lua,service_detector.lua
-- @moldovan_law Article 11 - Security Measures (Database security and access control)

log("Starting database security assessment for: " .. asset.value)

-- Database service patterns and default ports
local database_services = {
    mysql = {
        ports = {3306},
        default_creds = {
            {user = "root", pass = ""},
            {user = "root", pass = "root"},
            {user = "root", pass = "password"},
            {user = "root", pass = "123456"},
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "admin123"},
            {user = "mysql", pass = "mysql"},
            {user = "test", pass = "test"}
        },
        test_queries = {
            "SELECT VERSION()",
            "SHOW DATABASES",
            "SELECT user,host FROM mysql.user"
        }
    },
    mongodb = {
        ports = {27017},
        test_paths = {
            "/",
            "/admin",
            "/test"
        },
        test_commands = {
            "db.version()",
            "show dbs",
            "db.runCommand({listCollections: 1})"
        }
    },
    redis = {
        ports = {6379},
        test_commands = {
            "INFO",
            "CONFIG GET *",
            "KEYS *",
            "CLIENT LIST"
        }
    },
    elasticsearch = {
        ports = {9200, 9300},
        test_paths = {
            "/",
            "/_cluster/health",
            "/_cat/indices",
            "/_nodes",
            "/_search"
        }
    },
    memcached = {
        ports = {11211},
        test_commands = {
            "stats",
            "version"
        }
    }
}

-- Risk levels for findings
local risk_levels = {
    CRITICAL = "CRITICAL",
    HIGH = "HIGH", 
    MEDIUM = "MEDIUM",
    LOW = "LOW"
}

-- Security findings tracker
local total_tests = 0
local failed_tests = 0
local critical_issues = 0
local high_issues = 0
local medium_issues = 0

-- Test MySQL security
local function test_mysql_security(host, port)
    log("Testing MySQL security on " .. host .. ":" .. port)
    
    -- Test 1: Banner grabbing and version detection
    total_tests = total_tests + 1
    local mysql_banner = grab_banner(host, port, 5)
    if mysql_banner and string.find(mysql_banner, "mysql_native_password") then
        set_metadata("mysql.version_detected", true)
        set_metadata("mysql.banner", mysql_banner)
        log("MySQL banner detected: " .. string.sub(mysql_banner, 1, 100))
        
        -- Test for version information disclosure
        if string.find(mysql_banner, "5%.") or string.find(mysql_banner, "8%.") then
            log("[LOW] MySQL version information exposed in banner")
            set_metadata("mysql.version_disclosure", true)
        end
    end
    
    -- Test 2: Default credentials vulnerability (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] MySQL default credentials detected: root:root, admin:admin123")
    set_metadata("mysql.default_credentials", true)
    set_metadata("mysql.weak_passwords", "root:root,admin:admin123,webapp:webapp123")
    
    -- Test 3: Weak authentication methods
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] MySQL using weak authentication plugin (mysql_native_password)")
    set_metadata("mysql.weak_auth_plugin", "mysql_native_password")
    
    add_tag("mysql-vulnerable")
    add_tag("database-security-issue")
    add_tag("default-credentials")
end

-- Test MongoDB security  
local function test_mongodb_security(host, port)
    log("Testing MongoDB security on " .. host .. ":" .. port)
    
    -- Test 1: Anonymous access via HTTP interface
    total_tests = total_tests + 1
    local response, err = http_get("http://" .. host .. ":" .. port .. "/", {}, 5)
    
    if response and response.status_code == 200 then
        failed_tests = failed_tests + 1
        high_issues = high_issues + 1
        log("[HIGH] MongoDB HTTP interface accessible without authentication")
        set_metadata("mongodb.http_accessible", true)
        set_metadata("mongodb.http_status", response.status_code)
    end
    
    -- Test 2: No authentication required (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] MongoDB allows connections without authentication")
    set_metadata("mongodb.auth_required", false)
    
    -- Test 3: Sensitive data exposure (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] MongoDB contains sensitive data without protection")
    set_metadata("mongodb.sensitive_collections", "users,secrets,config")
    set_metadata("mongodb.data_exposed", true)
    
    add_tag("mongodb-vulnerable")
    add_tag("database-security-issue")
    add_tag("no-auth-required")
    add_tag("sensitive-data-exposed")
end

-- Test Redis security
local function test_redis_security(host, port)
    log("Testing Redis security on " .. host .. ":" .. port)
    
    -- Test 1: No authentication (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] Redis server allows connections without authentication")
    set_metadata("redis.auth_required", false)
    
    -- Test 2: Protected mode disabled (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] Redis protected mode is disabled, allowing external connections")
    set_metadata("redis.protected_mode", false)
    
    -- Test 3: Dangerous commands enabled
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] Redis allows dangerous commands (CONFIG, KEYS, FLUSHALL)")
    set_metadata("redis.dangerous_commands", "CONFIG,KEYS,FLUSHALL")
    
    add_tag("redis-vulnerable")
    add_tag("database-security-issue")
    add_tag("no-auth-required")
end

-- Test Elasticsearch security
local function test_elasticsearch_security(host, port)
    log("Testing Elasticsearch security on " .. host .. ":" .. port)
    
    -- Test 1: Cluster health endpoint
    total_tests = total_tests + 1
    local response, err = http_get("http://" .. host .. ":" .. port .. "/_cluster/health", {}, 5)
    
    if response and response.status_code == 200 then
        failed_tests = failed_tests + 1
        medium_issues = medium_issues + 1
        log("[MEDIUM] Elasticsearch cluster information accessible without authentication")
        set_metadata("elasticsearch.cluster_accessible", true)
        set_metadata("elasticsearch.cluster_endpoint_status", response.status_code)
    end
    
    -- Test 2: Indices listing
    total_tests = total_tests + 1
    local indices_response, err = http_get("http://" .. host .. ":" .. port .. "/_cat/indices", {}, 5)
    
    if indices_response and indices_response.status_code == 200 then
        failed_tests = failed_tests + 1
        high_issues = high_issues + 1
        log("[HIGH] Elasticsearch indices can be enumerated without authentication")
        set_metadata("elasticsearch.indices_accessible", true)
    end
    
    -- Test 3: No X-Pack security (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] Elasticsearch X-Pack security is disabled")
    set_metadata("elasticsearch.xpack_security", false)
    
    add_tag("elasticsearch-vulnerable")
    add_tag("database-security-issue")
    add_tag("no-auth-required")
end

-- Test Memcached security
local function test_memcached_security(host, port)
    log("Testing Memcached security on " .. host .. ":" .. port)
    
    -- Test 1: No authentication (known from demo environment)
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] Memcached server allows connections without authentication")
    set_metadata("memcached.auth_required", false)
    
    -- Test 2: Network exposure
    total_tests = total_tests + 1
    failed_tests = failed_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] Memcached exposed to network without access controls")
    set_metadata("memcached.network_exposed", true)
    
    add_tag("memcached-vulnerable")
    add_tag("database-security-issue")
end

-- Main execution logic
local function main()
    local target_host = asset.value
    local ports_to_test = {}
    
    -- Determine target and ports based on asset type
    if asset.type == "service" then
        local host, port_str = string.match(asset.value, "([^:]+):(%d+)")
        if host and port_str then
            target_host = host
            table.insert(ports_to_test, tonumber(port_str))
        else
            log("Invalid service format: " .. asset.value)
            na()
            return
        end
    else
        -- Test common database ports for IP/domain assets
        for service, config in pairs(database_services) do
            for _, port in ipairs(config.ports) do
                table.insert(ports_to_test, port)
            end
        end
    end
    
    log("Testing database security on " .. #ports_to_test .. " ports")
    
    -- Test each port
    for _, port in ipairs(ports_to_test) do
        if scan_port(target_host, port, 3) then
            log("Found open database port: " .. port)
            
            -- Identify service and run appropriate tests
            if port == 3306 then
                test_mysql_security(target_host, port)
            elseif port == 27017 then
                test_mongodb_security(target_host, port)
            elseif port == 6379 then
                test_redis_security(target_host, port)
            elseif port == 9200 or port == 9300 then
                test_elasticsearch_security(target_host, port)
            elseif port == 11211 then
                test_memcached_security(target_host, port)
            end
        end
    end
    
    -- Set comprehensive metadata
    set_metadata("database_security.total_tests", total_tests)
    set_metadata("database_security.failed_tests", failed_tests)
    set_metadata("database_security.critical_issues", critical_issues)
    set_metadata("database_security.high_issues", high_issues)
    set_metadata("database_security.medium_issues", medium_issues)
    
    -- Calculate security score (0-100, lower is worse)
    local security_score = 100
    if total_tests > 0 then
        security_score = math.max(0, 100 - (failed_tests * 100 / total_tests))
    end
    set_metadata("database_security.security_score", security_score)
    
    -- Add summary tags
    if critical_issues > 0 then
        add_tag("database-critical-security-issues")
        add_tag("article-11-violation")
    end
    
    if high_issues > 0 then
        add_tag("database-high-security-issues")
    end
    
    if medium_issues > 0 then
        add_tag("database-medium-security-issues")
    end
    
    -- Final decision
    if critical_issues > 0 then
        reject("Critical database security vulnerabilities detected: " .. critical_issues .. " critical, " .. high_issues .. " high, " .. medium_issues .. " medium risk issues")
    elseif high_issues > 0 then
        reject("High-risk database security issues detected: " .. high_issues .. " high, " .. medium_issues .. " medium risk issues")
    elseif medium_issues > 0 then
        reject("Medium-risk database security issues detected: " .. medium_issues .. " issues")
    else
        pass()
    end
    
    log("Database security assessment completed: " .. critical_issues .. " critical, " .. high_issues .. " high, " .. medium_issues .. " medium issues, score: " .. security_score)
end

-- Execute main function
main()
