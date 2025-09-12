package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/spf13/cobra"
	lua "github.com/yuin/gopher-lua"
)

// Asset represents a discovered asset from recontool (mirrors recontool's Asset struct)
type Asset struct {
	ID         string      `json:"id"`
	Type       string      `json:"type"`
	Value      string      `json:"value"`
	IPs        []string    `json:"ips,omitempty"`
	ASN        string      `json:"asn,omitempty"`
	ASNOrg     string      `json:"asn_org,omitempty"`
	Subdomains []string    `json:"subdomains,omitempty"`
	Proxied    *bool       `json:"proxied,omitempty"`
	DNSRecords *DNSRecords `json:"dns_records,omitempty"`
	ServiceIDs []string    `json:"service_ids,omitempty"`

	// Service-specific fields
	Port     *int   `json:"port,omitempty"`
	Protocol string `json:"protocol,omitempty"`
	State    string `json:"state,omitempty"`
	Service  string `json:"service,omitempty"`
	Version  string `json:"version,omitempty"`
	SourceIP string `json:"source_ip,omitempty"`
}

// DNSRecords holds various DNS record types
type DNSRecords struct {
	A     []string `json:"a,omitempty"`
	AAAA  []string `json:"aaaa,omitempty"`
	CNAME []string `json:"cname,omitempty"`
	MX    []string `json:"mx,omitempty"`
	TXT   []string `json:"txt,omitempty"`
	NS    []string `json:"ns,omitempty"`
	SOA   []string `json:"soa,omitempty"`
	PTR   []string `json:"ptr,omitempty"`
}

// LuaScript represents a Lua script that can process assets
type LuaScript struct {
	Name    string
	Path    string
	Content string
	State   *lua.LState
}

// BackendConfig holds configuration for the backend
type BackendConfig struct {
	RecontoolPath string
	ScriptsDir    string
	Verbose       bool
	OutputFile    string
	Targets       []string
}

var config BackendConfig

func main() {
	var rootCmd = &cobra.Command{
		Use:   "backend [targets...]",
		Short: "Asset processing backend with Lua scripting",
		Long: `Backend system that retrieves assets from recontool in stream mode,
then processes each asset through Lua scripts with full asset data available.`,
		Args: cobra.MinimumNArgs(1),
		Run:  runBackend,
	}

	rootCmd.Flags().StringVar(&config.RecontoolPath, "recontool", "../recontool/regtech", "Path to recontool executable")
	rootCmd.Flags().StringVar(&config.ScriptsDir, "scripts", "./scripts", "Directory containing Lua scripts")
	rootCmd.Flags().BoolVarP(&config.Verbose, "verbose", "v", false, "Enable verbose output")
	rootCmd.Flags().StringVarP(&config.OutputFile, "output", "o", "", "Output file for results")

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

func runBackend(cmd *cobra.Command, args []string) {
	config.Targets = args

	if config.Verbose {
		log.Printf("Starting backend processing for targets: %v", config.Targets)
		log.Printf("Recontool path: %s", config.RecontoolPath)
		log.Printf("Scripts directory: %s", config.ScriptsDir)
	}

	// Create directories if they don't exist
	createDirectories()

	// Load Lua scripts
	luaScripts, err := loadLuaScripts()
	if err != nil {
		log.Printf("Warning: Error loading Lua scripts: %v", err)
	}

	if config.Verbose {
		log.Printf("Loaded %d Lua scripts", len(luaScripts))
	}

	// Get assets from recontool in stream mode
	assetChan := make(chan Asset, 100)
	var wg sync.WaitGroup

	// Start recontool in streaming mode
	wg.Add(1)
	go func() {
		defer wg.Done()
		defer close(assetChan)
		runRecontoolStreaming(assetChan)
	}()

	// Process assets as they come in
	wg.Add(1)
	go func() {
		defer wg.Done()
		processAssets(assetChan, luaScripts)
	}()

	wg.Wait()

	if config.Verbose {
		log.Println("Backend processing completed")
	}
}

func createDirectories() {
	dirs := []string{config.ScriptsDir}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			log.Printf("Warning: Could not create directory %s: %v", dir, err)
		}
	}
}

