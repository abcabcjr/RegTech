# RegTech Backend

A powerful backend system that integrates with recontool to process discovered assets through Lua scripts.

## Features

- **Streaming Asset Processing**: Receives assets in real-time from recontool's streaming mode
- **Lua Scripting**: Embedded Lua interpreter with full asset data access
- **Global Asset Table**: Complete asset information available as a global table in Lua
- **Concurrent Processing**: Handles multiple assets simultaneously
- **Sudo Integration**: Runs recontool with sudo for comprehensive port scanning

## Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│   recontool │───▶│   Backend    │───▶│ Lua Scripts     │
│ (streaming) │    │   (main.go)  │    │   Processing    │
└─────────────┘    └──────────────┘    └─────────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Processed       │
                   │ Results         │
                   └─────────────────┘
```

## Quick Start

### 1. Build Everything

```bash
make all
```

### 2. Run with Example Target

```bash
make run
```

### 3. Run with Custom Targets

```bash
make run-targets TARGETS="example.com google.com"
```

### 4. Test the System

```bash
make test
```

## Usage

### Command Line Options

```bash
./build/backend [targets...] [flags]

Flags:
  --recontool string    Path to recontool executable (default "../recontool/regtech")
  --scripts string      Directory containing Lua scripts (default "./scripts")
  -v, --verbose         Enable verbose output
  -o, --output string   Output file for results
```

### Examples

```bash
# Basic usage
./build/backend example.com

# With custom paths and verbose output
./build/backend -v --scripts ./custom_scripts example.com

# Multiple targets with output file
./build/backend -v -o results.json domain1.com domain2.com 192.168.1.1

# Using different recontool path
./build/backend --recontool /path/to/recontool example.com
```

## Script Development

### Lua Scripts

Create Lua scripts in the `scripts/` directory:

```lua
-- example_processing.lua
log("Processing asset: " .. asset.value)
log("Asset type: " .. asset.type)

if asset.type == "domain" then
    log("Found domain: " .. asset.value)
    if asset.subdomains then
        log("Has " .. #asset.subdomains .. " subdomains")
    end
    -- Custom domain processing logic
elseif asset.type == "ip" then
    log("Found IP: " .. asset.value)
    if asset.asn then
        log("ASN: " .. asset.asn)
    end
    -- Custom IP processing logic
elseif asset.type == "service" then
    log("Found service on port " .. asset.port)
    -- Custom service processing logic
end
```

## Asset Types

The system processes four types of assets from recontool:

### Domain Assets
```json
{
  "id": "unique_id",
  "type": "domain",
  "value": "example.com",
  "ips": ["93.184.216.34"],
  "subdomains": ["www.example.com", "mail.example.com"],
  "proxied": false,
  "dns_records": { ... }
}
```

### Subdomain Assets
```json
{
  "id": "unique_id", 
  "type": "subdomain",
  "value": "www.example.com",
  "ips": ["93.184.216.34"],
  "proxied": true,
  "dns_records": { ... }
}
```

### IP Assets
```json
{
  "id": "unique_id",
  "type": "ip", 
  "value": "93.184.216.34",
  "asn": "AS15133",
  "asn_org": "EDGECAST, US",
  "service_ids": ["service_id_1", "service_id_2"]
}
```

### Service Assets
```json
{
  "id": "unique_id",
  "type": "service",
  "value": "93.184.216.34:443/tcp",
  "port": 443,
  "protocol": "tcp",
  "state": "open",
  "service": "https",
  "version": "nginx/1.18.0",
  "source_ip": "93.184.216.34"
}
```

## Lua API Reference

### Built-in Functions

- `log(message)` - Log a message
- `sleep(seconds)` - Sleep for specified seconds

### Asset Table

The `asset` global table contains the current asset being processed with all available properties:

```lua
-- Basic properties (all assets)
local domain = asset.value      -- Asset value (domain, IP, etc.)
local asset_type = asset.type   -- "domain", "subdomain", "ip", "service"
local asset_id = asset.id       -- Unique asset identifier

-- IP addresses (domains and subdomains)
if asset.ips then
    for i, ip in ipairs(asset.ips) do
        log("IP " .. i .. ": " .. ip)
    end
end

-- Domain-specific properties
if asset.subdomains then
    log("Found " .. #asset.subdomains .. " subdomains")
end

-- IP-specific properties
if asset.asn then
    log("ASN: " .. asset.asn .. " (" .. (asset.asn_org or "unknown") .. ")")
end

-- Service-specific properties
if asset.port then
    log("Service on port " .. asset.port .. "/" .. (asset.protocol or "unknown"))
end

-- CDN/Proxy detection
if asset.proxied ~= nil then
    log("Proxied: " .. tostring(asset.proxied))
end

-- DNS records
if asset.dns_records then
    if asset.dns_records.mx then
        log("MX records: " .. #asset.dns_records.mx)
    end
end
```

## Directory Structure

```
backend/
├── main.go              # Main application
├── Makefile            # Build automation
├── README.md           # This file
├── go.mod              # Go module definition
├── scripts/            # Lua scripts
│   └── example_script.lua
└── build/              # Build output (created by make)
    ├── backend         # Main binary
    └── scripts/        # Copied Lua scripts
```

## Development Workflow

### 1. Create a New Script

```bash
# Create script file
vim scripts/my_script.lua

# Copy scripts
make scripts

# Test
make run
```

```bash
# Clean and rebuild everything
make clean all

# Test with verbose output
make test
```

## Troubleshooting

### Common Issues

1. **Recontool not found**: Check the `--recontool` path
2. **Permission errors**: The system runs recontool with sudo for port scanning
3. **Lua script errors**: Check script syntax and available functions
4. **Asset table access**: Ensure you're accessing the global `asset` table correctly

### Debug Mode

Run with verbose flag to see detailed processing information:

```bash
./build/backend -v example.com
```

### Logs

The system provides comprehensive logging:
- Asset reception from recontool
- Plugin execution status
- Lua script processing
- Error messages and warnings

## Requirements

- Go 1.19 or later
- Built recontool binary (../recontool/regtech)
- sudo access for port scanning
- nmap (for recontool port scanning)

## Performance Considerations

- Assets are processed concurrently
- Each plugin gets its own Lua state
- Streaming mode provides real-time processing
- Memory usage scales with concurrent asset processing

## Security Notes

- The system runs recontool with sudo privileges
- Lua scripts have access to system functions
- Plugin code runs with full application privileges
- Only load trusted plugins and scripts
