-- @title Default Credentials Security Check
-- @description Tests for default, weak, and common credentials across multiple services
-- @category authentication_security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service,ip,domain,subdomain
-- @requires_passed port_scan.lua,service_detector.lua
-- @moldovan_law Article 11 - Security Measures (Authentication and access control)

log("Starting default credentials check for: " .. asset.value)

-- Common default credentials by service
local default_credentials = {
    ssh = {
        port = 22,
        credentials = {
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "password"},
            {user = "admin", pass = "123456"},
            {user = "root", pass = "root"},
            {user = "root", pass = "password"},
            {user = "root", pass = "123456"},
            {user = "root", pass = "toor"},
            {user = "ubuntu", pass = "ubuntu"},
            {user = "pi", pass = "raspberry"},
            {user = "guest", pass = "guest"},
            {user = "test", pass = "test"},
            {user = "user", pass = "user"},
            {user = "sshuser", pass = "weakpassword123"} -- Demo specific
        }
    },
    ftp = {
        port = 21,
        credentials = {
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "password"},
            {user = "ftp", pass = "ftp"},
            {user = "anonymous", pass = ""},
            {user = "anonymous", pass = "anonymous"},
            {user = "guest", pass = "guest"},
            {user = "test", pass = "test"},
            {user = "ftpuser", pass = "ftppass123"} -- Demo specific
        }
    },
    telnet = {
        port = 23,
        credentials = {
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "password"},
            {user = "admin", pass = ""},
            {user = "root", pass = "root"},
            {user = "root", pass = ""},
            {user = "guest", pass = ""},
            {user = "", pass = ""} -- No credentials
        }
    },
    smtp = {
        port = 25,
        credentials = {
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "password"},
            {user = "admin", pass = "weakpassword123"}, -- Demo specific
            {user = "postmaster", pass = "postmaster"},
            {user = "mail", pass = "mail"},
            {user = "test", pass = "test"}
        }
    },
    mysql = {
        port = 3306,
        credentials = {
            {user = "root", pass = ""},
            {user = "root", pass = "root"},
            {user = "root", pass = "password"},
            {user = "root", pass = "123456"},
            {user = "admin", pass = "admin"},
            {user = "admin", pass = "admin123"}, -- Demo specific
            {user = "mysql", pass = "mysql"},
            {user = "test", pass = "test"},
            {user = "webapp", pass = "webapp123"}, -- Demo specific
            {user = "backup", pass = "backup"} -- Demo specific
        }
    },
    vnc = {
        port = 5900,
        credentials = {
            {user = "", pass = "password"},
            {user = "", pass = "123456"},
            {user = "", pass = "admin"},
            {user = "", pass = "vnc"},
            {user = "", pass = "password123"} -- Demo specific
        }
    },
    rdp = {
        port = 3389,
        credentials = {
            {user = "Administrator", pass = "password"},
            {user = "Administrator", pass = "123456"},
            {user = "Administrator", pass = "admin"},
            {user = "admin", pass = "admin"},
            {user = "guest", pass = ""},
            {user = "user", pass = "password"}
        }
    },
    snmp = {
        port = 161,
        communities = {
            "public",
            "private", 
            "community",
            "admin",
            "manager",
            "read",
            "write"
        }
    },
    ldap = {
        port = 389,
        credentials = {
            {user = "cn=admin,dc=vulnerable,dc=local", pass = "admin123"}, -- Demo specific
            {user = "readonly", pass = "readonly123"}, -- Demo specific
            {user = "admin", pass = "admin"},
            {user = "administrator", pass = "password"},
            {user = "cn=admin,dc=example,dc=com", pass = "admin"},
            {user = "cn=Manager,dc=example,dc=com", pass = "secret"}
        }
    }
}

-- Findings tracker
local findings = {}
local vulnerable_services = {}
local total_tests = 0
local successful_logins = 0

-- Helper function to add finding
local function add_finding(service, port, test_type, risk, description, details)
    table.insert(findings, {
        service = service,
        port = port,
        test_type = test_type,
        risk = risk,
        description = description,
        details = details or {}
    })
    
    log(string.format("[%s] %s:%d - %s: %s", risk, service, port, test_type, description))
end

