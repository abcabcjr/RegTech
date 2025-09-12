package main

import (
	"bufio"
	"bytes"
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/ammario/ipisp"
	"github.com/projectdiscovery/subfinder/v2/pkg/runner"
	"github.com/spf13/cobra"
)

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

var (
	outputFile  string
	verbose     bool
	enableScans bool
	streaming   bool
)

// generateAssetID generates a unique ID for an asset based on its type and value
func generateAssetID(assetType, value string) string {
	hash := md5.Sum([]byte(fmt.Sprintf("%s:%s", assetType, value)))
	return hex.EncodeToString(hash[:])[:12] // Use first 12 characters
}

// generateServiceID generates a unique ID for a service based on IP, port, and protocol
func generateServiceID(ip string, port int, protocol string) string {
	hash := md5.Sum([]byte(fmt.Sprintf("service:%s:%d:%s", ip, port, protocol)))
	return hex.EncodeToString(hash[:])[:12] // Use first 12 characters
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "regtech [domains/subdomains/ips...]",
		Short: "A CLI tool for asset discovery and reconnaissance",
		Long:  `RegTech discovers subdomains, resolves IPs, and queries ASN information for given domains.`,
		Args:  cobra.MinimumNArgs(1),
		Run:   runAssetDiscovery,
	}

	rootCmd.Flags().StringVarP(&outputFile, "output", "o", "", "Output file for JSON results (default: stdout)")
	rootCmd.Flags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose output")
	rootCmd.Flags().BoolVarP(&enableScans, "scan", "s", false, "Enable port scanning with Nmap (requires nmap)")
	rootCmd.Flags().BoolVar(&streaming, "stream", false, "Enable streaming JSON output (one asset per line)")

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

func runAssetDiscovery(cmd *cobra.Command, args []string) {
	if verbose {
		log.Println("Starting asset discovery...")
	}

	if streaming {
		runStreamingAssetDiscovery(args)
	} else {
		runBatchAssetDiscovery(args)
	}
}

func runStreamingAssetDiscovery(args []string) {
	// Set up output writer
	var writer *bufio.Writer
	var file *os.File
	var err error

	if outputFile != "" {
		file, err = os.Create(outputFile)
		if err != nil {
			log.Fatalf("Error creating output file: %v", err)
		}
		defer file.Close()
		writer = bufio.NewWriter(file)
	} else {
		writer = bufio.NewWriter(os.Stdout)
	}
	defer writer.Flush()

	// Asset channel for streaming output
	assetChan := make(chan Asset, 100)
	var wg sync.WaitGroup

	// Start asset writer goroutine
	go func() {
		for asset := range assetChan {
			jsonData, err := json.Marshal(asset)
			if err != nil {
				if verbose {
					log.Printf("Error marshalling asset: %v", err)
				}
				continue
			}

			writer.Write(jsonData)
			writer.WriteString("\n")
			writer.Flush() // Immediate flush for streaming
		}
	}()

	// Process each input
	for _, input := range args {
		wg.Add(1)
		go func(input string) {
			defer wg.Done()
			processInputStreaming(input, assetChan)
		}(input)
	}

	wg.Wait()
	close(assetChan)

	if verbose && outputFile != "" {
		log.Printf("Streaming results written to %s", outputFile)
	}
}

func runBatchAssetDiscovery(args []string) {
	var allAssets []Asset
	var allServices []Asset
	var wg sync.WaitGroup
	var mutex sync.Mutex

	// Process each input (could be domain, subdomain, or IP)
	for _, input := range args {
		wg.Add(1)
		go func(input string) {
			defer wg.Done()
			assets, services := processInputWithServices(input)

			mutex.Lock()
			allAssets = append(allAssets, assets...)
			allServices = append(allServices, services...)
			mutex.Unlock()
		}(input)
	}

	wg.Wait()

	// Combine all assets (domains, subdomains, IPs, and services)
	finalAssets := append(allAssets, allServices...)

	// Create final output
	collection := AssetCollection{Assets: finalAssets}

	// Marshal to JSON
	output, err := json.MarshalIndent(collection, "", "  ")
	if err != nil {
		log.Fatalf("Error marshalling JSON: %v", err)
	}

	// Output results
	if outputFile != "" {
		err := os.WriteFile(outputFile, output, 0644)
		if err != nil {
			log.Fatalf("Error writing to file: %v", err)
		}
		if verbose {
			log.Printf("Results written to %s", outputFile)
		}
	} else {
		fmt.Println(string(output))
	}
}

