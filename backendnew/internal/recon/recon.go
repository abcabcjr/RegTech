package recon

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"log"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/ammario/ipisp"
)

// ReconService provides asset discovery and reconnaissance functionality
type ReconService struct {
	config *ReconConfig
}

// NewReconService creates a new reconnaissance service
func NewReconService(config *ReconConfig) *ReconService {
	if config == nil {
		config = &ReconConfig{
			EnableScanning:  true,
			EnableStreaming: true,
			DefaultTimeout:  10 * time.Minute,
			Verbose:         false,
		}
	}
	return &ReconService{
		config: config,
	}
}

// DiscoverAssets performs asset discovery for the given hosts
func (r *ReconService) DiscoverAssets(ctx context.Context, options *ReconOptions) (<-chan Asset, error) {
	if options == nil {
		options = &ReconOptions{
			EnableScanning:  r.config.EnableScanning,
			EnableStreaming: r.config.EnableStreaming,
			Timeout:         r.config.DefaultTimeout,
			Verbose:         r.config.Verbose,
		}
	}

	// Create asset channel for streaming output
	assetChan := make(chan Asset, 100)

	// Start discovery in background
	go func() {
		defer close(assetChan)

		var wg sync.WaitGroup
		for _, host := range options.Hosts {
			wg.Add(1)
			go func(host string) {
				defer wg.Done()
				r.processInputStreaming(ctx, host, assetChan, options)
			}(host)
		}
		wg.Wait()
	}()

	return assetChan, nil
}

// DiscoverAssetsBatch performs batch asset discovery (non-streaming)
func (r *ReconService) DiscoverAssetsBatch(ctx context.Context, options *ReconOptions) ([]Asset, error) {
	var allAssets []Asset
	var allServices []Asset
	var wg sync.WaitGroup
	var mutex sync.Mutex

	// Process each input (could be domain, subdomain, or IP)
	for _, input := range options.Hosts {
		wg.Add(1)
		go func(input string) {
			defer wg.Done()
			assets, services := r.processInputWithServices(ctx, input, options)

			mutex.Lock()
			allAssets = append(allAssets, assets...)
			allServices = append(allServices, services...)
			mutex.Unlock()
		}(input)
	}

	wg.Wait()

	// Combine all assets (domains, subdomains, IPs, and services)
	finalAssets := append(allAssets, allServices...)
	return finalAssets, nil
}

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

// processInputWithServices processes input and returns separate asset and service lists
func (r *ReconService) processInputWithServices(ctx context.Context, input string, options *ReconOptions) ([]Asset, []Asset) {
	var assets []Asset
	var services []Asset

	// Determine if input is IP or domain
	if net.ParseIP(input) != nil {
		// It's an IP
		asset, serviceAssets := r.processIPWithServices(ctx, input, options)
		assets = append(assets, asset)
		services = append(services, serviceAssets...)
	} else {
		// It's a domain or subdomain
		isDomain := !strings.Contains(input, ".") || r.isRootDomain(input)

		if isDomain {
			// Process as main domain - discover subdomains
			domainAssets, domainServices := r.processDomainWithServices(ctx, input, options)
			assets = append(assets, domainAssets...)
			services = append(services, domainServices...)
		} else {
			// Process as standalone subdomain
			if options.Verbose {
				log.Printf("Processing standalone subdomain: %s", input)
			}

			subAsset := Asset{
				ID:    generateAssetID("subdomain", input),
				Type:  "subdomain",
				Value: input,
			}

			// Resolve IPs for standalone subdomain
			subIPs := r.resolveIPs(input)
			subAsset.IPs = subIPs

			// Check if standalone subdomain is proxied
			if len(subIPs) > 0 {
				proxied := r.isProxied(subIPs)
				subAsset.Proxied = &proxied
			}

			// Perform comprehensive DNS lookup
			subAsset.DNSRecords = r.performDNSLookup(input)
			assets = append(assets, subAsset)

			// Create IP assets and services for each unique IP
			for _, ip := range subIPs {
				ipAsset, ipServices := r.processIPWithServices(ctx, ip, options)
				assets = append(assets, ipAsset)
				services = append(services, ipServices...)
			}
		}
	}

	return assets, services
}

// processInputStreaming processes input and streams assets as they're discovered
func (r *ReconService) processInputStreaming(ctx context.Context, input string, assetChan chan<- Asset, options *ReconOptions) {
	// Determine if input is IP or domain
	if net.ParseIP(input) != nil {
		// It's an IP
		r.processIPStreaming(ctx, input, assetChan, options)
	} else {
		// It's a domain or subdomain
		isDomain := !strings.Contains(input, ".") || r.isRootDomain(input)

		if isDomain {
			// Process as main domain - discover subdomains
			r.processDomainStreaming(ctx, input, assetChan, options)
		} else {
			// Process as standalone subdomain
			r.processSubdomainStreaming(ctx, input, assetChan, options)
		}
	}
}

func (r *ReconService) isRootDomain(domain string) bool {
	// Simple heuristic: if it has only one dot and common TLD, treat as root domain
	parts := strings.Split(domain, ".")
	return len(parts) == 2
}

func (r *ReconService) processDomainWithServices(ctx context.Context, domain string, options *ReconOptions) ([]Asset, []Asset) {
	var assets []Asset
	var services []Asset
	var allIPs []string
	ipSet := make(map[string]bool) // To track unique IPs

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

	// Create main domain asset
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
		ipAsset, ipServices := r.processIPWithServices(ctx, ip, options)
		assets = append(assets, ipAsset)
		services = append(services, ipServices...)
	}

	return assets, services
}

func (r *ReconService) processIPWithServices(ctx context.Context, ip string, options *ReconOptions) (Asset, []Asset) {
	if options.Verbose {
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
	isProxiedIP := r.isProxiedIP(ip)

	// Scan for open ports if not proxied and scanning is enabled
	if options.EnableScanning && !isProxiedIP {
		if services, err := r.scanPortsWithNmap(ctx, ip, options); err == nil {
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
			if options.Verbose {
				log.Printf("Port scan failed for IP %s: %v", ip, err)
			}
			// Still return the asset without services rather than failing completely
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

	return asset, serviceAssets
}
