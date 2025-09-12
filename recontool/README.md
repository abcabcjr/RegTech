# RegTech - Advanced Asset Discovery & Reconnaissance Tool

A powerful CLI tool for comprehensive asset discovery and reconnaissance that processes domains, subdomains, and IP addresses with advanced features including real-time streaming output, port scanning, and service discovery.

## 🚀 Features

### Core Functionality
- **Multi-input Support**: Accepts domains, subdomains, and IP addresses
- **Subfinder Integration**: Full ProjectDiscovery subfinder integration for passive subdomain enumeration
- **Comprehensive DNS Lookup**: A, AAAA, CNAME, MX, TXT, NS, SOA, and PTR records
- **IP Resolution & ASN Lookup**: Resolves IPs and queries ASN information for all assets
- **CDN/Proxy Detection**: Automatically detects if domains/subdomains are behind CDN services
- **Port Scanning**: Efficient Nmap integration with SYN scan and TCP connect fallback
- **Service Discovery**: Identifies services running on discovered ports

### Output & Performance
- **Streaming JSON Output**: Real-time asset discovery with immediate results
- **Structured Asset Model**: Relational asset structure with unique IDs and references
- **Concurrent Processing**: Parallelized discovery for maximum performance
- **Comprehensive Logging**: Detailed verbose mode for troubleshooting

### Asset Types
- **Domains**: Root domains with discovered subdomains and DNS records
- **Subdomains**: Individual subdomains with IP resolution and proxy detection
- **IPs**: IP addresses with ASN information and discovered services
- **Services**: Individual services with port, protocol, and version details

## 📦 Installation

### Prerequisites
- Go 1.19 or later
- Internet connection for DNS resolution and ASN lookups
- Nmap (optional, for port scanning functionality)

### Build from Source

```bash
git clone <repository-url>
cd RegTech/recontool
go mod tidy
go build -o regtech main.go
```

Or use the build script:
```bash
./build_and_run.sh
```

## 🔧 Usage

### Command Line Options

```
Usage:
  regtech [domains/subdomains/ips...] [flags]

Flags:
  -h, --help            help for regtech
  -o, --output string   Output file for JSON results (default: stdout)
  -s, --scan            Enable port scanning with Nmap (requires nmap)
      --stream          Enable streaming JSON output (one asset per line)
  -v, --verbose         Enable verbose output
```

### Basic Usage

```bash
# Analyze a single domain
./regtech example.com

# Analyze multiple domains with verbose output
./regtech -v example.com google.com

# Enable port scanning
./regtech -s -v example.com

# Stream results in real-time
./regtech --stream -v example.com

# Save to file with all features enabled
./regtech -s --stream -v -o results.json example.com
```

### Advanced Examples

```bash
# Full reconnaissance with streaming
./regtech --stream -s -v company.com subdomain.company.com 192.168.1.1

# Port scanning only for specific IPs
./regtech -s 8.8.8.8 1.1.1.1

# Comprehensive domain analysis
./regtech -s -v -o comprehensive-scan.json target.com
```

## 📊 Output Formats

### Batch Output (Default)
Standard JSON array with all assets collected:

```json
{
  "assets": [
    {
      "id": "d1a2b3c4d5e6",
      "type": "domain",
      "value": "example.com",
      "ips": ["93.184.216.34"],
      "subdomains": ["www.example.com"],
      "proxied": false,
      "dns_records": {
        "a": ["93.184.216.34"],
        "mx": ["10 mail.example.com"],
        "txt": ["v=spf1 include:_spf.example.com ~all"],
        "ns": ["ns1.example.com", "ns2.example.com"]
      }
    },
    {
      "id": "a1b2c3d4e5f6",
      "type": "ip",
      "value": "93.184.216.34",
      "ips": ["93.184.216.34"],
      "asn": "AS15133",
      "asn_org": "EDGECAST, US",
      "service_ids": ["svc1234567890"]
    },
    {
      "id": "svc1234567890",
      "type": "service",
      "value": "93.184.216.34:443/tcp",
      "port": 443,
      "protocol": "tcp",
      "state": "open",
      "service": "https",
      "version": "nginx/1.18.0",
      "source_ip": "93.184.216.34"
    }
  ]
}
```

### Streaming Output (--stream)
Real-time JSONL format (one asset per line):