// processInputWithServices processes input and returns separate asset and service lists
func processInputWithServices(input string) ([]Asset, []Asset) {
	var assets []Asset
	var services []Asset

	// Determine if input is IP or domain
	if net.ParseIP(input) != nil {
		// It's an IP
		asset, serviceAssets := processIPWithServices(input)
		assets = append(assets, asset)
		services = append(services, serviceAssets...)
	} else {
		// It's a domain or subdomain
		isDomain := !strings.Contains(input, ".") || isRootDomain(input)

		if isDomain {
			// Process as main domain - discover subdomains
			domainAssets, domainServices := processDomainWithServices(input)
			assets = append(assets, domainAssets...)
			services = append(services, domainServices...)
		} else {
			// Process as standalone subdomain
			if verbose {
				log.Printf("Processing standalone subdomain: %s", input)
			}

			subAsset := Asset{
				ID:    generateAssetID("subdomain", input),
				Type:  "subdomain",
				Value: input,
			}

			// Resolve IPs for standalone subdomain
			subIPs := resolveIPs(input)
			subAsset.IPs = subIPs

			// Check if standalone subdomain is proxied
			if len(subIPs) > 0 {
				proxied := isProxied(subIPs)
				subAsset.Proxied = &proxied
			}

			// Perform comprehensive DNS lookup
			subAsset.DNSRecords = performDNSLookup(input)
			assets = append(assets, subAsset)

			// Create IP assets and services for each unique IP
			for _, ip := range subIPs {
				ipAsset, ipServices := processIPWithServices(ip)
				assets = append(assets, ipAsset)
				services = append(services, ipServices...)
			}
		}
	}

	return assets, services
}

// processInputStreaming processes input and streams assets as they're discovered
func processInputStreaming(input string, assetChan chan<- Asset) {
	// Determine if input is IP or domain
	if net.ParseIP(input) != nil {
		// It's an IP
		processIPStreaming(input, assetChan)
	} else {
		// It's a domain or subdomain
		isDomain := !strings.Contains(input, ".") || isRootDomain(input)

		if isDomain {
			// Process as main domain - discover subdomains
			processDomainStreaming(input, assetChan)
		} else {
			// Process as standalone subdomain
			processSubdomainStreaming(input, assetChan)
		}
	}
}

// Legacy function for compatibility
func processInput(input string) []Asset {
	assets, services := processInputWithServices(input)
	return append(assets, services...)
}

func isRootDomain(domain string) bool {
	// Simple heuristic: if it has only one dot and common TLD, treat as root domain
	parts := strings.Split(domain, ".")
	return len(parts) == 2
}

func processDomainWithServices(domain string) ([]Asset, []Asset) {
	var assets []Asset
	var services []Asset
	var allIPs []string
	ipSet := make(map[string]bool) // To track unique IPs

	if verbose {
		log.Printf("Processing domain: %s", domain)
	}

	// Discover subdomains
	subdomains, err := findSubdomains(domain)
	if err != nil {
		if verbose {
			log.Printf("Error finding subdomains for %s: %v", domain, err)
		}
		subdomains = []string{} // Continue with empty subdomains
	}

	// Create main domain asset
	domainAsset := Asset{
		ID:         generateAssetID("domain", domain),
		Type:       "domain",
		Value:      domain,
		Subdomains: subdomains,
	}

	// Resolve IPs for main domain
	domainIPs := resolveIPs(domain)
	domainAsset.IPs = domainIPs

	// Check if domain is proxied
	if len(domainIPs) > 0 {
		proxied := isProxied(domainIPs)
		domainAsset.Proxied = &proxied
	}

	// Perform comprehensive DNS lookup
	domainAsset.DNSRecords = performDNSLookup(domain)

	// Add domain IPs to the unique set
	for _, ip := range domainIPs {
		if !ipSet[ip] {
			ipSet[ip] = true
			allIPs = append(allIPs, ip)
		}
	}

	assets = append(assets, domainAsset)

	// Process each subdomain
	for _, subdomain := range subdomains {
		if verbose {
			log.Printf("Processing subdomain: %s", subdomain)
		}

		subAsset := Asset{
			ID:    generateAssetID("subdomain", subdomain),
			Type:  "subdomain",
			Value: subdomain,
		}

		// Resolve IPs for subdomain
		subIPs := resolveIPs(subdomain)
		subAsset.IPs = subIPs

		// Check if subdomain is proxied
		if len(subIPs) > 0 {
			proxied := isProxied(subIPs)
			subAsset.Proxied = &proxied
		}

		// Perform comprehensive DNS lookup
		subAsset.DNSRecords = performDNSLookup(subdomain)

		// Add subdomain IPs to the unique set
		for _, ip := range subIPs {
			if !ipSet[ip] {
				ipSet[ip] = true
				allIPs = append(allIPs, ip)
			}
		}

		assets = append(assets, subAsset)
	}

	// Create IP assets and services for all unique IPs discovered
	for _, ip := range allIPs {
		ipAsset, ipServices := processIPWithServices(ip)
		assets = append(assets, ipAsset)
		services = append(services, ipServices...)
	}

	return assets, services
}

