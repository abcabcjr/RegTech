package recon

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// scanPortsWithNmap performs efficient Nmap SYN scan on an IP address
func (r *ReconService) scanPortsWithNmap(ctx context.Context, ip string, options *ReconOptions) ([]Service, error) {
	if options.Verbose {
		log.Printf("Starting Nmap scan for %s", ip)
	}

	// Check if nmap is available
	if _, err := exec.LookPath("nmap"); err != nil {
		if options.Verbose {
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
	ctxWithTimeout, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctxWithTimeout, "nmap", args...)
	output, err := cmd.CombinedOutput() // Use CombinedOutput to get both stdout and stderr
	if err != nil {
		if options.Verbose {
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

		fallbackCtx, fallbackCancel := context.WithTimeout(ctx, 90*time.Second)
		defer fallbackCancel()

		fallbackCmd := exec.CommandContext(fallbackCtx, "nmap", fallbackArgs...)
		fallbackOutput, fallbackErr := fallbackCmd.CombinedOutput()

		if fallbackErr != nil {
			if options.Verbose {
				log.Printf("TCP connect scan also failed for %s: %v", ip, fallbackErr)
				log.Printf("Fallback Nmap output: %s", string(fallbackOutput))
			}
			return []Service{}, fmt.Errorf("both SYN scan and TCP connect scan failed. SYN error: %v, TCP error: %v, TCP output: %s", err, fallbackErr, string(fallbackOutput))
		}

		if options.Verbose {
			log.Printf("TCP connect scan succeeded for %s", ip)
		}
		output = fallbackOutput
	}

	services := r.parseNmapOutput(string(output))

	if options.Verbose {
		log.Printf("Found %d open ports on %s", len(services), ip)
	}

	return services, nil
}

// parseNmapOutput parses Nmap output to extract services
func (r *ReconService) parseNmapOutput(output string) []Service {
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