func runRecontoolStreaming(assetChan chan<- Asset) {
	if config.Verbose {
		log.Printf("Starting recontool in streaming mode with sudo")
	}

	// Build recontool command with streaming and scanning enabled
	args := []string{
		config.RecontoolPath,
		"--stream",
		"--scan",
		"--verbose",
	}
	args = append(args, config.Targets...)

	// Run with sudo for port scanning capabilities
	cmd := exec.Command("sudo", args...)

	// Set up pipes
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatalf("Error creating stdout pipe: %v", err)
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Fatalf("Error creating stderr pipe: %v", err)
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		log.Fatalf("Error starting recontool: %v", err)
	}

	// Read stderr in a separate goroutine for verbose output
	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			if config.Verbose {
				log.Printf("recontool: %s", scanner.Text())
			}
		}
	}()

	// Read and parse streaming JSON output
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		var asset Asset
		if err := json.Unmarshal([]byte(line), &asset); err != nil {
			if config.Verbose {
				log.Printf("Error parsing asset JSON: %v, line: %s", err, line)
			}
			continue
		}

		if config.Verbose {
			log.Printf("Received asset: %s (%s)", asset.Value, asset.Type)
		}

		assetChan <- asset
	}

	if err := scanner.Err(); err != nil {
		log.Printf("Error reading recontool output: %v", err)
	}

	// Wait for command to complete
	if err := cmd.Wait(); err != nil {
		log.Printf("Recontool command finished with error: %v", err)
	}
}

func loadLuaScripts() ([]*LuaScript, error) {
	var scripts []*LuaScript

	// Check if scripts directory exists
	if _, err := os.Stat(config.ScriptsDir); os.IsNotExist(err) {
		if config.Verbose {
			log.Printf("Scripts directory %s does not exist, skipping Lua scripts", config.ScriptsDir)
		}
		return scripts, nil
	}

	// Find all .lua files in scripts directory
	pattern := filepath.Join(config.ScriptsDir, "*.lua")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return nil, fmt.Errorf("error finding Lua script files: %v", err)
	}

	for _, scriptPath := range matches {
		if config.Verbose {
			log.Printf("Loading Lua script: %s", scriptPath)
		}

		// Read script content
		content, err := os.ReadFile(scriptPath)
		if err != nil {
			log.Printf("Error reading script %s: %v", scriptPath, err)
			continue
		}

		// Create new Lua state
		L := lua.NewState()

		// Register asset processing functions in Lua
		registerLuaFunctions(L)

		script := &LuaScript{
			Name:    filepath.Base(scriptPath),
			Path:    scriptPath,
			Content: string(content),
			State:   L,
		}

		scripts = append(scripts, script)
		if config.Verbose {
			log.Printf("Successfully loaded Lua script: %s", script.Name)
		}
	}

	return scripts, nil
}

func registerLuaFunctions(L *lua.LState) {
	// Register a log function for Lua scripts
	L.SetGlobal("log", L.NewFunction(func(L *lua.LState) int {
		msg := L.ToString(1)
		log.Printf("Lua: %s", msg)
		return 0
	}))

	// Register utility functions
	L.SetGlobal("sleep", L.NewFunction(func(L *lua.LState) int {
		seconds := L.ToNumber(1)
		time.Sleep(time.Duration(float64(seconds)) * time.Second)
		return 0
	}))
}

func processAssets(assetChan <-chan Asset, luaScripts []*LuaScript) {
	var processedCount int
	var outputFile *os.File
	var err error

	// Open output file if specified
	if config.OutputFile != "" {
		outputFile, err = os.Create(config.OutputFile)
		if err != nil {
			log.Printf("Error creating output file: %v", err)
			return
		}
		defer outputFile.Close()
	}

	for asset := range assetChan {
		processedCount++

		if config.Verbose {
			log.Printf("Processing asset %d: %s (%s)", processedCount, asset.Value, asset.Type)
		}

		// Process through Lua scripts
		for _, script := range luaScripts {
			if config.Verbose {
				log.Printf("Running Lua script %s on asset %s", script.Name, asset.Value)
			}

			err := processAssetWithLuaScript(asset, script)
			if err != nil {
				log.Printf("Error in Lua script %s processing asset %s: %v", script.Name, asset.Value, err)
			}
		}

		// Write processed asset to output file if specified
		if outputFile != nil {
			assetJSON, err := json.Marshal(asset)
			if err != nil {
				log.Printf("Error marshaling processed asset: %v", err)
			} else {
				outputFile.WriteString(string(assetJSON) + "\n")
			}
		}
	}

	if config.Verbose {
		log.Printf("Finished processing %d assets", processedCount)
	}
}