// Legacy function for compatibility
func processDomain(domain string) []Asset {
	assets, services := processDomainWithServices(domain)
	return append(assets, services...)
}

func processIPWithServices(ip string) (Asset, []Asset) {
	if verbose {
		log.Printf("Processing IP: %s", ip)
	}

	asset := Asset{
		ID:    generateAssetID("ip", ip),
		Type:  "ip",
		Value: ip,
		IPs:   []string{ip},
	}

	var serviceAssets []Asset
	var serviceIDs []string

	// Query ASN for IP
	parsedIP := net.ParseIP(ip)
	if parsedIP != nil {
		client, err := ipisp.NewDNSClient()
		if err == nil {
			resp, err := client.LookupIP(parsedIP)
			if err == nil {
				asset.ASN = fmt.Sprintf("AS%d", resp.ASN)
				asset.ASNOrg = resp.Name.Raw
			}
		}
	}

	// Check if IP is proxied (CDN/proxy)
	isProxiedIP := isProxiedIP(ip)

	// Scan for open ports if not proxied and scanning is enabled
	if enableScans && !isProxiedIP {
		if services, err := scanPortsWithNmap(ip); err == nil {
			// Create service assets for each discovered service
			for _, service := range services {
				serviceID := generateServiceID(ip, service.Port, service.Protocol)
				serviceAsset := Asset{
					ID:       serviceID,
					Type:     "service",
					Value:    fmt.Sprintf("%s:%d/%s", ip, service.Port, service.Protocol),
					Port:     &service.Port,
					Protocol: service.Protocol,
					State:    service.State,
					Service:  service.Service,
					Version:  service.Version,
					SourceIP: ip,
				}
				serviceAssets = append(serviceAssets, serviceAsset)
				serviceIDs = append(serviceIDs, serviceID)
			}
		} else {
			if verbose {
				log.Printf("Port scan failed for IP %s: %v", ip, err)
			}
			// Still return the asset without services rather than failing completely
		}
	} else if verbose {
		if !enableScans {
			log.Printf("Port scanning disabled for IP %s (use --scan to enable)", ip)
		} else {
			log.Printf("Skipping port scan for proxied IP %s", ip)
		}
	}

	// Add service IDs to the IP asset
	if len(serviceIDs) > 0 {
		asset.ServiceIDs = serviceIDs
	}

	return asset, serviceAssets
}

// Legacy function for compatibility
func processIP(ip string) Asset {
	asset, _ := processIPWithServices(ip)
	return asset
}

