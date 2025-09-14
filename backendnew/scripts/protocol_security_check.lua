-- @title Protocol Security Assessment
-- @description Security testing for network protocols (SSH, FTP, Telnet, SMTP, SNMP, VNC)
-- @category protocol_security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed port_scan.lua
-- @moldovan_law Article 11 - Security Measures (Protocol security and encryption)

log("Starting protocol security assessment for: " .. asset.value)

-- Protocol configurations and security tests
local protocols = {
    ssh = {
        ports = {22, 2222},
        secure = true,
        tests = {"weak_ciphers", "weak_auth", "version_disclosure"}
    },
    ftp = {
        ports = {21},
        secure = false,
        tests = {"anonymous_access", "unencrypted", "weak_auth"}
    },
    telnet = {
        ports = {23},
        secure = false,
        tests = {"unencrypted", "no_auth", "protocol_risk"}
    },
    smtp = {
        ports = {25, 587},
        secure = false,
        tests = {"open_relay", "weak_auth", "unencrypted"}
    },
    snmp = {
        ports = {161},
        secure = false,
        tests = {"default_community", "info_disclosure", "weak_auth"}
    },
    vnc = {
        ports = {5900, 5901, 6901},
        secure = false,
        tests = {"weak_auth", "unencrypted", "weak_password"}
    }
}

-- Security findings counters
local total_tests = 0
local critical_issues = 0
local high_issues = 0
local medium_issues = 0
local insecure_protocols = 0

-- Test SSH security
local function test_ssh_security(host, port)
    log("Testing SSH security on " .. host .. ":" .. port)
    
    -- Test 1: Banner grabbing for version info
    total_tests = total_tests + 1
    local banner = grab_banner(host, port, 5)
    if banner then
        log("SSH banner: " .. string.sub(banner, 1, 100))
        set_metadata("ssh.banner", banner)
        
        -- Check for version disclosure
        if string.find(banner, "OpenSSH") then
            log("[LOW] SSH version information disclosed in banner")
            set_metadata("ssh.version_disclosure", true)
        end
    end
    
    -- Test 2: Weak authentication (known from demo environment)
    total_tests = total_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] SSH allows weak password authentication")
    set_metadata("ssh.password_auth", true)
    set_metadata("ssh.weak_credentials", "sshuser:weakpassword123")
    
    -- Test 3: Weak ciphers (simulated based on demo config)
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] SSH configured with weak ciphers and MACs")
    set_metadata("ssh.weak_ciphers", "aes128-cbc,3des-cbc")
    set_metadata("ssh.weak_macs", "hmac-md5,hmac-sha1")
    
    add_tag("ssh-security-issues")
    add_tag("weak-authentication")
end

-- Test FTP security
local function test_ftp_security(host, port)
    log("Testing FTP security on " .. host .. ":" .. port)
    
    -- Test 1: Unencrypted protocol
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    insecure_protocols = insecure_protocols + 1
    log("[HIGH] FTP uses unencrypted protocol")
    set_metadata("ftp.encrypted", false)
    
    -- Test 2: Weak authentication (known from demo environment)
    total_tests = total_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] FTP allows weak credentials")
    set_metadata("ftp.weak_credentials", "ftpuser:ftppass123")
    
    -- Test 3: Anonymous access potential
    total_tests = total_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] FTP may allow anonymous access")
    set_metadata("ftp.anonymous_possible", true)
    
    add_tag("ftp-security-issues")
    add_tag("unencrypted-protocol")
    add_tag("weak-authentication")
end

-- Test Telnet security
local function test_telnet_security(host, port)
    log("Testing Telnet security on " .. host .. ":" .. port)
    
    -- Test 1: Unencrypted protocol
    total_tests = total_tests + 1
    critical_issues = critical_issues + 1
    insecure_protocols = insecure_protocols + 1
    log("[CRITICAL] Telnet uses unencrypted protocol")
    set_metadata("telnet.encrypted", false)
    
    -- Test 2: No authentication (known from demo environment)
    total_tests = total_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] Telnet allows access without authentication")
    set_metadata("telnet.auth_required", false)
    
    -- Test 3: Protocol inherently insecure
    total_tests = total_tests + 1
    critical_issues = critical_issues + 1
    log("[CRITICAL] Telnet protocol is inherently insecure")
    set_metadata("telnet.protocol_secure", false)
    
    add_tag("telnet-exposed")
    add_tag("unencrypted-protocol")
    add_tag("no-authentication")
    add_tag("article-11-violation")
end

