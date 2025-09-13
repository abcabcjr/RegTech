package recon

import (
	"context"
	"fmt"
	"log"
	"net"
	"sync"

	"github.com/ammario/ipisp"
)

// Streaming processing functions

// processDomainStreaming processes a domain and streams assets as they're discovered
func (r *ReconService) processDomainStreaming(ctx context.Context, domain string, assetChan chan<- Asset, options *ReconOptions) {
	if options.Verbose {
		log.Printf("Processing domain: %s", domain)
	}

	// Discover subdomains
	subdomains, err := r.findSubdomains(ctx, domain)
	if err != nil {
		if options.Verbose {
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
	domainIPs := r.resolveIPs(domain)
	domainAsset.IPs = domainIPs

	// Check if domain is proxied
	if len(domainIPs) > 0 {
		proxied := r.isProxied(domainIPs)
		domainAsset.Proxied = &proxied
	}

	// Perform comprehensive DNS lookup
	domainAsset.DNSRecords = r.performDNSLookup(domain)

	// Stream the domain asset
	select {
	case assetChan <- domainAsset:
	case <-ctx.Done():
		return
	}

	// Track unique IPs
	ipSet := make(map[string]bool)
	for _, ip := range domainIPs {
		ipSet[ip] = true
	}

	// Process each subdomain and stream immediately
	var wg sync.WaitGroup
	for _, subdomain := range subdomains {
		wg.Add(1)
		go func(subdomain string) {
			defer wg.Done()
			r.processSubdomainStreaming(ctx, subdomain, assetChan, options)

			// Add subdomain IPs to unique set
			subIPs := r.resolveIPs(subdomain)
			for _, ip := range subIPs {
				ipSet[ip] = true
			}
		}(subdomain)
	}

	wg.Wait()

	// Process and stream IP assets for all unique IPs
	var ipWg sync.WaitGroup
	for ip := range ipSet {
		ipWg.Add(1)
		go func(ip string) {
			defer ipWg.Done()
			r.processIPStreaming(ctx, ip, assetChan, options)
		}(ip)
	}
	ipWg.Wait()
}

// processSubdomainStreaming processes a subdomain and streams the asset
func (r *ReconService) processSubdomainStreaming(ctx context.Context, subdomain string, assetChan chan<- Asset, options *ReconOptions) {
	if options.Verbose {
		log.Printf("Processing subdomain: %s", subdomain)
	}

	subAsset := Asset{
		ID:    generateAssetID("subdomain", subdomain),
		Type:  "subdomain",
		Value: subdomain,
	}

	// Resolve IPs for subdomain
	subIPs := r.resolveIPs(subdomain)
	subAsset.IPs = subIPs

	// Check if subdomain is proxied
	if len(subIPs) > 0 {
		proxied := r.isProxied(subIPs)
		subAsset.Proxied = &proxied
	}

	// Perform comprehensive DNS lookup
	subAsset.DNSRecords = r.performDNSLookup(subdomain)

	// Stream the subdomain asset
	select {
	case assetChan <- subAsset:
	case <-ctx.Done():
		return
	}
}

// processIPStreaming processes an IP and streams the asset and any discovered services
func (r *ReconService) processIPStreaming(ctx context.Context, ip string, assetChan chan<- Asset, options *ReconOptions) {
	if options.Verbose {
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
	if parsedIP := parseIP(ip); parsedIP != nil {
		if client, err := newISPClient(); err == nil {
			if resp, err := client.LookupIP(parsedIP); err == nil {
				asset.ASN = formatASN(resp.ASN)
				asset.ASNOrg = resp.Name.Raw
			}
		}
	}

	// Check if IP is proxied (CDN/proxy)
	isProxiedIP := r.isProxiedIP(ip)

	// Scan for open ports if not proxied and scanning is enabled
	if options.EnableScanning && !isProxiedIP {
		if services, err := r.scanPortsWithNmap(ctx, ip, options); err == nil {
			// Create and stream service assets for each discovered service
			for _, service := range services {
				serviceID := generateServiceID(ip, service.Port, service.Protocol)
				serviceAsset := Asset{
					ID:       serviceID,
					Type:     "service",
					Value:    formatServiceValue(ip, service.Port, service.Protocol),
					Port:     &service.Port,
					Protocol: service.Protocol,
					State:    service.State,
					Service:  service.Service,
					Version:  service.Version,
					SourceIP: ip,
				}

				// Stream the service asset immediately
				select {
				case assetChan <- serviceAsset:
				case <-ctx.Done():
					return
				}
				serviceIDs = append(serviceIDs, serviceID)
			}
		} else {
			if options.Verbose {
				log.Printf("Port scan failed for IP %s: %v", ip, err)
			}
		}
	} else if options.Verbose {
		if !options.EnableScanning {
			log.Printf("Port scanning disabled for IP %s", ip)
		} else {
			log.Printf("Skipping port scan for proxied IP %s", ip)
		}
	}

	// Add service IDs to the IP asset
	if len(serviceIDs) > 0 {
		asset.ServiceIDs = serviceIDs
	}

	// Stream the IP asset
	select {
	case assetChan <- asset:
	case <-ctx.Done():
		return
	}
}

// Helper functions for streaming operations

func parseIP(ip string) net.IP {
	return net.ParseIP(ip)
}

func newISPClient() (ipisp.Client, error) {
	return ipisp.NewDNSClient()
}

func formatASN(asn ipisp.ASN) string {
	return fmt.Sprintf("AS%d", asn)
}

func formatServiceValue(ip string, port int, protocol string) string {
	return fmt.Sprintf("%s:%d/%s", ip, port, protocol)
}