func findSubdomains(domain string) ([]string, error) {
	if verbose {
		log.Printf("Starting subdomain enumeration for %s", domain)
	}

	// Configure subfinder options
	options := &runner.Options{
		Threads:            10,
		Timeout:            30,
		MaxEnumerationTime: 60, // 1 minute max enumeration time
		Silent:             true,
		Verbose:            false,
		RemoveWildcard:     true,
		All:                true, // Use all available sources
	}

	// Create subfinder runner
	subfinderRunner, err := runner.NewRunner(options)
	if err != nil {
		if verbose {
			log.Printf("Error creating subfinder runner: %v", err)
		}
		return []string{}, err
	}

	// Create output buffer to capture results
	output := &bytes.Buffer{}
	var sourceMap map[string]map[string]struct{}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Run subdomain enumeration on single domain
	sourceMap, err = subfinderRunner.EnumerateSingleDomainWithCtx(ctx, domain, []io.Writer{output})
	if err != nil {
		if verbose {
			log.Printf("Error during subfinder enumeration: %v", err)
		}
		return []string{}, err
	}

	// Parse output buffer to extract subdomains
	var subdomains []string
	outputStr := output.String()
	lines := strings.Split(strings.TrimSpace(outputStr), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && line != domain {
			subdomains = append(subdomains, line)
		}
	}

	// Also extract from sourceMap if available
	for subdomain := range sourceMap {
		if subdomain != domain {
			// Check if already in list to avoid duplicates
			found := false
			for _, existing := range subdomains {
				if existing == subdomain {
					found = true
					break
				}
			}
			if !found {
				subdomains = append(subdomains, subdomain)
			}
		}
	}

	if verbose {
		log.Printf("Found %d subdomains for %s", len(subdomains), domain)
	}

	return subdomains, nil
}

func resolveIPs(hostname string) []string {
	// Resolve IPs
	ips, err := net.LookupIP(hostname)
	if err != nil {
		if verbose {
			log.Printf("Error resolving IPs for %s: %v", hostname, err)
		}
		return []string{}
	}

	var ipStrings []string
	for _, ip := range ips {
		ipStrings = append(ipStrings, ip.String())
	}

	return ipStrings
}

// isProxied checks if any of the IPs belong to known CDN/proxy providers
func isProxied(ips []string) bool {
	for _, ip := range ips {
		if isProxiedIP(ip) {
			return true
		}
	}
	return false
}

// isProxiedIP checks if a single IP belongs to known CDN/proxy providers
func isProxiedIP(ip string) bool {
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}

	// Get ASN information for the IP
	client, err := ipisp.NewDNSClient()
	if err != nil {
		return false
	}

	resp, err := client.LookupIP(parsedIP)
	if err != nil {
		return false
	}

	// Check if ASN belongs to known CDN/proxy providers
	asnOrg := strings.ToLower(resp.Name.Raw)

	// List of known CDN/proxy ASN organizations
	cdnProviders := []string{
		"cloudflare",
		"akamai",
		"amazon",
		"aws",
		"cloudfront",
		"fastly",
		"incapsula",
		"imperva",
		"maxcdn",
		"stackpath",
		"keycdn",
		"bunnycdn",
		"jsdelivr",
		"cdnjs",
		"google cloud",
		"microsoft azure",
		"azure",
		"sucuri",
		"ddos-guard",
		"ovh cdn",
		"limelight",
		"edgecast",
		"verizon",
		"level3",
		"centurylink",
	}

	for _, provider := range cdnProviders {
		if strings.Contains(asnOrg, provider) {
			if verbose {
				log.Printf("IP %s detected as proxied through %s (ASN: AS%d)", ip, resp.Name.Raw, resp.ASN)
			}
			return true
		}
	}

	return false
}

