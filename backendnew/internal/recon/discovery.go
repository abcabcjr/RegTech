package recon

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"strings"
	"time"

	"github.com/ammario/ipisp"
	"github.com/projectdiscovery/subfinder/v2/pkg/runner"
)

// findSubdomains discovers subdomains for a given domain using subfinder
func (r *ReconService) findSubdomains(ctx context.Context, domain string) ([]string, error) {
	if r.config.Verbose {
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
		if r.config.Verbose {
			log.Printf("Error creating subfinder runner: %v", err)
		}
		return []string{}, err
	}

	// Create output buffer to capture results
	output := &bytes.Buffer{}
	var sourceMap map[string]map[string]struct{}

	// Create context with timeout
	ctxWithTimeout, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	// Run subdomain enumeration on single domain
	sourceMap, err = subfinderRunner.EnumerateSingleDomainWithCtx(ctxWithTimeout, domain, []io.Writer{output})
	if err != nil {
		if r.config.Verbose {
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

	if r.config.Verbose {
		log.Printf("Found %d subdomains for %s", len(subdomains), domain)
	}

	return subdomains, nil
}

// resolveIPs resolves IP addresses for a hostname
func (r *ReconService) resolveIPs(hostname string) []string {
	// Resolve IPs
	ips, err := net.LookupIP(hostname)
	if err != nil {
		if r.config.Verbose {
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
func (r *ReconService) isProxied(ips []string) bool {
	for _, ip := range ips {
		if r.isProxiedIP(ip) {
			return true
		}
	}
	return false
}

// isProxiedIP checks if a single IP belongs to known CDN/proxy providers
func (r *ReconService) isProxiedIP(ip string) bool {
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
			if r.config.Verbose {
				log.Printf("IP %s detected as proxied through %s (ASN: AS%d)", ip, resp.Name.Raw, resp.ASN)
			}
			return true
		}
	}

	return false
}

// performDNSLookup performs comprehensive DNS record lookups for a domain/subdomain
func (r *ReconService) performDNSLookup(hostname string) *DNSRecords {
	if r.config.Verbose {
		log.Printf("Performing DNS lookup for %s", hostname)
	}

	records := &DNSRecords{}
	isRootDom := r.isRootDomain(hostname)

	// A and AAAA records (IPv4 and IPv6) - available for both domains and subdomains
	if aRecords, err := net.LookupIP(hostname); err == nil {
		for _, ip := range aRecords {
			if ipv4 := ip.To4(); ipv4 != nil {
				records.A = append(records.A, ip.String())
			} else {
				records.AAAA = append(records.AAAA, ip.String())
			}
		}
	} else if r.config.Verbose {
		log.Printf("No A/AAAA records found for %s: %v", hostname, err)
	}

	// CNAME records - more common for subdomains
	if cname, err := net.LookupCNAME(hostname); err == nil && cname != hostname+"." {
		records.CNAME = append(records.CNAME, strings.TrimSuffix(cname, "."))
	} else if r.config.Verbose && err != nil {
		log.Printf("No CNAME records found for %s: %v", hostname, err)
	}

	// TXT records - available for both domains and subdomains
	if txtRecords, err := net.LookupTXT(hostname); err == nil && len(txtRecords) > 0 {
		records.TXT = txtRecords
	} else if r.config.Verbose && err != nil {
		log.Printf("No TXT records found for %s: %v", hostname, err)
	}

	// MX records - typically only for root domains or mail subdomains
	if mxRecords, err := net.LookupMX(hostname); err == nil && len(mxRecords) > 0 {
		for _, mx := range mxRecords {
			mxStr := fmt.Sprintf("%d %s", mx.Pref, strings.TrimSuffix(mx.Host, "."))
			records.MX = append(records.MX, mxStr)
		}
	} else if r.config.Verbose && err != nil && isRootDom {
		log.Printf("No MX records found for %s: %v", hostname, err)
	}

	// NS records - typically only for root domains
	if isRootDom {
		if nsRecords, err := net.LookupNS(hostname); err == nil && len(nsRecords) > 0 {
			for _, ns := range nsRecords {
				records.NS = append(records.NS, strings.TrimSuffix(ns.Host, "."))
			}
		} else if r.config.Verbose && err != nil {
			log.Printf("No NS records found for %s: %v", hostname, err)
		}

		// SOA record - only for root domains
		if soaRecords, err := r.lookupSOA(hostname); err == nil && len(soaRecords) > 0 {
			records.SOA = soaRecords
		} else if r.config.Verbose && err != nil {
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
func (r *ReconService) lookupSOA(hostname string) ([]string, error) {
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