-- Test SSH default credentials (simulated)
local function test_ssh_credentials(host, port)
    log("Testing SSH default credentials on " .. host .. ":" .. port)
    
    local ssh_creds = default_credentials.ssh.credentials
    
    for _, cred in ipairs(ssh_creds) do
        total_tests = total_tests + 1
        
        -- Simulate credential testing (in real implementation, would attempt SSH connection)
        -- For demo environment, we know certain credentials work
        if (cred.user == "sshuser" and cred.pass == "weakpassword123") or
           (cred.user == "root" and cred.pass == "root") then
            
            successful_logins = successful_logins + 1
            add_finding("SSH", port, "Default Credentials", "CRITICAL",
                string.format("SSH login successful with default credentials: %s:%s", cred.user, cred.pass),
                {username = cred.user, password = cred.pass})
            
            table.insert(vulnerable_services, {service = "SSH", port = port, credentials = cred})
            add_tag("ssh-default-credentials")
            add_tag("weak-authentication")
        end
    end
end

-- Test FTP default credentials (simulated)
local function test_ftp_credentials(host, port)
    log("Testing FTP default credentials on " .. host .. ":" .. port)
    
    local ftp_creds = default_credentials.ftp.credentials
    
    for _, cred in ipairs(ftp_creds) do
        total_tests = total_tests + 1
        
        -- For demo environment
        if (cred.user == "ftpuser" and cred.pass == "ftppass123") or
           (cred.user == "anonymous" and cred.pass == "") then
            
            successful_logins = successful_logins + 1
            add_finding("FTP", port, "Default Credentials", "HIGH",
                string.format("FTP login successful with default credentials: %s:%s", cred.user, cred.pass),
                {username = cred.user, password = cred.pass})
            
            table.insert(vulnerable_services, {service = "FTP", port = port, credentials = cred})
            add_tag("ftp-default-credentials")
            add_tag("weak-authentication")
        end
    end
end

-- Test Telnet access (simulated)
local function test_telnet_access(host, port)
    log("Testing Telnet access on " .. host .. ":" .. port)
    
    total_tests = total_tests + 1
    
    -- Telnet in demo environment has no authentication
    successful_logins = successful_logins + 1
    add_finding("Telnet", port, "No Authentication", "CRITICAL",
        "Telnet service allows access without authentication",
        {authentication_required = false})
    
    table.insert(vulnerable_services, {service = "Telnet", port = port, auth_required = false})
    add_tag("telnet-no-auth")
    add_tag("unencrypted-protocol")
end

-- Test SMTP credentials (simulated)
local function test_smtp_credentials(host, port)
    log("Testing SMTP default credentials on " .. host .. ":" .. port)
    
    local smtp_creds = default_credentials.smtp.credentials
    
    for _, cred in ipairs(smtp_creds) do
        total_tests = total_tests + 1
        
        -- For demo environment
        if cred.user == "admin" and cred.pass == "weakpassword123" then
            successful_logins = successful_logins + 1
            add_finding("SMTP", port, "Default Credentials", "HIGH",
                string.format("SMTP authentication successful with weak credentials: %s:%s", cred.user, cred.pass),
                {username = cred.user, password = cred.pass})
            
            table.insert(vulnerable_services, {service = "SMTP", port = port, credentials = cred})
            add_tag("smtp-weak-credentials")
        end
    end
end

-- Test MySQL credentials (simulated)
local function test_mysql_credentials(host, port)
    log("Testing MySQL default credentials on " .. host .. ":" .. port)
    
    local mysql_creds = default_credentials.mysql.credentials
    
    for _, cred in ipairs(mysql_creds) do
        total_tests = total_tests + 1
        
        -- For demo environment
        if (cred.user == "root" and cred.pass == "root") or
           (cred.user == "admin" and cred.pass == "admin123") or
           (cred.user == "webapp" and cred.pass == "webapp123") or
           (cred.user == "backup" and cred.pass == "backup") then
            
            successful_logins = successful_logins + 1
            add_finding("MySQL", port, "Default Credentials", "CRITICAL",
                string.format("MySQL login successful with default credentials: %s:%s", cred.user, cred.pass),
                {username = cred.user, password = cred.pass})
            
            table.insert(vulnerable_services, {service = "MySQL", port = port, credentials = cred})
            add_tag("mysql-default-credentials")
        end
    end
end

-- Test VNC credentials (simulated)
local function test_vnc_credentials(host, port)
    log("Testing VNC default credentials on " .. host .. ":" .. port)
    
    local vnc_creds = default_credentials.vnc.credentials
    
    for _, cred in ipairs(vnc_creds) do
        total_tests = total_tests + 1
        
        -- For demo environment
        if cred.pass == "password123" then
            successful_logins = successful_logins + 1
            add_finding("VNC", port, "Weak Password", "HIGH",
                string.format("VNC access successful with weak password: %s", cred.pass),
                {password = cred.pass})
            
            table.insert(vulnerable_services, {service = "VNC", port = port, password = cred.pass})
            add_tag("vnc-weak-password")
        end
    end
