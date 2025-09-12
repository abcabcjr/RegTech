# RegTech - Asset Discovery CLI Tool

A powerful CLI tool for asset discovery and reconnaissance that processes domains, subdomains, and IP addresses to compile comprehensive JSON output with ASN information.

## Features

- **Multi-input Support**: Accepts domains, subdomains, and IP addresses
- **Subdomain Discovery**: Uses passive enumeration to find subdomains (currently with basic implementation, full subfinder integration pending)
- **IP Resolution**: Resolves IP addresses for all domains and subdomains
- **ASN Lookup**: Queries Autonomous System Number (ASN) information for all discovered IPs
- **JSON Output**: Structured JSON output with comprehensive asset information
- **Concurrent Processing**: Processes multiple inputs concurrently for better performance
- **Verbose Mode**: Detailed logging for troubleshooting and monitoring

## Installation

### Prerequisites
- Go 1.19 or later
- Internet connection for DNS resolution and ASN lookups

### Build from Source

```bash
git clone <repository-url>
cd RegTech
go mod tidy
go build -o regtech main.go
```

Or use the build script:
```bash
./build_and_run.sh
```

## Usage

### Basic Usage

```bash
# Analyze a single domain
./regtech example.com

# Analyze multiple domains
./regtech example.com google.com

# Analyze mixed input types
./regtech example.com 8.8.8.8 www.github.com

# Enable verbose output
./regtech -v example.com

# Save output to file
./regtech -o results.json example.com
```

### Command Line Options

- `-v, --verbose`: Enable verbose output for detailed logging
- `-o, --output`: Specify output file for JSON results (default: stdout)
- `-h, --help`: Show help information

### Build and Run Script

The included `build_and_run.sh` script provides an easy way to build and run the tool:

```bash
# Build and show usage
./build_and_run.sh

# Build and run with arguments
./build_and_run.sh -v example.com
./build_and_run.sh -o results.json example.com google.com
```

## Output Format

The tool outputs JSON with the following structure:

```json
{
  "assets": [
    {
      "type": "domain",
      "value": "example.com",
      "ips": ["93.184.216.34", "2606:2800:220:1:248:1893:25c8:1946"],
      "asn": "AS15133",
      "asn_org": "EDGECAST, US",
      "subdomains": ["www.example.com"]
    },
    {
      "type": "subdomain", 
      "value": "www.example.com",
      "ips": ["93.184.216.34"],
      "asn": "AS15133",
      "asn_org": "EDGECAST, US"
    },
    {
      "type": "ip",
      "value": "8.8.8.8",
      "ips": ["8.8.8.8"],
      "asn": "AS15169",
      "asn_org": "GOOGLE, US"
    }
  ]
}
```

### Asset Types

- **domain**: Root domains with discovered subdomains
- **subdomain**: Individual subdomains with their IP resolution
- **ip**: Direct IP addresses with ASN information

## Examples

### Single Domain Analysis
```bash
./regtech -v example.com
```

### Multiple Domains with Output File
```bash
./regtech -o company-assets.json company.com subdomain.company.com 192.168.1.1
```

### Verbose Mode for Debugging
```bash
./regtech -v -o debug-output.json example.com
```

## Current Limitations

- **Subfinder Integration**: Currently using basic subdomain enumeration. Full ProjectDiscovery subfinder integration is planned for future releases.
- **Rate Limiting**: No built-in rate limiting for DNS queries (relies on system defaults).
- **Error Handling**: Basic error handling for network issues.

## Planned Features

- [ ] Full ProjectDiscovery subfinder integration
- [ ] Rate limiting for DNS queries  
- [ ] Support for custom DNS servers
- [ ] Additional ASN data sources
- [ ] Export to multiple formats (CSV, XML)
- [ ] Integration with other reconnaissance tools

## Dependencies

- `github.com/spf13/cobra` - CLI framework
- `github.com/ammario/ipisp` - ASN lookup functionality
- `github.com/projectdiscovery/subfinder/v2` - Subdomain enumeration (integration pending)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

[Add your license information here]

## Disclaimer

This tool is intended for legitimate security research and asset discovery purposes only. Users are responsible for ensuring they have proper authorization before scanning domains or networks they do not own.