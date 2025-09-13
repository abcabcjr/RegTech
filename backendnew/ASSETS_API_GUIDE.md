# Asset Management System API Guide

## Overview

The Asset Management System provides comprehensive functionality for discovering, cataloguing, scanning, and analyzing network assets. This guide covers the complete API, data structures, and implementation examples for working with the system.

## Table of Contents

1. [Asset Model](#asset-model)
2. [REST API Endpoints](#rest-api-endpoints)
3. [Job Management](#job-management)
4. [Lua Scripting API](#lua-scripting-api)
5. [Implementation Examples](#implementation-examples)
6. [Error Handling](#error-handling)

## Asset Model

### Core Asset Structure

```json
{
  "id": "string",              // Unique asset identifier
  "type": "string",            // Asset type: domain, subdomain, ip, service
  "value": "string",           // Asset value (domain name, IP address, etc.)
  "discovered_at": "datetime", // When the asset was first discovered
  "last_scanned_at": "datetime", // When the asset was last scanned (nullable)
  "scan_count": "number",      // Number of times the asset has been scanned
  "status": "string",          // Asset status: discovered, scanning, scanned, error
  "properties": "object",      // Additional asset properties (flexible key-value pairs)
  "scan_results": "array",     // Array of scan results
  "dns_records": "object",     // DNS records (for domains/subdomains)
  "tags": "array"              // Array of tags for categorization
}
```

### Asset Types

- **`domain`**: Root domain (e.g., `example.com`)
- **`subdomain`**: Subdomain (e.g., `api.example.com`)
- **`ip`**: IP address (e.g., `192.168.1.1`)
- **`service`**: Network service (e.g., `192.168.1.1:80`)

### Asset Status Values

- **`discovered`**: Asset has been found but not yet scanned
- **`scanning`**: Asset is currently being scanned
- **`scanned`**: Asset has been successfully scanned
- **`error`**: An error occurred during scanning

### DNS Records Structure

```json
{
  "dns_records": {
    "a": ["192.168.1.1", "192.168.1.2"],          // A records (IPv4)
    "aaaa": ["2001:db8::1"],                       // AAAA records (IPv6)
    "cname": ["alias.example.com"],                // CNAME records
    "mx": ["10 mail.example.com"],                 // MX records
    "txt": ["v=spf1 include:_spf.google.com ~all"], // TXT records
    "ns": ["ns1.example.com", "ns2.example.com"],  // NS records
    "soa": ["ns1.example.com. admin.example.com. 1"],  // SOA records
    "ptr": ["example.com"]                         // PTR records
  }
}
```

### Scan Result Structure

```json
{
  "id": "string",
  "script_name": "string",
  "executed_at": "datetime",
  "success": "boolean",
  "output": ["array of log messages"],
  "error": "string",
  "duration": "string",
  "metadata": "object"
}
```

## REST API Endpoints

### Asset Discovery

#### Start Asset Discovery
```http
POST /api/v1/assets/discover
Content-Type: application/json

{
  "hosts": ["example.com", "192.168.1.1"]
}
```

**Response:**
```json
{
  "message": "Asset discovery started",
  "job_id": "discovery_20240101_123456_abc123",
  "host_count": 2,
  "started_at": "2024-01-01T12:34:56Z"
}
```

### Asset Catalogue

#### Get All Assets
```http
GET /api/v1/assets/catalogue
GET /api/v1/assets/catalogue?type=domain,subdomain
GET /api/v1/assets/catalogue?status=discovered,scanned
```

**Response:**
```json
{
  "assets": [
    {
      "id": "asset_abc123",
      "type": "domain",
      "value": "example.com",
      "discovered_at": "2024-01-01T12:34:56Z",
      "last_scanned_at": "2024-01-01T12:35:30Z",
      "scan_count": 1,
      "status": "scanned"
    }
  ],
  "total": 1
}
```

#### Get Asset Details
```http
GET /api/v1/assets/{asset_id}
```

**Response:**
```json
{
  "asset": {
    "id": "asset_abc123",
    "type": "domain",
    "value": "example.com",
    "discovered_at": "2024-01-01T12:34:56Z",
    "last_scanned_at": "2024-01-01T12:35:30Z",
    "scan_count": 1,
    "status": "scanned",
    "properties": {
      "ips": ["192.168.1.1"],
      "asn": "AS12345",
      "asn_org": "Example ISP",
      "proxied": false
    },
    "dns_records": {
      "a": ["192.168.1.1"],
      "mx": ["10 mail.example.com"],
      "txt": ["v=spf1 include:_spf.google.com ~all"]
    },
    "tags": ["has-ipv4", "mail-server", "spf-configured"],
    "scan_results": [
      {
        "id": "result_xyz789",
        "script_name": "basic_info.lua",
        "executed_at": "2024-01-01T12:35:30Z",
        "success": true,
        "output": ["Asset: example.com (domain)", "Status: discovered"],
        "error": "",
        "duration": "1.5s",
        "metadata": {
          "processed_at": "2024-01-01 12:35:30",
          "asset_length": 11
        }
      }
    ]
  }
}
```

### Asset Scanning

#### Scan Single Asset
```http
POST /api/v1/assets/{asset_id}/scan
Content-Type: application/json

{
  "scripts": ["basic_info.lua", "http_probe.lua"]
}
```

**Response:**
```json
{
  "message": "Asset scan started",
  "job_id": "scan_asset_20240101_123456_def456",
  "asset_id": "asset_abc123",
  "started_at": "2024-01-01T12:34:56Z"
}
```

#### Scan All Assets
```http
POST /api/v1/assets/scan
Content-Type: application/json

{
  "scripts": ["basic_info.lua", "http_probe.lua"],
  "asset_types": ["domain", "subdomain"]
}
```

**Response:**
```json
{
  "message": "All assets scan started",
  "job_id": "scan_all_20240101_123456_ghi789",
  "asset_count": 15,
  "started_at": "2024-01-01T12:34:56Z"
}
```

## Job Management

### Job Status Tracking

#### Get Job Status
```http
GET /api/v1/jobs/{job_id}
```

**Response:**
```json
{
  "job_id": "discovery_20240101_123456_abc123",
  "status": "running",
  "started_at": "2024-01-01T12:34:56Z",
  "completed_at": null,
  "progress": {
    "total": 10,
    "completed": 7,
    "failed": 1
  },
  "error": ""
}
```

### Job Types and Status Values

**Job Types:**
- `discovery`: Asset discovery job
- `scan_asset`: Single asset scanning job
- `scan_all`: Bulk asset scanning job

**Job Status Values:**
- `pending`: Job is queued but not started
- `running`: Job is currently executing
- `completed`: Job finished successfully
- `failed`: Job failed with an error

## Lua Scripting API

### Global Variables

#### Asset Object
The `asset` global variable provides access to the current asset being scanned:

```lua
-- Basic asset properties
local asset_id = asset.id
local asset_type = asset.type        -- "domain", "subdomain", "ip", "service"
local asset_value = asset.value      -- The actual value (domain name, IP, etc.)
local asset_status = asset.status    -- "discovered", "scanning", "scanned", "error"
local scan_count = asset.scan_count  -- Number of previous scans

-- Asset properties (additional metadata)
if asset.properties then
    local ips = asset.properties.ips
    local asn = asset.properties.asn
    local is_proxied = asset.properties.proxied
end

-- DNS records (for domains/subdomains)
if asset.dns_records then
    -- A records (IPv4 addresses)
    if asset.dns_records.a then
        for i, ip in ipairs(asset.dns_records.a) do
            log("A record: " .. ip)
        end
    end
    
    -- MX records (mail servers)
    if asset.dns_records.mx then
        for i, mx in ipairs(asset.dns_records.mx) do
            log("MX record: " .. mx)
        end
    end
    
    -- TXT records
    if asset.dns_records.txt then
        for i, txt in ipairs(asset.dns_records.txt) do
            log("TXT record: " .. txt)
        end
    end
    
    -- Other record types: aaaa, cname, ns, soa, ptr
end

-- Tags
if asset.tags then
    for i, tag in ipairs(asset.tags) do
        log("Tag: " .. tag)
    end
end
```

### Built-in Functions

#### Logging and Output
```lua
-- Log a message (appears in scan results)
log("This message will be logged")

-- Sleep for specified seconds
sleep(2.5)  -- Sleep for 2.5 seconds
```

#### Metadata Management
```lua
-- Set metadata key-value pairs
set_metadata("key", "value")
set_metadata("port", 80)
set_metadata("ssl_enabled", true)
```

#### Tagging System
```lua
-- Add tags to the asset
add_tag("http")         -- Service discovery tags
add_tag("cf-proxied")   -- Infrastructure tags
add_tag("mail-server")  -- Functionality tags
add_tag("vulnerable")   -- Security tags
```

#### Audit Decisions
```lua
-- Mark the check as passed
pass()

-- Mark the check as failed
fail()

-- Mark as not applicable
na()
```

### Network Libraries

#### HTTP Client
```lua
-- Simple GET request
local status, body, headers, err = http.get("https://example.com")
if err then
    log("HTTP error: " .. err)
else
    log("Status: " .. status)
    log("Body length: " .. #body)
end

-- POST request with headers
local headers_table = {
    ["Content-Type"] = "application/json",
    ["User-Agent"] = "Asset-Scanner/1.0"
}
local status, body, headers, err = http.post(
    "https://api.example.com/data",
    '{"key": "value"}',
    headers_table,
    30  -- timeout in seconds
)

-- Generic request
local status, body, headers, err = http.request(
    "PUT",
    "https://api.example.com/resource",
    '{"updated": true}',
    headers_table,
    15
)
```

#### TCP Client
```lua
-- Connect to a TCP service
local fd, err = tcp.connect("example.com", 80, 10)  -- 10 second timeout
if err then
    log("Connection failed: " .. err)
    return
end

-- Send data
local bytes_sent, err = tcp.send(fd, "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
if err then
    log("Send failed: " .. err)
    tcp.close(fd)
    return
end

-- Receive data
local data, err = tcp.recv(fd, 4096, 5)  -- max 4096 bytes, 5 second timeout
if err then
    log("Receive failed: " .. err)
else
    log("Received: " .. data)
end

-- Close connection
tcp.close(fd)
```

### Script Metadata (Comments)

Scripts should include metadata comments at the top:

```lua
-- @title Script Title
-- @description Brief description of what the script does
-- @category security|information|compliance|network
-- @author Your Name
-- @version 1.0
-- @asset_types domain,subdomain,ip,service
-- @requires_passed basic_info.lua,http_probe.lua
```

#### Script Dependencies with `@requires_passed`

The `@requires_passed` comment creates script execution dependencies. Scripts will only run if all specified prerequisite scripts have completed successfully with a `pass()` decision.

**Syntax:**
```lua
-- @requires_passed script1.lua,script2.lua,script3.lua
```

**How it works:**
1. The scanner analyzes all script dependencies before execution
2. Scripts are executed in phases, with dependency-free scripts running first
3. A script only runs if ALL its required dependencies have passed
4. If a dependency fails or returns `na()`, dependent scripts are skipped
5. This creates a conditional execution chain for complex scanning workflows

**Example Use Cases:**

1. **Service Detection Chain:**
   ```lua
   -- basic_info.lua (no dependencies)
   -- @asset_types service
   
   -- http_probe.lua 
   -- @requires_passed basic_info.lua
   -- @asset_types service
   
   -- http_title.lua
   -- @requires_passed http_probe.lua  
   -- @asset_types service
   ```

2. **Security Analysis Chain:**
   ```lua
   -- port_scan.lua (discovers open ports)
   
   -- service_detection.lua
   -- @requires_passed port_scan.lua
   
   -- vulnerability_scan.lua
   -- @requires_passed service_detection.lua
   ```

**Benefits:**
- **Efficiency**: Skip expensive scans if prerequisites fail
- **Logic**: Only run SSL checks if HTTPS is detected
- **Organization**: Create clear scanning workflows
- **Resource Management**: Avoid redundant network operations

## Implementation Examples

### Example 1: Basic Asset Information Script

```lua
-- @title Basic Asset Information
-- @description Gather basic information about an asset
-- @category information
-- @asset_types domain,subdomain,ip,service

log("Scanning asset: " .. asset.value .. " (type: " .. asset.type .. ")")

-- Check asset type and perform type-specific analysis
if asset.type == "domain" or asset.type == "subdomain" then
    -- Domain/subdomain specific checks
    if asset.dns_records and asset.dns_records.a then
        log("Found " .. #asset.dns_records.a .. " A records")
        add_tag("has-ipv4")
    end
    
    if asset.dns_records and asset.dns_records.mx then
        log("Found " .. #asset.dns_records.mx .. " MX records")
        add_tag("mail-server")
    end
    
    -- Check for development environments
    if string.match(asset.value, "dev") or string.match(asset.value, "test") then
        add_tag("dev-environment")
        set_metadata("environment_type", "development")
    end

elseif asset.type == "ip" then
    -- IP specific checks
    if string.match(asset.value, "^192%.168%.") or 
       string.match(asset.value, "^10%.") then
        log("Private IP address detected")
        add_tag("private-ip")
        set_metadata("ip_scope", "private")
    else
        add_tag("public-ip")
        set_metadata("ip_scope", "public")
    end

elseif asset.type == "service" then
    -- Service specific checks
    if asset.properties and asset.properties.port then
        local port = asset.properties.port
        set_metadata("service_port", port)
        
        if port == 22 then
            add_tag("ssh")
        elseif port == 80 or port == 443 then
            add_tag("web")
        elseif port == 21 then
            add_tag("ftp")
        end
    end
end

pass()
```

### Example 2: HTTP Service Detection Script

```lua
-- @title HTTP Service Detection
-- @description Detect and analyze HTTP services
-- @category network
-- @asset_types domain,subdomain,ip,service

local function probe_http(url)
    local status, body, headers, err = http.get(url, nil, 10)
    if err then
        return nil, err
    end
    return {status = status, body = body, headers = headers}, nil
end

local function extract_title(body)
    local title = string.match(body, "<title[^>]*>([^<]*)</title>")
    return title or ""
end

-- Build URLs to test
local urls = {}
if asset.type == "domain" or asset.type == "subdomain" then
    table.insert(urls, "http://" .. asset.value)
    table.insert(urls, "https://" .. asset.value)
elseif asset.type == "ip" then
    table.insert(urls, "http://" .. asset.value)
    table.insert(urls, "https://" .. asset.value)
elseif asset.type == "service" and asset.properties and 
       (asset.properties.port == 80 or asset.properties.port == 443 or 
        asset.properties.port == 8080 or asset.properties.port == 8443) then
    local scheme = (asset.properties.port == 443 or asset.properties.port == 8443) and "https" or "http"
    table.insert(urls, scheme .. "://" .. asset.value)
end

-- Test each URL
local found_http = false
for _, url in ipairs(urls) do
    log("Probing: " .. url)
    local resp, err = probe_http(url)
    
    if resp then
        found_http = true
        add_tag("http")
        
        if string.match(url, "^https://") then
            add_tag("https")
        end
        
        set_metadata("http_status", resp.status)
        set_metadata("http_url", url)
        
        -- Extract and store title
        local title = extract_title(resp.body)
        if title ~= "" then
            set_metadata("http_title", title)
            log("Page title: " .. title)
        end
        
        -- Check for interesting headers
        if resp.headers then
            for header, value in pairs(resp.headers) do
                if string.lower(header) == "server" then
                    set_metadata("http_server", value)
                    log("Server: " .. value)
                elseif string.lower(header) == "x-powered-by" then
                    set_metadata("http_powered_by", value)
                    log("Powered by: " .. value)
                end
            end
        end
        
        break  -- Found working HTTP, no need to test more URLs
    else
        log("Failed to probe " .. url .. ": " .. err)
    end
end

if found_http then
    pass()
else
    log("No HTTP service detected")
    na()
end
```

### Example 3: DNS Analysis Script

```lua
-- @title DNS Analysis
-- @description Analyze DNS records for security and configuration issues
-- @category security
-- @asset_types domain,subdomain

-- Only run on domains/subdomains
if asset.type ~= "domain" and asset.type ~= "subdomain" then
    na()
    return
end

if not asset.dns_records then
    log("No DNS records available")
    na()
    return
end

log("Analyzing DNS records for " .. asset.value)

-- Analyze TXT records for security configurations
if asset.dns_records.txt then
    for _, txt in ipairs(asset.dns_records.txt) do
        log("TXT record: " .. txt)
        
        -- SPF analysis
        if string.match(txt, "^v=spf1") then
            add_tag("spf-configured")
            set_metadata("spf_record", txt)
            
            if string.match(txt, "~all") then
                log("SPF softfail policy detected")
                set_metadata("spf_policy", "softfail")
            elseif string.match(txt, "-all") then
                log("SPF hardfail policy detected")
                set_metadata("spf_policy", "hardfail")
            elseif string.match(txt, "%+all") then
                log("WARNING: SPF allows all senders")
                set_metadata("spf_policy", "allow_all")
                add_tag("spf-permissive")
            end
        end
        
        -- DMARC analysis
        if string.match(txt, "^v=DMARC1") then
            add_tag("dmarc-configured")
            set_metadata("dmarc_record", txt)
            
            local policy = string.match(txt, "p=([^;]+)")
            if policy then
                set_metadata("dmarc_policy", policy)
                log("DMARC policy: " .. policy)
            end
        end
        
        -- Google verification
        if string.match(txt, "google%-site%-verification") then
            add_tag("google-verified")
            log("Google site verification found")
        end
    end
end

-- Analyze MX records
if asset.dns_records.mx then
    add_tag("mail-server")
    log("Found " .. #asset.dns_records.mx .. " MX records")
    
    for _, mx in ipairs(asset.dns_records.mx) do
        log("MX: " .. mx)
        
        -- Check for common mail providers
        if string.match(mx, "google%.com") or string.match(mx, "googlemail%.com") then
            add_tag("google-mail")
        elseif string.match(mx, "outlook%.com") or string.match(mx, "hotmail%.com") then
            add_tag("microsoft-mail")
        elseif string.match(mx, "amazonaws%.com") then
            add_tag("aws-mail")
        end
    end
end

-- Check for IPv6 support
if asset.dns_records.aaaa then
    add_tag("ipv6-enabled")
    log("IPv6 support detected")
end

pass()
```

### Example 4: Port Security Check Script

```lua
-- @title Port Security Check
-- @description Check for common insecure ports and services
-- @category security
-- @asset_types service

if asset.type ~= "service" then
    na()
    return
end

if not asset.properties or not asset.properties.port then
    log("No port information available")
    na()
    return
end

local port = asset.properties.port
local host = string.gsub(asset.value, ":.*", "")  -- Extract host from "host:port"

log("Checking security for port " .. port .. " on " .. host)

-- Define insecure ports
local insecure_ports = {
    [21] = "FTP - Unencrypted file transfer",
    [23] = "Telnet - Unencrypted remote access",
    [25] = "SMTP - Potentially open relay",
    [53] = "DNS - Potential amplification attacks",
    [69] = "TFTP - Unencrypted file transfer",
    [79] = "Finger - Information disclosure",
    [80] = "HTTP - Unencrypted web traffic",
    [110] = "POP3 - Unencrypted email",
    [143] = "IMAP - Unencrypted email",
    [161] = "SNMP - Default community strings",
    [512] = "rexec - Unencrypted remote execution",
    [513] = "rlogin - Unencrypted remote login",
    [514] = "rsh - Unencrypted remote shell"
}

-- Check if port is in insecure list
if insecure_ports[port] then
    log("SECURITY CONCERN: " .. insecure_ports[port])
    add_tag("insecure-service")
    set_metadata("security_risk", insecure_ports[port])
    
    -- Try to connect and banner grab
    local fd, err = tcp.connect(host, port, 5)
    if fd then
        log("Successfully connected to " .. host .. ":" .. port)
        
        -- Try to receive banner
        local banner, err = tcp.recv(fd, 1024, 3)
        if banner and banner ~= "" then
            log("Banner: " .. banner)
            set_metadata("service_banner", banner)
            
            -- Analyze banner for version information
            if string.match(banner, "SSH%-") then
                add_tag("ssh")
                local version = string.match(banner, "SSH%-([%d%.]+)")
                if version then
                    set_metadata("ssh_version", version)
                end
            elseif string.match(banner, "HTTP/") then
                add_tag("http")
            elseif string.match(banner, "FTP") then
                add_tag("ftp")
            end
        end
        
        tcp.close(fd)
        fail()  -- Insecure service is accessible
    else
        log("Could not connect: " .. err)
        pass()  -- Service not accessible, less risk
    end
else
    log("Port " .. port .. " is not in the insecure ports list")
    pass()
end
```

### Example 5: Script Dependency Chain

This example shows how to create a dependency chain using `@requires_passed`:

**Step 1: Base Service Detection (`service_detector.lua`)**
```lua
-- @title Service Detection
-- @description Detect what type of service is running
-- @category network
-- @asset_types service

if asset.type ~= "service" then
    na()
    return
end

local port = asset.properties and asset.properties.port
if not port then
    log("No port information available")
    fail()
    return
end

log("Detecting service type for port " .. port)

-- Basic service detection logic
if port == 80 or port == 8080 then
    add_tag("http")
    set_metadata("service_type", "http")
elseif port == 443 or port == 8443 then
    add_tag("https")
    set_metadata("service_type", "https")
elseif port == 22 then
    add_tag("ssh")
    set_metadata("service_type", "ssh")
elseif port == 21 then
    add_tag("ftp")
    set_metadata("service_type", "ftp")
else
    log("Unknown service type for port " .. port)
    na()
    return
end

pass()
```

**Step 2: HTTP-Specific Analysis (`http_analyzer.lua`)**
```lua
-- @title HTTP Service Analysis
-- @description Detailed HTTP service analysis
-- @category web
-- @asset_types service
-- @requires_passed service_detector.lua

-- This script only runs if service_detector.lua passed
if asset.type ~= "service" then
    na()
    return
end

-- Check if this is an HTTP service (from previous script's tags)
local is_http = false
if asset.tags then
    for _, tag in ipairs(asset.tags) do
        if tag == "http" or tag == "https" then
            is_http = true
            break
        end
    end
end

if not is_http then
    log("Not an HTTP service, skipping HTTP analysis")
    na()
    return
end

log("Performing detailed HTTP analysis")

-- Extract host from asset value (host:port format)
local host = string.gsub(asset.value, ":.*", "")
local port = asset.properties and asset.properties.port or 80
local scheme = (port == 443 or port == 8443) and "https" or "http"
local url = scheme .. "://" .. host .. ":" .. port

-- Perform HTTP request
local status, body, headers, err = http.get(url, nil, 10)
if err then
    log("HTTP request failed: " .. err)
    fail()
    return
end

log("HTTP response status: " .. status)
set_metadata("http_status", status)

-- Analyze response headers
if headers then
    for header, value in pairs(headers) do
        local lower_header = string.lower(header)
        if lower_header == "server" then
            set_metadata("web_server", value)
            log("Web server: " .. value)
            
            -- Tag based on server type
            if string.match(string.lower(value), "apache") then
                add_tag("apache")
            elseif string.match(string.lower(value), "nginx") then
                add_tag("nginx")
            elseif string.match(string.lower(value), "iis") then
                add_tag("iis")
            end
        elseif lower_header == "x-powered-by" then
            set_metadata("powered_by", value)
            log("Powered by: " .. value)
        end
    end
end

pass()
```

**Step 3: Security Headers Check (`security_headers.lua`)**
```lua
-- @title Security Headers Analysis
-- @description Check for security-related HTTP headers
-- @category security
-- @asset_types service
-- @requires_passed http_analyzer.lua

-- This script only runs if both service_detector.lua AND http_analyzer.lua passed
if asset.type ~= "service" then
    na()
    return
end

log("Analyzing security headers")

-- Extract connection details
local host = string.gsub(asset.value, ":.*", "")
local port = asset.properties and asset.properties.port or 80
local scheme = (port == 443 or port == 8443) and "https" or "http"
local url = scheme .. "://" .. host .. ":" .. port

-- Make HTTP request to analyze headers
local status, body, headers, err = http.get(url, nil, 10)
if err then
    log("Failed to fetch headers: " .. err)
    fail()
    return
end

-- Security headers to check
local security_headers = {
    ["strict-transport-security"] = "HSTS",
    ["content-security-policy"] = "CSP",
    ["x-frame-options"] = "X-Frame-Options",
    ["x-content-type-options"] = "X-Content-Type-Options",
    ["x-xss-protection"] = "X-XSS-Protection",
    ["referrer-policy"] = "Referrer-Policy"
}

local found_headers = 0
local missing_headers = {}

for header_name, display_name in pairs(security_headers) do
    local found = false
    if headers then
        for h, v in pairs(headers) do
            if string.lower(h) == header_name then
                found = true
                found_headers = found_headers + 1
                log("Found " .. display_name .. ": " .. v)
                set_metadata("security_header_" .. string.gsub(header_name, "-", "_"), v)
                break
            end
        end
    end
    
    if not found then
        table.insert(missing_headers, display_name)
    end
end

-- Set overall security score
local total_headers = 0
for _ in pairs(security_headers) do total_headers = total_headers + 1 end
local security_score = (found_headers / total_headers) * 100

set_metadata("security_headers_found", found_headers)
set_metadata("security_headers_total", total_headers)
set_metadata("security_score", security_score)

log("Security headers found: " .. found_headers .. "/" .. total_headers)
log("Security score: " .. string.format("%.1f", security_score) .. "%")

-- Tag based on security posture
if security_score >= 80 then
    add_tag("secure-headers")
    pass()
elseif security_score >= 50 then
    add_tag("partial-security")
    pass()
else
    add_tag("insecure-headers")
    log("WARNING: Poor security header configuration")
    for _, missing in ipairs(missing_headers) do
        log("Missing: " .. missing)
    end
    fail()
end
```

**Execution Flow:**
1. **Phase 1**: `service_detector.lua` runs first (no dependencies)
   - If it fails or returns `na()`, the chain stops
   - If it passes, HTTP services get tagged appropriately

2. **Phase 2**: `http_analyzer.lua` runs only if `service_detector.lua` passed
   - Performs detailed HTTP analysis
   - If it fails, `security_headers.lua` won't run

3. **Phase 3**: `security_headers.lua` runs only if both prerequisites passed
   - Analyzes security posture
   - Makes final security assessment

This creates an efficient scanning workflow where expensive operations only run when prerequisites are met, and each script builds upon the knowledge gathered by previous scripts.

## Error Handling

### HTTP Status Codes

- **200 OK**: Request successful
- **202 Accepted**: Async operation started (discovery/scanning)
- **400 Bad Request**: Invalid request parameters
- **404 Not Found**: Asset or job not found
- **409 Conflict**: Resource conflict (e.g., discovery already running)
- **500 Internal Server Error**: Server error

### Error Response Format

```json
{
  "error": "Error description",
  "code": 400,
  "details": {
    "field": "specific error message"
  }
}
```

### Common Error Scenarios

1. **Asset Not Found**
   ```json
   {
     "error": "Asset not found",
     "code": 404
   }
   ```

2. **Discovery Already Running**
   ```json
   {
     "error": "Discovery job already in progress",
     "code": 409,
     "details": {
       "job_id": "discovery_20240101_123456_abc123"
     }
   }
   ```

3. **Invalid Script**
   ```json
   {
     "error": "Script execution failed",
     "code": 500,
     "details": {
       "script": "invalid_script.lua",
       "message": "Lua execution error: attempt to call a nil value"
     }
   }
   ```

## Best Practices

### Script Development
1. Always include script metadata comments
2. Use appropriate asset type filtering
3. Handle missing data gracefully
4. Use meaningful log messages
5. Set relevant metadata and tags
6. Use proper audit decisions (pass/fail/na)

### API Usage
1. Poll job status for long-running operations
2. Handle HTTP errors appropriately
3. Use asset type filters to reduce response size
4. Cache asset details when possible
5. Implement proper timeout handling

### Performance
1. Limit concurrent scans using the job system
2. Use appropriate timeouts for network operations
3. Filter assets by type/status when possible
4. Implement proper error recovery

This guide provides comprehensive coverage of the Asset Management System API. For additional support or questions, refer to the system logs or contact the development team.
