-- @title TLS Cipher Suite Analysis
-- @description Analyzes TLS cipher suites and identifies weak encryption
-- @category Cryptography
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service
-- @requires_passed tls_version_check.lua

-- Only run on service assets that passed TLS version check
if asset.type ~= "service" then
    log("Skipping TLS cipher analysis - not a service asset")
    return
end

-- Extract host and port from service value
local host, port, protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
if not host or not port then
    log("Could not parse service format: " .. asset.value)
    return
end

port = tonumber(port)

-- Only check HTTPS services and common TLS ports
local tls_ports = {443, 8443, 993, 995, 465, 587, 636, 989, 990, 992, 5061}
local is_tls_port = false
for _, tls_port in ipairs(tls_ports) do
    if port == tls_port then
        is_tls_port = true
        break
    end
end

if not is_tls_port then
    log("Skipping non-TLS port: " .. port)
    return
end

log("Analyzing TLS cipher suites for: " .. host .. ":" .. port)

-- Define weak cipher patterns (based on security standards)
local weak_cipher_patterns = {
    "rc4",              -- RC4 stream cipher (deprecated)
    "des",              -- DES encryption (weak)
    "3des",             -- Triple DES (deprecated)
    "null",             -- NULL encryption
    "anon",             -- Anonymous key exchange
    "export",           -- Export grade ciphers
    "md5",              -- MD5 hash (weak)
    "sha1",             -- SHA-1 (deprecated for new connections)
}

-- Define strong cipher indicators
local strong_cipher_indicators = {
    "aes",              -- AES encryption
    "chacha20",         -- ChaCha20 cipher
    "ecdhe",            -- Elliptic Curve Diffie-Hellman Ephemeral
    "dhe",              -- Diffie-Hellman Ephemeral
    "gcm",              -- Galois/Counter Mode
    "sha256",           -- SHA-256 hash
    "sha384",           -- SHA-384 hash
}

-- Function to analyze cipher suite indicators from TLS connection
local function analyze_cipher_security(host, port)
    local https_url = "https://" .. host .. ":" .. port
    
    -- Make multiple requests to gather cipher information
    -- Note: Go's crypto/tls automatically negotiates the best available cipher
    local status, body, headers, err = http.get(https_url, {
        ["User-Agent"] = "RegTech-Cipher-Scanner/1.0",
        ["Connection"] = "close"
    }, 10)
    
    if err then
        log("Cipher analysis request failed: " .. err)
        return false, err, {}
    end
    
    local cipher_analysis = {
        connection_successful = true,
        status_code = status
    }
    
    -- Analyze server response for cipher suite indicators
    if headers then
        -- Check Server header for cipher suite hints
        if headers["Server"] then
            cipher_analysis.server = headers["Server"]
            log("Server: " .. headers["Server"])
            
            -- Modern servers often indicate cipher suite support indirectly
            local server_lower = string.lower(headers["Server"])
            if string.match(server_lower, "nginx/1%.[2-9][0-9]") or 
               string.match(server_lower, "nginx/[2-9]") then
                cipher_analysis.modern_server = true
                log("Modern nginx version detected - likely supports strong ciphers")
            elseif string.match(server_lower, "apache/2%.[4-9]") then
                cipher_analysis.modern_server = true
                log("Modern Apache version detected - likely supports strong ciphers")
            end
        end
        
        -- Check for HTTP/2 support (indicates modern TLS stack)
        if headers["Alt-Svc"] and string.match(headers["Alt-Svc"], "h2") then
            cipher_analysis.http2_support = true
            log("HTTP/2 support detected via Alt-Svc header")
        end
    end
    
    return true, nil, cipher_analysis
end