func processAssetWithLuaScript(asset Asset, script *LuaScript) error {
	L := script.State

	// Convert asset to comprehensive Lua table
	assetTable := L.NewTable()
	assetTable.RawSetString("id", lua.LString(asset.ID))
	assetTable.RawSetString("type", lua.LString(asset.Type))
	assetTable.RawSetString("value", lua.LString(asset.Value))

	// Add IPs array
	if len(asset.IPs) > 0 {
		ipsTable := L.NewTable()
		for i, ip := range asset.IPs {
			ipsTable.RawSetInt(i+1, lua.LString(ip))
		}
		assetTable.RawSetString("ips", ipsTable)
	}

	// Add ASN information
	if asset.ASN != "" {
		assetTable.RawSetString("asn", lua.LString(asset.ASN))
	}
	if asset.ASNOrg != "" {
		assetTable.RawSetString("asn_org", lua.LString(asset.ASNOrg))
	}

	// Add subdomains array
	if len(asset.Subdomains) > 0 {
		subdomainsTable := L.NewTable()
		for i, subdomain := range asset.Subdomains {
			subdomainsTable.RawSetInt(i+1, lua.LString(subdomain))
		}
		assetTable.RawSetString("subdomains", subdomainsTable)
	}

	// Add proxied status
	if asset.Proxied != nil {
		assetTable.RawSetString("proxied", lua.LBool(*asset.Proxied))
	}

	// Add DNS records
	if asset.DNSRecords != nil {
		dnsTable := L.NewTable()

		if len(asset.DNSRecords.A) > 0 {
			aTable := L.NewTable()
			for i, record := range asset.DNSRecords.A {
				aTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("a", aTable)
		}

		if len(asset.DNSRecords.AAAA) > 0 {
			aaaaTable := L.NewTable()
			for i, record := range asset.DNSRecords.AAAA {
				aaaaTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("aaaa", aaaaTable)
		}

		if len(asset.DNSRecords.CNAME) > 0 {
			cnameTable := L.NewTable()
			for i, record := range asset.DNSRecords.CNAME {
				cnameTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("cname", cnameTable)
		}

		if len(asset.DNSRecords.MX) > 0 {
			mxTable := L.NewTable()
			for i, record := range asset.DNSRecords.MX {
				mxTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("mx", mxTable)
		}

		if len(asset.DNSRecords.TXT) > 0 {
			txtTable := L.NewTable()
			for i, record := range asset.DNSRecords.TXT {
				txtTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("txt", txtTable)
		}

		if len(asset.DNSRecords.NS) > 0 {
			nsTable := L.NewTable()
			for i, record := range asset.DNSRecords.NS {
				nsTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("ns", nsTable)
		}

		assetTable.RawSetString("dns_records", dnsTable)
	}

	// Add service IDs
	if len(asset.ServiceIDs) > 0 {
		serviceIDsTable := L.NewTable()
		for i, serviceID := range asset.ServiceIDs {
			serviceIDsTable.RawSetInt(i+1, lua.LString(serviceID))
		}
		assetTable.RawSetString("service_ids", serviceIDsTable)
	}

	// Add service-specific fields
	if asset.Port != nil {
		assetTable.RawSetString("port", lua.LNumber(*asset.Port))
	}
	if asset.Protocol != "" {
		assetTable.RawSetString("protocol", lua.LString(asset.Protocol))
	}
	if asset.State != "" {
		assetTable.RawSetString("state", lua.LString(asset.State))
	}
	if asset.Service != "" {
		assetTable.RawSetString("service", lua.LString(asset.Service))
	}
	if asset.Version != "" {
		assetTable.RawSetString("version", lua.LString(asset.Version))
	}
	if asset.SourceIP != "" {
		assetTable.RawSetString("source_ip", lua.LString(asset.SourceIP))
	}

	// Set the global asset table
	L.SetGlobal("asset", assetTable)

	// Execute the script
	err := L.DoString(script.Content)
	if err != nil {
		return fmt.Errorf("error executing Lua script: %v", err)
	}

	return nil
}