// performDNSLookup performs comprehensive DNS record lookups for a domain/subdomain
func performDNSLookup(hostname string) *DNSRecords {
	if verbose {
		log.Printf("Performing DNS lookup for %s", hostname)
	}

	records := &DNSRecords{}
	isRootDom := isRootDomain(hostname)

	// A and AAAA records (IPv4 and IPv6) - available for both domains and subdomains
	if aRecords, err := net.LookupIP(hostname); err == nil {
		for _, ip := range aRecords {
			if ipv4 := ip.To4(); ipv4 != nil {
				records.A = append(records.A, ip.String())
			} else {
				records.AAAA = append(records.AAAA, ip.String())
			}
		}
	} else if verbose {
		log.Printf("No A/AAAA records found for %s: %v", hostname, err)
	}

	// CNAME records - more common for subdomains
	if cname, err := net.LookupCNAME(hostname); err == nil && cname != hostname+"." {
		records.CNAME = append(records.CNAME, strings.TrimSuffix(cname, "."))
	} else if verbose && err != nil {
		log.Printf("No CNAME records found for %s: %v", hostname, err)
	}

	// TXT records - available for both domains and subdomains
	if txtRecords, err := net.LookupTXT(hostname); err == nil && len(txtRecords) > 0 {
		records.TXT = txtRecords
	} else if verbose && err != nil {
		log.Printf("No TXT records found for %s: %v", hostname, err)
	}

	// MX records - typically only for root domains or mail subdomains
	if mxRecords, err := net.LookupMX(hostname); err == nil && len(mxRecords) > 0 {
		for _, mx := range mxRecords {
			mxStr := fmt.Sprintf("%d %s", mx.Pref, strings.TrimSuffix(mx.Host, "."))
			records.MX = append(records.MX, mxStr)
		}
	} else if verbose && err != nil && isRootDom {
		log.Printf("No MX records found for %s: %v", hostname, err)
	}

	// NS records - typically only for root domains
	if isRootDom {
		if nsRecords, err := net.LookupNS(hostname); err == nil && len(nsRecords) > 0 {
			for _, ns := range nsRecords {
				records.NS = append(records.NS, strings.TrimSuffix(ns.Host, "."))
			}
		} else if verbose && err != nil {
			log.Printf("No NS records found for %s: %v", hostname, err)
		}

		// SOA record - only for root domains
		if soaRecords, err := lookupSOA(hostname); err == nil && len(soaRecords) > 0 {
			records.SOA = soaRecords
		} else if verbose && err != nil {
			log.Printf("No SOA records found for %s: %v", hostname, err)
		}
	}

	// PTR records (reverse DNS) - for the resolved IPs
	allIPs := append(records.A, records.AAAA...)
	for _, ip := range allIPs {
		if ptrRecords, err := net.LookupAddr(ip); err == nil && len(ptrRecords) > 0 {
			for _, ptr := range ptrRecords {
				ptrClean := strings.TrimSuffix(ptr, ".")
				// Avoid duplicates
				found := false
				for _, existing := range records.PTR {
					if existing == ptrClean {
						found = true
						break
					}
				}
				if !found {
					records.PTR = append(records.PTR, ptrClean)
				}
			}
		}
	}

	return records
}

// lookupSOA attempts to lookup SOA records (simplified implementation)
func lookupSOA(hostname string) ([]string, error) {
	// This is a simplified approach since Go's net package doesn't have direct SOA lookup
	// In a production environment, you might want to use a more comprehensive DNS library
	// like github.com/miekg/dns for more detailed DNS record types

	// For now, we'll try to infer from NS records
	if nsRecords, err := net.LookupNS(hostname); err == nil && len(nsRecords) > 0 {
		// Return the first NS as a simplified SOA indication
		return []string{fmt.Sprintf("Primary NS: %s", strings.TrimSuffix(nsRecords[0].Host, "."))}, nil
	}

	return []string{}, fmt.Errorf("no SOA records found")
}