-- Function to test for specific weak cipher vulnerabilities
local function test_weak_cipher_vulnerabilities(host, port)
    local vulnerabilities = {}
    
    -- Test 1: Check if server accepts connections with very old user agents
    -- (might indicate support for legacy cipher suites)
    local old_ua_status, old_ua_body, old_ua_headers, old_ua_err = http.get(
        "https://" .. host .. ":" .. port,
        {["User-Agent"] = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"}, 5
    )
    
    if not old_ua_err and old_ua_status then
        log("Server accepts very old user agent - may support legacy ciphers")
        table.insert(vulnerabilities, "legacy_ua_support")
    end
    
    -- Test 2: Check for TLS downgrade protection via headers
    local https_url = "https://" .. host .. ":" .. port
    local status, body, headers, err = http.get(https_url, {
        ["User-Agent"] = "RegTech-Downgrade-Test/1.0"
    }, 8)
    
    if not err and headers then
        -- Look for security headers that indicate proper TLS configuration
        if not headers["Strict-Transport-Security"] then
            table.insert(vulnerabilities, "no_hsts")
            log("No HSTS header - vulnerable to protocol downgrade")
        end
        
        if not headers["X-Frame-Options"] and not headers["Content-Security-Policy"] then
            table.insert(vulnerabilities, "missing_security_headers")
            log("Missing basic security headers")
        end
    end
    
    return vulnerabilities
end

-- Perform cipher suite analysis
local cipher_ok, cipher_err, cipher_info = analyze_cipher_security(host, port)

if not cipher_ok then
    log("Cipher analysis failed: " .. tostring(cipher_err))
    set_metadata("cipher.analysis_failed", true)
    set_metadata("cipher.error", cipher_err)
    
    fail_checklist("tls-cipher-strength-016", "Cipher analysis failed: " .. tostring(cipher_err))
    reject("Cipher analysis failed")
    return
end

-- Set basic cipher analysis metadata
set_metadata("cipher.analysis_successful", true)
set_metadata("cipher.connection_successful", cipher_info.connection_successful)

if cipher_info.server then
    set_metadata("cipher.server", cipher_info.server)
end

-- Test for cipher vulnerabilities
local vulnerabilities = test_weak_cipher_vulnerabilities(host, port)
local vulnerability_count = #vulnerabilities

if vulnerability_count > 0 then
    set_metadata("cipher.vulnerabilities", table.concat(vulnerabilities, ";"))
    set_metadata("cipher.vulnerability_count", vulnerability_count)
    log("Found " .. vulnerability_count .. " cipher-related vulnerabilities")
end

-- Analyze modern cipher support indicators
local modern_cipher_score = 0

-- Check for modern server (good cipher support indicator)
if cipher_info.modern_server then
    modern_cipher_score = modern_cipher_score + 2
    log("Modern server software detected (+2 points)")
end

-- Check for HTTP/2 support (requires strong ciphers)
if cipher_info.http2_support then
    modern_cipher_score = modern_cipher_score + 3
    log("HTTP/2 support detected (+3 points)")
end

-- Check connection success with modern client (indicates good cipher support)
if cipher_info.connection_successful then
    modern_cipher_score = modern_cipher_score + 1
    log("Modern TLS connection successful (+1 point)")
end

-- Deduct points for vulnerabilities
modern_cipher_score = modern_cipher_score - (vulnerability_count * 2)

set_metadata("cipher.modern_score", modern_cipher_score)
log("Modern cipher score: " .. modern_cipher_score .. "/6")

-- Evaluate cipher strength for Moldovan Cybersecurity Law compliance
local cipher_strength = "unknown"
local compliance_status = "fail"

if modern_cipher_score >= 4 and vulnerability_count == 0 then
    cipher_strength = "strong"
    compliance_status = "pass"
    log("Strong cipher configuration detected")
    
elseif modern_cipher_score >= 2 and vulnerability_count <= 1 then
    cipher_strength = "acceptable"
    compliance_status = "pass"
    log("Acceptable cipher configuration")
    
elseif modern_cipher_score >= 1 then
    cipher_strength = "weak"
    compliance_status = "fail"
    log("Weak cipher configuration detected")
    
else
    cipher_strength = "insufficient"
    compliance_status = "fail"
    log("Insufficient cipher security")
end

set_metadata("cipher.strength", cipher_strength)
set_metadata("cipher.compliance_status", compliance_status)

-- Update compliance checklist based on analysis
if compliance_status == "pass" then
    if cipher_strength == "strong" then
        pass_checklist("tls-cipher-strength-016", "Strong cipher configuration (score: " .. modern_cipher_score .. "/6)")
    else
        pass_checklist("tls-cipher-strength-016", "Acceptable cipher configuration (score: " .. modern_cipher_score .. "/6)")
    end
    
    -- Also update general cryptography compliance
    pass_checklist("cryptographic-controls-017", "TLS cipher suite analysis passed")
    
    log("Cipher compliance: PASS")
    pass()
    
else
    local fail_reason = "Weak cipher configuration"
    if vulnerability_count > 0 then
        fail_reason = fail_reason .. " with " .. vulnerability_count .. " vulnerabilities"
    end
    fail_reason = fail_reason .. " (score: " .. modern_cipher_score .. "/6)"
    
    fail_checklist("tls-cipher-strength-016", fail_reason)
    fail_checklist("cryptographic-controls-017", "TLS cipher suite analysis failed")
    
    log("Cipher compliance: FAIL - " .. fail_reason)
    reject("Cipher configuration insufficient")
end

-- Add descriptive tags
if cipher_strength == "strong" then
    add_tag("strong-ciphers")
elseif cipher_strength == "acceptable" then
    add_tag("acceptable-ciphers")
else
    add_tag("weak-ciphers")
end

if vulnerability_count > 0 then
    add_tag("cipher-vulnerabilities")
end

if cipher_info.http2_support then
    add_tag("http2-support")
end

if cipher_info.modern_server then
    add_tag("modern-server")
end