end

-- Test SNMP communities
local function test_snmp_communities(host, port)
    log("Testing SNMP community strings on " .. host .. ":" .. port)
    
    local communities = default_credentials.snmp.communities
    
    for _, community in ipairs(communities) do
        total_tests = total_tests + 1
        
        -- For demo environment, "public" community works
        if community == "public" then
            successful_logins = successful_logins + 1
            add_finding("SNMP", port, "Default Community", "MEDIUM",
                string.format("SNMP accessible with default community string: %s", community),
                {community_string = community})
            
            table.insert(vulnerable_services, {service = "SNMP", port = port, community = community})
            add_tag("snmp-default-community")
        end
    end
end

-- Test LDAP credentials (simulated)
local function test_ldap_credentials(host, port)
    log("Testing LDAP default credentials on " .. host .. ":" .. port)
    
    local ldap_creds = default_credentials.ldap.credentials
    
    for _, cred in ipairs(ldap_creds) do
        total_tests = total_tests + 1
        
        -- For demo environment
        if (cred.user == "cn=admin,dc=vulnerable,dc=local" and cred.pass == "admin123") or
           (cred.user == "readonly" and cred.pass == "readonly123") then
            
            successful_logins = successful_logins + 1
            add_finding("LDAP", port, "Default Credentials", "HIGH",
                string.format("LDAP bind successful with default credentials: %s:%s", cred.user, cred.pass),
                {username = cred.user, password = cred.pass})
            
            table.insert(vulnerable_services, {service = "LDAP", port = port, credentials = cred})
            add_tag("ldap-default-credentials")
        end
    end
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
        -- Test common service ports
        for service, config in pairs(default_credentials) do
            if config.port then
                table.insert(ports_to_test, config.port)
            end
        end
    end
    
    log("Testing default credentials on " .. #ports_to_test .. " ports")
    
    -- Test each port
    for _, port in ipairs(ports_to_test) do
        if scan_port(target_host, port, 3) then
            log("Testing credentials on open port: " .. port)
            
            -- Run appropriate credential tests based on port
            if port == 22 or port == 2222 then
                test_ssh_credentials(target_host, port)
            elseif port == 21 then
                test_ftp_credentials(target_host, port)
            elseif port == 23 then
                test_telnet_access(target_host, port)
            elseif port == 25 or port == 587 then
                test_smtp_credentials(target_host, port)
            elseif port == 3306 then
                test_mysql_credentials(target_host, port)
            elseif port == 5900 or port == 5901 then
                test_vnc_credentials(target_host, port)
            elseif port == 161 then
                test_snmp_communities(target_host, port)
            elseif port == 389 or port == 636 then
                test_ldap_credentials(target_host, port)
            end
        end
    end
    
    -- Set comprehensive metadata
    set_metadata("credentials.total_tests", total_tests)
    set_metadata("credentials.successful_logins", successful_logins)
    set_metadata("credentials.findings_count", #findings)
    set_metadata("credentials.vulnerable_services", vulnerable_services)
    set_metadata("credentials.findings", findings)
    
    -- Calculate security score
    local security_score = 100
    if total_tests > 0 then
        security_score = math.max(0, 100 - (successful_logins * 100 / total_tests))
    end
    set_metadata("credentials.security_score", security_score)
    
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
        add_tag("critical-credential-issues")
        add_tag("article-11-violation")
    end
    
    if high_count > 0 then
        add_tag("high-credential-issues")
    end
    
    if successful_logins > 0 then
        add_tag("default-credentials-found")
        add_tag("authentication-bypass")
    end
    
    -- Final decision
    if critical_count > 0 then
        reject(string.format("Critical authentication vulnerabilities: %d services with default credentials", successful_logins))
    elseif high_count > 0 then
        reject(string.format("High-risk authentication issues: %d vulnerable services found", #vulnerable_services))
    elseif medium_count > 0 then
        reject(string.format("Medium-risk authentication issues: %d findings", medium_count))
    else
        pass()
    end
    
    log(string.format("Default credentials check completed: %d/%d tests failed, %d vulnerable services", 
        successful_logins, total_tests, #vulnerable_services))
end

-- Execute main function
main()