// scanPortsWithNmap performs efficient Nmap SYN scan on an IP address
func scanPortsWithNmap(ip string) ([]Service, error) {
	if verbose {
		log.Printf("Starting Nmap scan for %s", ip)
	}

	// Check if nmap is available
	if _, err := exec.LookPath("nmap"); err != nil {
		if verbose {
			log.Printf("Nmap not found in PATH, skipping port scan for %s", ip)
		}
		return []Service{}, fmt.Errorf("nmap not available")
	}

	// Efficient Nmap command for SYN scan
	// -sS: SYN scan (stealth scan)
	// -T4: Aggressive timing template (faster)
	// --top-ports 1000: Scan top 1000 most common ports
	// -n: Never do DNS resolution
	// --open: Only show open ports
	// -Pn: Treat all hosts as online (skip host discovery)
	args := []string{
		"-sS",                 // SYN scan
		"-T4",                 // Aggressive timing
		"--top-ports", "1000", // Top 1000 ports
		"-n",                 // No DNS resolution
		"--open",             // Only open ports
		"-Pn",                // Skip ping
		"--max-retries", "1", // Reduce retries for speed
		"--max-rtt-timeout", "500ms", // Reduce timeout
		ip,
	}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "nmap", args...)
	output, err := cmd.CombinedOutput() // Use CombinedOutput to get both stdout and stderr
	if err != nil {
		if verbose {
			log.Printf("SYN scan failed for %s: %v", ip, err)
			log.Printf("Nmap output: %s", string(output))
			log.Printf("Trying TCP connect scan as fallback...")
		}

		// Fallback to TCP connect scan (doesn't require root)
		fallbackArgs := []string{
			"-sT",                // TCP connect scan
			"-T4",                // Aggressive timing
			"--top-ports", "100", // Reduced ports for TCP connect
			"-n",                 // No DNS resolution
			"--open",             // Only show open ports
			"-Pn",                // Skip ping
			"--max-retries", "1", // Reduce retries for speed
			"--max-rtt-timeout", "1000ms", // Slightly higher timeout for TCP
			ip,
		}

		fallbackCtx, fallbackCancel := context.WithTimeout(context.Background(), 90*time.Second)
		defer fallbackCancel()

		fallbackCmd := exec.CommandContext(fallbackCtx, "nmap", fallbackArgs...)
		fallbackOutput, fallbackErr := fallbackCmd.CombinedOutput()

		if fallbackErr != nil {
			if verbose {
				log.Printf("TCP connect scan also failed for %s: %v", ip, fallbackErr)
				log.Printf("Fallback Nmap output: %s", string(fallbackOutput))
			}
			return []Service{}, fmt.Errorf("both SYN scan and TCP connect scan failed. SYN error: %v, TCP error: %v, TCP output: %s", err, fallbackErr, string(fallbackOutput))
		}

		if verbose {
			log.Printf("TCP connect scan succeeded for %s", ip)
		}
		output = fallbackOutput
	}

	services := parseNmapOutput(string(output))

	if verbose {
		log.Printf("Found %d open ports on %s", len(services), ip)
	}

	return services, nil
}

// parseNmapOutput parses Nmap output to extract services
func parseNmapOutput(output string) []Service {
	var services []Service

	// Regular expression to match port lines like "22/tcp   open  ssh"
	portRegex := regexp.MustCompile(`(\d+)/(tcp|udp)\s+(open|closed|filtered)\s+(.*)`)

	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		matches := portRegex.FindStringSubmatch(line)
		if len(matches) >= 4 {
			port, err := strconv.Atoi(matches[1])
			if err != nil {
				continue
			}

			protocol := matches[2]
			state := matches[3]
			serviceInfo := strings.TrimSpace(matches[4])

			// Only include open ports
			if state == "open" {
				service := Service{
					Port:     port,
					Protocol: protocol,
					State:    state,
				}

				// Parse service name and version if available
				if serviceInfo != "" {
					parts := strings.Fields(serviceInfo)
					if len(parts) > 0 {
						service.Service = parts[0]
						if len(parts) > 1 {
							service.Version = strings.Join(parts[1:], " ")
						}
					}
				}

				services = append(services, service)
			}
		}
	}

	return services
}

// scanIPConcurrently scans an IP for open ports if it's not proxied
func scanIPConcurrently(ip string, isProxiedIP bool, resultChan chan<- []Service, wg *sync.WaitGroup) {
	defer wg.Done()

	if isProxiedIP {
		if verbose {
			log.Printf("Skipping port scan for proxied IP %s", ip)
		}
		resultChan <- []Service{}
		return
	}

	services, err := scanPortsWithNmap(ip)
	if err != nil {
		if verbose {
			log.Printf("Port scan failed for %s: %v", ip, err)
		}
		resultChan <- []Service{}
		return
	}

	if verbose && len(services) > 0 {
		log.Printf("Successfully scanned %s: found %d services", ip, len(services))
	}

	resultChan <- services
}