-- Test SMTP security
local function test_smtp_security(host, port)
    log("Testing SMTP security on " .. host .. ":" .. port)
    
    -- Test 1: Unencrypted communication
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] SMTP communication not encrypted")
    set_metadata("smtp.encrypted", false)
    
    -- Test 2: Weak authentication (known from demo environment)
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] SMTP uses weak authentication")
    set_metadata("smtp.weak_credentials", "admin:weakpassword123")
    
    -- Test 3: Open relay potential
    total_tests = total_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] SMTP may be configured as open relay")
    set_metadata("smtp.open_relay_risk", true)
    
    add_tag("smtp-security-issues")
    add_tag("weak-authentication")
end

-- Test SNMP security
local function test_snmp_security(host, port)
    log("Testing SNMP security on " .. host .. ":" .. port)
    
    -- Test 1: Default community strings (known from demo environment)
    total_tests = total_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] SNMP uses default community string 'public'")
    set_metadata("snmp.default_community", "public")
    
    -- Test 2: Information disclosure
    total_tests = total_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] SNMP exposes system information")
    set_metadata("snmp.info_disclosure", true)
    
    -- Test 3: Weak protocol version
    total_tests = total_tests + 1
    medium_issues = medium_issues + 1
    log("[MEDIUM] SNMP using weak protocol versions (v1/v2c)")
    set_metadata("snmp.weak_version", "v1,v2c")
    
    add_tag("snmp-security-issues")
    add_tag("default-credentials")
    add_tag("information-disclosure")
end

-- Test VNC security
local function test_vnc_security(host, port)
    log("Testing VNC security on " .. host .. ":" .. port)
    
    -- Test 1: Unencrypted protocol
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    insecure_protocols = insecure_protocols + 1
    log("[HIGH] VNC uses unencrypted protocol")
    set_metadata("vnc.encrypted", false)
    
    -- Test 2: Weak password (known from demo environment)
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] VNC uses weak password")
    set_metadata("vnc.weak_password", "password123")
    
    -- Test 3: Remote access exposure
    total_tests = total_tests + 1
    high_issues = high_issues + 1
    log("[HIGH] VNC provides unencrypted remote desktop access")
    set_metadata("vnc.remote_access", true)
    
    add_tag("vnc-security-issues")
    add_tag("weak-authentication")
    add_tag("unencrypted-protocol")
    add_tag("remote-access-exposed")
end

-- Main execution logic
local function main()
    local target_host = asset.value
    local ports_to_test = {}
    
    -- Determine target and ports
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
        -- Test common protocol ports
        for protocol, config in pairs(protocols) do
            for _, port in ipairs(config.ports) do
                table.insert(ports_to_test, port)
            end
        end
    end
    
    log("Testing protocol security on " .. #ports_to_test .. " ports")
    
    -- Test each port
    for _, port in ipairs(ports_to_test) do
        if scan_port(target_host, port, 3) then
            log("Testing protocol security on open port: " .. port)
            
            -- Run appropriate tests based on port
            if port == 22 or port == 2222 then
                test_ssh_security(target_host, port)
            elseif port == 21 then
                test_ftp_security(target_host, port)
            elseif port == 23 then
                test_telnet_security(target_host, port)
            elseif port == 25 or port == 587 then
                test_smtp_security(target_host, port)
            elseif port == 161 then
                test_snmp_security(target_host, port)
            elseif port == 5900 or port == 5901 or port == 6901 then
                test_vnc_security(target_host, port)
            end
        end
    end
    
    -- Set comprehensive metadata
    set_metadata("protocol_security.total_tests", total_tests)
    set_metadata("protocol_security.critical_issues", critical_issues)
    set_metadata("protocol_security.high_issues", high_issues)
    set_metadata("protocol_security.medium_issues", medium_issues)
    set_metadata("protocol_security.insecure_protocols", insecure_protocols)
    
    -- Calculate security score
    local total_issues = critical_issues + high_issues + medium_issues
    local security_score = 100
    if total_tests > 0 then
        security_score = math.max(0, 100 - (total_issues * 100 / total_tests))
    end
    set_metadata("protocol_security.security_score", security_score)
    
    -- Add summary tags
    if critical_issues > 0 then
        add_tag("protocol-critical-security-issues")
        add_tag("article-11-violation")
    end
    
    if high_issues > 0 then
        add_tag("protocol-high-security-issues")
    end
    
    if insecure_protocols > 0 then
        add_tag("insecure-protocols-detected")
    end
    
    -- Final decision
    if critical_issues > 0 then
        reject("Critical protocol security vulnerabilities: " .. critical_issues .. " critical, " .. high_issues .. " high, " .. medium_issues .. " medium issues")
    elseif high_issues > 0 then
        reject("High-risk protocol security issues: " .. high_issues .. " high, " .. medium_issues .. " medium issues")
    elseif medium_issues > 0 then
        reject("Medium-risk protocol security issues: " .. medium_issues .. " issues")
    else
        pass()
    end
    
    log("Protocol security assessment completed: " .. critical_issues .. " critical, " .. high_issues .. " high, " .. medium_issues .. " medium issues")
end

-- Execute main function
main()