```jsonl
{"id":"d1a2b3c4d5e6","type":"domain","value":"example.com","ips":["93.184.216.34"],"subdomains":["www.example.com"],"proxied":false}
{"id":"s1a2b3c4d5e6","type":"subdomain","value":"www.example.com","ips":["93.184.216.34"],"proxied":true}
{"id":"a1b2c3d4e5f6","type":"ip","value":"93.184.216.34","asn":"AS15133","asn_org":"EDGECAST, US","service_ids":["svc1234567890"]}
{"id":"svc1234567890","type":"service","value":"93.184.216.34:443/tcp","port":443,"protocol":"tcp","state":"open","service":"https","source_ip":"93.184.216.34"}
```

## 🎯 Asset Structure

### Domain Assets
- **ID**: Unique identifier
- **Subdomains**: List of discovered subdomains
- **IPs**: Resolved IP addresses
- **Proxied**: Boolean indicating CDN/proxy usage
- **DNS Records**: Comprehensive DNS record lookup

### IP Assets
- **ASN & Organization**: Autonomous System information
- **Service IDs**: References to discovered services
- **Proxy Detection**: Identifies CDN/proxy IPs

### Service Assets
- **Port & Protocol**: Service endpoint details
- **State**: Port state (open/closed/filtered)
- **Service & Version**: Identified service and version
- **Source IP**: Parent IP address reference

## ⚡ Performance Features

### Streaming Mode
- **Real-time Output**: Assets streamed as discovered
- **Memory Efficient**: No buffering of large result sets
- **Progress Monitoring**: Immediate feedback during long scans

### Concurrent Processing
- **Parallel Subdomain Discovery**: Multiple domains processed simultaneously
- **Concurrent Port Scanning**: Parallel Nmap execution
- **Efficient DNS Lookups**: Optimized DNS resolution

### Smart Scanning
- **Proxy Detection**: Skips port scanning for CDN/proxy IPs
- **Fallback Mechanisms**: TCP connect scan when SYN scan fails
- **Timeout Management**: Configurable timeouts for all operations

## 🛠 Build and Run Script

The `build_and_run.sh` script provides convenient access:

```bash
# Build and show usage
./build_and_run.sh

# Build and run with streaming
./build_and_run.sh --stream -v example.com

# Full reconnaissance
./build_and_run.sh -s --stream -v -o results.json target.com
```

## 🔍 Advanced Features

### CDN/Proxy Detection
Automatically identifies assets behind:
- Cloudflare
- Akamai  
- AWS CloudFront
- Fastly
- And many more...

### Port Scanning Integration
- **SYN Stealth Scans**: Fast, stealthy port discovery
- **TCP Connect Fallback**: Works without root privileges
- **Top 1000 Ports**: Efficient port selection
- **Service Identification**: Automatic service detection

### DNS Record Analysis
Complete DNS reconnaissance including:
- A/AAAA records (IPv4/IPv6)
- CNAME records (aliases)
- MX records (mail servers)
- TXT records (SPF, DKIM, etc.)
- NS records (name servers)
- PTR records (reverse DNS)

## 📈 Use Cases

### Security Research
- Asset discovery and enumeration
- Attack surface mapping
- Subdomain takeover identification
- Service version analysis

### Network Reconnaissance
- Infrastructure mapping
- Service discovery
- CDN identification
- DNS configuration analysis

### Compliance & Auditing
- Asset inventory creation
- External exposure assessment
- Service cataloging
- Configuration validation

## 🚨 Error Handling & Reliability

- **Graceful Fallbacks**: Multiple scan methods for reliability
- **Comprehensive Error Reporting**: Detailed error messages in verbose mode
- **Timeout Management**: Prevents hanging on unresponsive targets
- **Partial Results**: Returns discovered assets even if some operations fail

## 📋 Dependencies

- `github.com/spf13/cobra` - CLI framework
- `github.com/ammario/ipisp` - ASN lookup functionality  
- `github.com/projectdiscovery/subfinder/v2` - Subdomain enumeration
- `nmap` (optional) - Port scanning capabilities

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

[Add your license information here]

## ⚠️ Disclaimer

This tool is intended for legitimate security research, penetration testing, and asset discovery purposes only. Users are responsible for:

- Obtaining proper authorization before scanning domains or networks
- Complying with applicable laws and regulations
- Using the tool ethically and responsibly
- Respecting rate limits and target system resources

The developers assume no liability for misuse of this tool.

## 🔗 Related Projects

- [ProjectDiscovery Subfinder](https://github.com/projectdiscovery/subfinder)
- [Nmap](https://nmap.org/)
- [ASN Lookup Tools](https://github.com/ammario/ipisp)