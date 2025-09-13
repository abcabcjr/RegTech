package recon

import "time"

// Service represents a discovered service on an IP/port (used internally for Nmap results)
type Service struct {
	Port     int    `json:"port"`
	Protocol string `json:"protocol"`
	State    string `json:"state"`
	Service  string `json:"service,omitempty"`
	Version  string `json:"version,omitempty"`
}

// DNSRecords holds various DNS record types
type DNSRecords struct {
	A     []string `json:"a,omitempty"`     // A records (IPv4)
	AAAA  []string `json:"aaaa,omitempty"`  // AAAA records (IPv6)
	CNAME []string `json:"cname,omitempty"` // CNAME records
	MX    []string `json:"mx,omitempty"`    // MX records (mail exchange)
	TXT   []string `json:"txt,omitempty"`   // TXT records
	NS    []string `json:"ns,omitempty"`    // NS records (name servers)
	SOA   []string `json:"soa,omitempty"`   // SOA records (start of authority)
	PTR   []string `json:"ptr,omitempty"`   // PTR records (reverse DNS)
}

// Asset represents a discovered asset (domain, subdomain, IP, or service)
type Asset struct {
	ID         string      `json:"id"`                    // unique identifier for this asset
	Type       string      `json:"type"`                  // "domain", "subdomain", "ip", or "service"
	Value      string      `json:"value"`                 // the actual domain/subdomain/ip/service
	IPs        []string    `json:"ips,omitempty"`         // resolved IPs for domains/subdomains
	ASN        string      `json:"asn,omitempty"`         // ASN information
	ASNOrg     string      `json:"asn_org,omitempty"`     // ASN organization
	Subdomains []string    `json:"subdomains,omitempty"`  // discovered subdomains (for domains only)
	Proxied    *bool       `json:"proxied,omitempty"`     // true if behind CDN/proxy (domains/subdomains only)
	DNSRecords *DNSRecords `json:"dns_records,omitempty"` // DNS records (domains/subdomains only)
	ServiceIDs []string    `json:"service_ids,omitempty"` // IDs of discovered services (IPs only)

	// Service-specific fields (when type == "service")
	Port     *int   `json:"port,omitempty"`      // port number for services
	Protocol string `json:"protocol,omitempty"`  // tcp, udp for services
	State    string `json:"state,omitempty"`     // open, closed, filtered for services
	Service  string `json:"service,omitempty"`   // http, ssh, ftp, etc. for services
	Version  string `json:"version,omitempty"`   // service version if detected
	SourceIP string `json:"source_ip,omitempty"` // source IP for service assets
}

// AssetCollection holds all discovered assets
type AssetCollection struct {
	Assets []Asset `json:"assets"`
}

// ReconConfig holds configuration for the reconnaissance service
type ReconConfig struct {
	EnableScanning  bool          `json:"enable_scanning"`
	EnableStreaming bool          `json:"enable_streaming"`
	DefaultTimeout  time.Duration `json:"default_timeout"`
	Verbose         bool          `json:"verbose"`
}

// ReconOptions holds options for a specific reconnaissance run
type ReconOptions struct {
	Hosts           []string      `json:"hosts"`
	EnableScanning  bool          `json:"enable_scanning"`
	EnableStreaming bool          `json:"enable_streaming"`
	Timeout         time.Duration `json:"timeout"`
	Verbose         bool          `json:"verbose"`
}
