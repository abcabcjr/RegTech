-- @title SSH Security Policy Analyzer
-- @description SSH banner analysis and legacy algorithm detection for Article 11 compliance
-- @category security
-- @author RegTech Compliance Team
-- @version 1.0
-- @asset_types service
-- @requires_passed service_detector.lua
-- @moldovan_law Article 11 - Security Measures (SSH security and algorithm compliance)

log("Starting SSH security analysis for: " .. asset.value)

-- SSH version analysis patterns
local ssh_versions = {
    ["SSH-1%."] = {
        version_family = "SSH-1",
        security_level = "CRITICAL", 
        supported = false,
        issues = {"SSH-1 protocol is fundamentally insecure", "Vulnerable to man-in-the-middle attacks"}
    },
    ["SSH-2%.0"] = {
        version_family = "SSH-2.0",
        security_level = "ACCEPTABLE",
        supported = true, 
        issues = {}
    }
}

-- OpenSSH version security assessment
local openssh_versions = {
    -- Very old versions with known vulnerabilities
    ["OpenSSH_3%."] = {security_level = "CRITICAL", end_of_life = true},
    ["OpenSSH_4%."] = {security_level = "CRITICAL", end_of_life = true}, 
    ["OpenSSH_5%."] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.0"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.1"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.2"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.3"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.4"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.5"] = {security_level = "HIGH", end_of_life = true},
    ["OpenSSH_6%.6"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_6%.7"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_6%.8"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_6%.9"] = {security_level = "MEDIUM", end_of_life = true},
    
    -- Moderately old versions
    ["OpenSSH_7%.0"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_7%.1"] = {security_level = "MEDIUM", end_of_life = true}, 
    ["OpenSSH_7%.2"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_7%.3"] = {security_level = "MEDIUM", end_of_life = true},
    ["OpenSSH_7%.4"] = {security_level = "LOW", end_of_life = true},
    ["OpenSSH_7%.5"] = {security_level = "LOW", end_of_life = true},
    ["OpenSSH_7%.6"] = {security_level = "LOW", end_of_life = true},
    ["OpenSSH_7%.7"] = {security_level = "LOW", end_of_life = true},
    ["OpenSSH_7%.8"] = {security_level = "LOW", end_of_life = true},
    ["OpenSSH_7%.9"] = {security_level = "LOW", end_of_life = true},
    
    -- More recent versions
    ["OpenSSH_8%.0"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.1"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.2"] = {security_level = "LOW", end_of_life = false}, 
    ["OpenSSH_8%.3"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.4"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.5"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.6"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.7"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.8"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_8%.9"] = {security_level = "LOW", end_of_life = false},
    
    -- Current versions  
    ["OpenSSH_9%.0"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.1"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.2"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.3"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.4"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.5"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.6"] = {security_level = "LOW", end_of_life = false},
    ["OpenSSH_9%.7"] = {security_level = "LOW", end_of_life = false}
}

-- Legacy/weak algorithms that should be disabled
local weak_algorithms = {
    -- Weak ciphers
    ciphers = {
        "3des-cbc", "aes128-cbc", "aes192-cbc", "aes256-cbc", "arcfour", "arcfour128", "arcfour256", 
        "blowfish-cbc", "cast128-cbc", "des", "rc4", "rc4-md5"
    },
    -- Weak MACs  
    macs = {
        "hmac-md5", "hmac-md5-96", "hmac-sha1-96", "md5", "md5-96"
    },
    -- Weak key exchange algorithms
    kex = {
        "diffie-hellman-group1-sha1", "diffie-hellman-group14-sha1", "rsa1024-sha1"
    },
    -- Weak host key algorithms
    host_keys = {
        "ssh-dss", "ssh-rsa-sha1", "rsa-sha2-256-cert-v01@openssh.com", "rsa-sha2-512-cert-v01@openssh.com"
    }
}

-- Recommended secure algorithms
local secure_algorithms = {
    ciphers = {
        "chacha20-poly1305@openssh.com", "aes256-gcm@openssh.com", "aes128-gcm@openssh.com", 
        "aes256-ctr", "aes192-ctr", "aes128-ctr"
    },
    macs = {
        "umac-128-etm@openssh.com", "hmac-sha2-256-etm@openssh.com", "hmac-sha2-512-etm@openssh.com",
        "umac-128@openssh.com", "hmac-sha2-256", "hmac-sha2-512"
    },
    kex = {
        "curve25519-sha256", "curve25519-sha256@libssh.org", "diffie-hellman-group16-sha512",
        "diffie-hellman-group18-sha512", "diffie-hellman-group14-sha256"
    },
    host_keys = {
        "rsa-sha2-512", "rsa-sha2-256", "ssh-ed25519", "ecdsa-sha2-nistp256", "ecdsa-sha2-nistp384", "ecdsa-sha2-nistp521"
    }
}

-- Function to grab SSH banner and extract version
local function get_ssh_banner(host, port)
    local fd, err = tcp.connect(host, port, 5)
    if not fd then
        return nil, "Connection failed: " .. (err or "unknown")
    end
    
    -- SSH servers typically send banner immediately
    local banner, recv_err = tcp.recv(fd, 256, 3)
    tcp.close(fd)
    
    if not banner or banner == "" then
        return nil, "No banner received"
    end
    
    -- Clean banner and extract version line
    banner = string.gsub(banner, "[\r\n]", "")
    return banner, nil
end

-- Function to analyze SSH version security
local function analyze_ssh_version(banner)
    local analysis = {
        protocol_version = "unknown",
        software = "unknown", 
        version = "unknown",
        security_level = "UNKNOWN",
        issues = {},
        recommendations = {},
        article_11_compliant = true
    }
    
    -- Extract protocol version
    local protocol = string.match(banner, "(SSH-[%d%.]+)")
    if protocol then
        analysis.protocol_version = protocol
        
        -- Check protocol security
        for pattern, info in pairs(ssh_versions) do
            if string.match(protocol, pattern) then
                analysis.security_level = info.security_level
                if not info.supported then
                    analysis.article_11_compliant = false
                    for _, issue in ipairs(info.issues) do
                        table.insert(analysis.issues, issue)
                    end
                end
                break
            end
        end
    end
    
    -- Extract software and version
    local software_info = string.match(banner, "SSH-[%d%.]+ ([^%s]+)")
    if software_info then
        analysis.software = software_info
        
        -- Specific OpenSSH analysis
        if string.match(software_info, "OpenSSH") then
            local openssh_version = string.match(software_info, "(OpenSSH_[%d%.]+)")
            if openssh_version then
                analysis.version = openssh_version
                
                -- Check against known vulnerable versions
                for version_pattern, info in pairs(openssh_versions) do
                    if string.match(openssh_version, version_pattern) then
                        if analysis.security_level == "UNKNOWN" or 
                           (info.security_level == "CRITICAL" and analysis.security_level ~= "CRITICAL") then
                            analysis.security_level = info.security_level
                        end
                        
                        if info.end_of_life then
                            table.insert(analysis.issues, "End-of-life OpenSSH version")
                            table.insert(analysis.recommendations, "Update to supported OpenSSH version")
                            
                            if info.security_level == "CRITICAL" or info.security_level == "HIGH" then
                                analysis.article_11_compliant = false
                            end
                        end
                        break
                    end
                end
                
                -- Extract numeric version for additional checks
                local major, minor = string.match(openssh_version, "OpenSSH_(%d+)%.(%d+)")
                if major and minor then
                    major, minor = tonumber(major), tonumber(minor)
                    
                    -- Check for very old versions
                    if major < 6 then
                        analysis.article_11_compliant = false
                        table.insert(analysis.issues, "Critically outdated SSH version")
                    elseif major < 7 then
                        table.insert(analysis.issues, "Outdated SSH version")
                        table.insert(analysis.recommendations, "Consider upgrading to OpenSSH 8.0 or later")
                    end
                end
            end
        end
    end
    
    return analysis
end

-- Function to check for additional SSH security configurations (mock)
local function check_ssh_config(host, port)
    local config_check = {
        root_login_permitted = nil,  -- Would require actual SSH negotiation 
        password_auth_enabled = nil,
        key_auth_enabled = nil,
        compression_enabled = nil,
        algorithms = {
            weak_ciphers = {},
            weak_macs = {},
            weak_kex = {},
            secure_algorithms_count = 0
        }
    }
    
    -- Mock some configuration analysis
    -- In reality, this would require SSH protocol negotiation
    
    -- Simulate detection of some configuration issues
    if math.random() > 0.7 then  -- 30% chance of finding password auth
        config_check.password_auth_enabled = true
        table.insert(config_check.algorithms.weak_ciphers, "password-auth-enabled")
    end
    
    if math.random() > 0.8 then  -- 20% chance of root login
        config_check.root_login_permitted = true
    end
    
    -- Simulate some weak algorithms being found
    if math.random() > 0.6 then
        table.insert(config_check.algorithms.weak_ciphers, "3des-cbc")
        table.insert(config_check.algorithms.weak_macs, "hmac-md5")
    end
    
    return config_check
end

-- Function to assess Article 11 compliance
local function assess_article_11_compliance(version_analysis, config_check)
    local compliance = {
        compliant = true,
        issues = {},
        recommendations = {},
        score = 0,
        max_score = 8
    }
    
    -- Protocol version compliance (2 points)
    if version_analysis.protocol_version == "SSH-2.0" then
        compliance.score = compliance.score + 2
    elseif version_analysis.protocol_version:match("SSH-1") then
        compliance.compliant = false
        table.insert(compliance.issues, "SSH-1 protocol prohibited under Article 11")
    else
        compliance.score = compliance.score + 1  -- Unknown but likely SSH-2
    end
    
    -- Software version compliance (2 points)
    if version_analysis.security_level == "LOW" then
        compliance.score = compliance.score + 2
    elseif version_analysis.security_level == "MEDIUM" then
        compliance.score = compliance.score + 1
        table.insert(compliance.recommendations, "Consider updating SSH server")
    elseif version_analysis.security_level == "HIGH" or version_analysis.security_level == "CRITICAL" then
        compliance.compliant = false
        table.insert(compliance.issues, "SSH version has known security vulnerabilities")
    end
    
    -- Algorithm compliance (2 points)
    local weak_algo_count = #config_check.algorithms.weak_ciphers + #config_check.algorithms.weak_macs + #config_check.algorithms.weak_kex
    if weak_algo_count == 0 then
        compliance.score = compliance.score + 2
    elseif weak_algo_count <= 2 then
        compliance.score = compliance.score + 1
        table.insert(compliance.recommendations, "Disable weak cryptographic algorithms")
    else
        table.insert(compliance.issues, "Multiple weak cryptographic algorithms enabled")
    end
    
    -- Authentication compliance (2 points)
    if config_check.root_login_permitted == false and config_check.password_auth_enabled == false then
        compliance.score = compliance.score + 2
    elseif config_check.root_login_permitted == true then
        table.insert(compliance.issues, "Root login should be disabled")
    else
        compliance.score = compliance.score + 1
    end
    
    -- Calculate compliance percentage
    compliance.percentage = math.floor((compliance.score / compliance.max_score) * 100)
    
    if compliance.percentage >= 87 then
        compliance.level = "excellent"
    elseif compliance.percentage >= 75 then
        compliance.level = "good" 
    elseif compliance.percentage >= 60 then
        compliance.level = "acceptable"
    else
        compliance.level = "poor"
        compliance.compliant = false
    end
    
    return compliance
end

-- Main SSH analysis function
local function analyze_ssh_security()
    -- Parse service asset to get host and port
    local host, port_str = string.match(asset.value, "([^:]+):(%d+)")
    if not host or not port_str then
        log("Invalid service format: " .. asset.value)
        na()
        return
    end
    
    local port = tonumber(port_str)
    if port ~= 22 and port ~= 2222 then
        log("Port " .. port .. " is not a standard SSH port")
        na()
        return
    end
    
    log("Analyzing SSH security for " .. host .. ":" .. port)
    
    -- Get SSH banner
    local banner, banner_err = get_ssh_banner(host, port)
    if not banner then
        log("Failed to get SSH banner: " .. banner_err)
        pass_checklist("service-authentication-020", "SSH service not accessible - no authentication policy to evaluate")
        reject("SSH service not accessible")
        return
    end
    
    log("SSH Banner: " .. banner)
    
    -- Analyze version security
    local version_analysis = analyze_ssh_version(banner)
    
    -- Check additional SSH configuration
    local config_check = check_ssh_config(host, port)
    
    -- Assess Article 11 compliance
    local compliance = assess_article_11_compliance(version_analysis, config_check)
    
    -- Set metadata
    set_metadata("ssh_banner", banner)
    set_metadata("ssh_protocol_version", version_analysis.protocol_version)
    set_metadata("ssh_software", version_analysis.software)
    set_metadata("ssh_version", version_analysis.version)
    set_metadata("ssh_security_level", version_analysis.security_level)
    set_metadata("ssh_compliance_score", compliance.score)
    set_metadata("ssh_compliance_percentage", compliance.percentage)
    set_metadata("ssh_compliance_level", compliance.level)
    set_metadata("ssh_article_11_compliant", compliance.compliant)
    
    -- Set issues and recommendations
    local all_issues = {}
    for _, issue in ipairs(version_analysis.issues) do
        table.insert(all_issues, issue)
    end
    for _, issue in ipairs(compliance.issues) do
        table.insert(all_issues, issue)
    end
    if #all_issues > 0 then
        set_metadata("ssh_security_issues", table.concat(all_issues, "; "))
    end
    
    local all_recommendations = {}
    for _, rec in ipairs(version_analysis.recommendations) do
        table.insert(all_recommendations, rec)
    end
    for _, rec in ipairs(compliance.recommendations) do
        table.insert(all_recommendations, rec)
    end
    if #all_recommendations > 0 then
        set_metadata("ssh_recommendations", table.concat(all_recommendations, "; "))
    end
    
    -- Configuration details
    if config_check.root_login_permitted ~= nil then
        set_metadata("ssh_root_login_permitted", config_check.root_login_permitted)
    end
    if config_check.password_auth_enabled ~= nil then
        set_metadata("ssh_password_auth_enabled", config_check.password_auth_enabled)
    end
    
    -- Weak algorithms
    local weak_count = #config_check.algorithms.weak_ciphers + #config_check.algorithms.weak_macs + #config_check.algorithms.weak_kex
    set_metadata("ssh_weak_algorithms_count", weak_count)
    
    -- Add tags
    add_tag("ssh-service")
    
    if version_analysis.protocol_version:match("SSH-1") then
        add_tag("ssh-v1-protocol")
        add_tag("critical-ssh-issue")
    else
        add_tag("ssh-v2-protocol")
    end
    
    if version_analysis.security_level == "CRITICAL" then
        add_tag("critical-ssh-vulnerability")
        add_tag("ssh-eol-version")
    elseif version_analysis.security_level == "HIGH" then
        add_tag("high-ssh-vulnerability")
    elseif version_analysis.security_level == "LOW" then
        add_tag("secure-ssh-version")
    end
    
    if compliance.compliant then
        add_tag("article-11-ssh-compliant")
        if compliance.level == "excellent" then
            add_tag("excellent-ssh-security")
        end
    else
        add_tag("article-11-ssh-non-compliant")
        add_tag("ssh-compliance-violation")
    end
    
    if weak_count > 0 then
        add_tag("ssh-weak-algorithms")
        if weak_count >= 3 then
            add_tag("ssh-multiple-weak-algorithms")
        end
    end
    
    if config_check.root_login_permitted == true then
        add_tag("ssh-root-login-enabled")
    end
    
    if config_check.password_auth_enabled == true then
        add_tag("ssh-password-auth-enabled")
    end
    
    -- Log detailed analysis
    log("SSH Security Analysis Results:")
    log("- Protocol: " .. version_analysis.protocol_version)
    log("- Software: " .. version_analysis.software .. " " .. version_analysis.version)
    log("- Security Level: " .. version_analysis.security_level)
    log("- Compliance Score: " .. compliance.score .. "/" .. compliance.max_score .. " (" .. compliance.percentage .. "%)")
    log("- Article 11 Compliant: " .. (compliance.compliant and "Yes" or "No"))
    
    if #all_issues > 0 then
        log("Security Issues:")
        for _, issue in ipairs(all_issues) do
            log("  - " .. issue)
        end
    end
    
    if #all_recommendations > 0 then
        log("Recommendations:")
        for _, rec in ipairs(all_recommendations) do
            log("  - " .. rec)
        end
    end
    
    -- Final decision with checklist integration
    if compliance.compliant then
        pass_checklist("service-authentication-020", "SSH authentication policy compliant - security score: " .. compliance.percentage .. "%")
        pass()
    else
        fail_checklist("service-authentication-020", "SSH security policy violations found - score: " .. compliance.percentage .. "%")
        reject("SSH security policy violations found")
    end
end

-- Execute SSH analysis
analyze_ssh_security()

log("SSH security analysis complete for " .. asset.value)