// Streaming processing functions
func processDomainStreaming(domain string, assetChan chan<- Asset) {
	if verbose {
		log.Printf("Processing domain: %s", domain)
	}

	// Discover subdomains
	subdomains, err := findSubdomains(domain)
	if err != nil {
		if verbose {
			log.Printf("Error finding subdomains for %s: %v", domain, err)
		}
		subdomains = []string{} // Continue with empty subdomains
	}

	// Create and stream main domain asset
	domainAsset := Asset{
		ID:         generateAssetID("domain", domain),
		Type:       "domain",
		Value:      domain,
		Subdomains: subdomains,
	}

	// Resolve IPs for main domain
	domainIPs := resolveIPs(domain)
	domainAsset.IPs = domainIPs

	// Check if domain is proxied
	if len(domainIPs) > 0 {
		proxied := isProxied(domainIPs)
		domainAsset.Proxied = &proxied
	}

	// Perform comprehensive DNS lookup
	domainAsset.DNSRecords = performDNSLookup(domain)

	// Stream the domain asset
	assetChan <- domainAsset

	// Track unique IPs
	ipSet := make(map[string]bool)
	for _, ip := range domainIPs {
		ipSet[ip] = true
	}

	// Process each subdomain and stream immediately
	for _, subdomain := range subdomains {
		processSubdomainStreaming(subdomain, assetChan)

		// Add subdomain IPs to unique set
		subIPs := resolveIPs(subdomain)
		for _, ip := range subIPs {
			ipSet[ip] = true
		}
	}

	// Process and stream IP assets for all unique IPs
	for ip := range ipSet {
		processIPStreaming(ip, assetChan)
	}
}

func processSubdomainStreaming(subdomain string, assetChan chan<- Asset) {
	if verbose {
		log.Printf("Processing subdomain: %s", subdomain)
	}

	subAsset := Asset{
		ID:    generateAssetID("subdomain", subdomain),
		Type:  "subdomain",
		Value: subdomain,
	}

	// Resolve IPs for subdomain
	subIPs := resolveIPs(subdomain)
	subAsset.IPs = subIPs

	// Check if subdomain is proxied
	if len(subIPs) > 0 {
		proxied := isProxied(subIPs)
		subAsset.Proxied = &proxied
	}

	// Perform comprehensive DNS lookup
	subAsset.DNSRecords = performDNSLookup(subdomain)

	// Stream the subdomain asset
	assetChan <- subAsset
}

func processIPStreaming(ip string, assetChan chan<- Asset) {
	if verbose {
		log.Printf("Processing IP: %s", ip)
	}

	asset := Asset{
		ID:    generateAssetID("ip", ip),
		Type:  "ip",
		Value: ip,
		IPs:   []string{ip},
	}

	var serviceIDs []string

	// Query ASN for IP
	parsedIP := net.ParseIP(ip)
	if parsedIP != nil {
		client, err := ipisp.NewDNSClient()
		if err == nil {
			resp, err := client.LookupIP(parsedIP)
			if err == nil {
				asset.ASN = fmt.Sprintf("AS%d", resp.ASN)
				asset.ASNOrg = resp.Name.Raw
			}
		}
	}

	// Check if IP is proxied (CDN/proxy)
	isProxiedIP := isProxiedIP(ip)

	// Scan for open ports if not proxied and scanning is enabled
	if enableScans && !isProxiedIP {
		if services, err := scanPortsWithNmap(ip); err == nil {
			// Create and stream service assets for each discovered service
			for _, service := range services {
				serviceID := generateServiceID(ip, service.Port, service.Protocol)
				serviceAsset := Asset{
					ID:       serviceID,
					Type:     "service",
					Value:    fmt.Sprintf("%s:%d/%s", ip, service.Port, service.Protocol),
					Port:     &service.Port,
					Protocol: service.Protocol,
					State:    service.State,
					Service:  service.Service,
					Version:  service.Version,
					SourceIP: ip,
				}

				// Stream the service asset immediately
				assetChan <- serviceAsset
				serviceIDs = append(serviceIDs, serviceID)
			}
		} else {
			if verbose {
				log.Printf("Port scan failed for IP %s: %v", ip, err)
			}
		}
	} else if verbose {
		if !enableScans {
			log.Printf("Port scanning disabled for IP %s (use --scan to enable)", ip)
		} else {
			log.Printf("Skipping port scan for proxied IP %s", ip)
		}
	}

	// Add service IDs to the IP asset
	if len(serviceIDs) > 0 {
		asset.ServiceIDs = serviceIDs
	}

	// Stream the IP asset
	assetChan <- asset
}
