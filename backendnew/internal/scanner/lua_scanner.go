package scanner

import (
	"assetscanner/internal/config"
	"assetscanner/internal/model"
	"assetscanner/internal/util"
	"context"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
	"sync"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// LuaScanner handles Lua script execution for asset scanning
type LuaScanner struct {
	config     *config.ScannerConfig
	scripts    map[string]*model.Script
	scriptsMu  sync.RWMutex
	workerPool chan struct{}
	results    chan *model.ScanResult
	ctx        context.Context
	cancel     context.CancelFunc
}

// NewLuaScanner creates a new Lua scanner
func NewLuaScanner(cfg *config.ScannerConfig) (*LuaScanner, error) {
	ctx, cancel := context.WithCancel(context.Background())

	scanner := &LuaScanner{
		config:     cfg,
		scripts:    make(map[string]*model.Script),
		workerPool: make(chan struct{}, cfg.WorkerPoolSize),
		results:    make(chan *model.ScanResult, cfg.MaxConcurrent*10), // Buffer for results
		ctx:        ctx,
		cancel:     cancel,
	}

	// Initialize worker pool
	for i := 0; i < cfg.WorkerPoolSize; i++ {
		scanner.workerPool <- struct{}{}
	}

	// Load scripts from directory
	if err := scanner.loadScripts(); err != nil {
		return nil, fmt.Errorf("failed to load scripts: %w", err)
	}

	return scanner, nil
}

// LoadScripts loads all Lua scripts from the scripts directory
func (s *LuaScanner) loadScripts() error {
	s.scriptsMu.Lock()
	defer s.scriptsMu.Unlock()

	// Find all .lua files in scripts directory
	pattern := filepath.Join(s.config.ScriptsDir, "*.lua")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return fmt.Errorf("error finding script files: %w", err)
	}

	for _, scriptPath := range matches {
		script, err := s.loadScript(scriptPath)
		if err != nil {
			logMessage(fmt.Sprintf("Warning: Failed to load script %s: %v", scriptPath, err))
			continue
		}

		s.scripts[script.Name] = script
		logMessage(fmt.Sprintf("Loaded Lua script: %s", script.Name))
	}

	return nil
}

// loadScript loads a single Lua script from file
func (s *LuaScanner) loadScript(scriptPath string) (*model.Script, error) {
	content, err := ioutil.ReadFile(scriptPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read script file: %w", err)
	}

	script := &model.Script{
		Name:    filepath.Base(scriptPath),
		Path:    scriptPath,
		Content: string(content),
	}

	// Parse script metadata from comments
	s.parseScriptMetadata(script)

	return script, nil
}

// parseScriptMetadata extracts metadata from script comments
func (s *LuaScanner) parseScriptMetadata(script *model.Script) {
	lines := strings.Split(script.Content, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "--") {
			continue
		}

		comment := strings.TrimPrefix(line, "--")
		comment = strings.TrimSpace(comment)

		if strings.HasPrefix(comment, "@title ") {
			script.Title = strings.TrimPrefix(comment, "@title ")
		} else if strings.HasPrefix(comment, "@description ") {
			script.Description = strings.TrimPrefix(comment, "@description ")
		} else if strings.HasPrefix(comment, "@category ") {
			script.Category = strings.TrimPrefix(comment, "@category ")
		} else if strings.HasPrefix(comment, "@author ") {
			script.Author = strings.TrimPrefix(comment, "@author ")
		} else if strings.HasPrefix(comment, "@version ") {
			script.Version = strings.TrimPrefix(comment, "@version ")
		} else if strings.HasPrefix(comment, "@asset_types ") {
			typesStr := strings.TrimPrefix(comment, "@asset_types ")
			script.AssetTypes = strings.Split(typesStr, ",")
			// Trim spaces
			for i, t := range script.AssetTypes {
				script.AssetTypes[i] = strings.TrimSpace(t)
			}
		} else if strings.HasPrefix(comment, "@requires_passed ") {
			reqStr := strings.TrimPrefix(comment, "@requires_passed ")
			parts := strings.Split(reqStr, ",")
			var reqs []string
			for _, p := range parts {
				p = strings.TrimSpace(p)
				if p != "" {
					reqs = append(reqs, p)
				}
			}
			script.RequiresPassed = reqs
		}
	}
}

// ScanAsset runs specified scripts on an asset
func (s *LuaScanner) ScanAsset(ctx context.Context, asset *model.Asset, scriptNames []string) ([]*model.ScanResult, error) {
	if len(scriptNames) == 0 {
		// Run all applicable scripts
		scriptNames = s.getApplicableScripts(asset.Type)
	}
	fmt.Println("scriptNames", scriptNames)

	var results []*model.ScanResult
	executed := make(map[string]bool)
	passed := make(map[string]bool)

	// Build map of candidate scripts
	candidates := make(map[string]*model.Script)
	for _, name := range scriptNames {
		if sc, ok := s.getScript(name); ok {
			candidates[name] = sc
		}
	}

	for {
		// Collect runnable scripts in this phase
		phase := make([]*model.Script, 0)
		for name, sc := range candidates {
			if executed[name] {
				continue
			}
			// Check dependency gating
			depsOK := true
			for _, req := range sc.RequiresPassed {
				if !passed[req] {
					depsOK = false
					break
				}
			}
			if depsOK {
				phase = append(phase, sc)
			}
		}

		if len(phase) == 0 {
			break
		}

		var wg sync.WaitGroup
		var mu sync.Mutex
		phaseResults := make([]*model.ScanResult, 0, len(phase))

		for _, sc := range phase {
			sc := sc
			wg.Add(1)
			go func() {
				defer wg.Done()
				// Acquire worker from pool
				<-s.workerPool
				defer func() { s.workerPool <- struct{}{} }()

				fmt.Println("executing script", sc.Name)
				r := s.executeScript(ctx, asset, sc)
				mu.Lock()
				phaseResults = append(phaseResults, r)
				executed[sc.Name] = true
				if r.Decision == "pass" {
					passed[sc.Name] = true
				}
				mu.Unlock()
			}()
		}

		wg.Wait()
		results = append(results, phaseResults...)
	}

	return results, nil
}

// executeScript executes a single Lua script on an asset
func (s *LuaScanner) executeScript(ctx context.Context, asset *model.Asset, script *model.Script) *model.ScanResult {
	startTime := time.Now()

	result := &model.ScanResult{
		ID:         util.GenerateID(),
		AssetID:    asset.ID,
		ScriptName: script.Name,
		ExecutedAt: startTime,
		Output:     make([]string, 0),
		Metadata:   make(map[string]interface{}),
	}

	// Create timeout context
	scriptCtx, cancel := context.WithTimeout(ctx, s.config.DefaultTimeout)
	defer cancel()

	// Execute script in goroutine to handle timeout
	done := make(chan struct{})
	go func() {
		defer close(done)
		defer func() {
			if r := recover(); r != nil {
				result.Success = false
				result.Error = fmt.Sprintf("Script panic: %v", r)
			}
		}()

		if err := s.runLuaScript(asset, script, result); err != nil {
			result.Success = false
			result.Error = err.Error()
		} else {
			result.Success = true
		}
	}()

	// Wait for completion or timeout
	select {
	case <-done:
		// Script completed
	case <-scriptCtx.Done():
		result.Success = false
		result.Error = "Script execution timeout"
	}

	if result.Decision == "" {
		result.Decision = "na"
	}
	result.Duration = time.Since(startTime)
	return result
}

// runLuaScript executes the Lua script
func (s *LuaScanner) runLuaScript(asset *model.Asset, script *model.Script, result *model.ScanResult) error {
	L := lua.NewState()
	defer L.Close()

	// Register built-in functions
	s.registerLuaFunctions(L, asset, result)

	// Register tcp helper library
	registerLuaNet(L)

	// Register http helper library
	registerLuaHTTP(L)

	// Set asset data as global
	s.setAssetGlobal(L, asset)

	// Execute the script
	if err := L.DoString(script.Content); err != nil {
		return fmt.Errorf("Lua execution error: %w", err)
	}

	return nil
}

// registerLuaFunctions registers built-in functions for Lua scripts
func (s *LuaScanner) registerLuaFunctions(L *lua.LState, asset *model.Asset, result *model.ScanResult) {
	// Log function
	L.SetGlobal("log", L.NewFunction(func(L *lua.LState) int {
		msg := L.ToString(1)
		result.Output = append(result.Output, msg)
		fmt.Println(msg)
		return 0
	}))

	// Sleep function
	L.SetGlobal("sleep", L.NewFunction(func(L *lua.LState) int {
		seconds := L.ToNumber(1)
		time.Sleep(time.Duration(float64(seconds)) * time.Second)
		return 0
	}))

	// Set metadata function
	L.SetGlobal("set_metadata", L.NewFunction(func(L *lua.LState) int {
		key := L.ToString(1)
		value := L.Get(2)

		var goVal interface{}
		switch v := value.(type) {
		case lua.LString:
			goVal = string(v)
		case lua.LNumber:
			goVal = float64(v)
		case lua.LBool:
			goVal = bool(v)
		default:
			goVal = value.String()
		}

		// Store
		result.Metadata[key] = goVal

		// Log
		logMessage(fmt.Sprintf("metadata set: key=%q value=%v asset=%s script=%s",
			key, goVal, result.AssetID, result.ScriptName))

		return 0
	}))

	// Add tag function
	L.SetGlobal("add_tag", L.NewFunction(func(L *lua.LState) int {
		tag := L.ToString(1)
		if tag == "" {
			return 0
		}

		// Check if tag already exists
		for _, existingTag := range asset.Tags {
			if existingTag == tag {
				return 0 // Tag already exists, don't add duplicate
			}
		}

		// Add the tag
		asset.Tags = append(asset.Tags, tag)

		// Log
		logMessage(fmt.Sprintf("tag added: %q asset=%s script=%s",
			tag, result.AssetID, result.ScriptName))

		return 0
	}))

	// HTTP request function (basic implementation)
	L.SetGlobal("http_get", L.NewFunction(func(L *lua.LState) int {
		url := L.ToString(1)
		// This is a placeholder - in a real implementation, you'd make an HTTP request
		logMessage(fmt.Sprintf("HTTP GET request to: %s", url))
		L.Push(lua.LString("HTTP response placeholder"))
		return 1
	}))

	// pass() marks audit decision as pass
	L.SetGlobal("pass", L.NewFunction(func(L *lua.LState) int {
		result.Decision = "pass"
		return 0
	}))

	// reject(reason?) marks audit decision as reject and can set error/metadata
	L.SetGlobal("reject", L.NewFunction(func(L *lua.LState) int {
		result.Decision = "reject"
		if L.GetTop() >= 1 {
			reason := L.ToString(1)
			result.Metadata["reject_reason"] = reason
		}
		return 0
	}))

	// Checklist control functions
	L.SetGlobal("pass_checklist", L.NewFunction(func(L *lua.LState) int {
		checklistID := L.ToString(1)
		reason := L.OptString(2, "")

		if checklistID == "" {
			result.Output = append(result.Output, "Error: pass_checklist requires checklist ID")
			return 0
		}

		// Store checklist result in metadata
		if result.Metadata["checklist_results"] == nil {
			result.Metadata["checklist_results"] = make(map[string]interface{})
		}

		checklistResults := result.Metadata["checklist_results"].(map[string]interface{})
		checklistResults[checklistID] = map[string]interface{}{
			"status": "yes",
			"reason": reason,
		}

		result.Output = append(result.Output, fmt.Sprintf("Passed checklist: %s", checklistID))
		if reason != "" {
			result.Output = append(result.Output, fmt.Sprintf("Reason: %s", reason))
		}

		return 0
	}))

	L.SetGlobal("fail_checklist", L.NewFunction(func(L *lua.LState) int {
		checklistID := L.ToString(1)
		reason := L.OptString(2, "")

		if checklistID == "" {
			result.Output = append(result.Output, "Error: fail_checklist requires checklist ID")
			return 0
		}

		// Store checklist result in metadata
		if result.Metadata["checklist_results"] == nil {
			result.Metadata["checklist_results"] = make(map[string]interface{})
		}

		checklistResults := result.Metadata["checklist_results"].(map[string]interface{})
		checklistResults[checklistID] = map[string]interface{}{
			"status": "no",
			"reason": reason,
		}

		result.Output = append(result.Output, fmt.Sprintf("Failed checklist: %s", checklistID))
		if reason != "" {
			result.Output = append(result.Output, fmt.Sprintf("Reason: %s", reason))
		}

		return 0
	}))

	L.SetGlobal("na_checklist", L.NewFunction(func(L *lua.LState) int {
		checklistID := L.ToString(1)
		reason := L.OptString(2, "")

		if checklistID == "" {
			result.Output = append(result.Output, "Error: na_checklist requires checklist ID")
			return 0
		}

		// Store checklist result in metadata
		if result.Metadata["checklist_results"] == nil {
			result.Metadata["checklist_results"] = make(map[string]interface{})
		}

		checklistResults := result.Metadata["checklist_results"].(map[string]interface{})
		checklistResults[checklistID] = map[string]interface{}{
			"status": "na",
			"reason": reason,
		}

		result.Output = append(result.Output, fmt.Sprintf("N/A checklist: %s", checklistID))
		if reason != "" {
			result.Output = append(result.Output, fmt.Sprintf("Reason: %s", reason))
		}

		return 0
	}))
}

// setAssetGlobal sets the asset data as a global table in Lua
func (s *LuaScanner) setAssetGlobal(L *lua.LState, asset *model.Asset) {
	assetTable := L.NewTable()
	assetTable.RawSetString("id", lua.LString(asset.ID))
	assetTable.RawSetString("type", lua.LString(asset.Type))
	assetTable.RawSetString("value", lua.LString(asset.Value))
	assetTable.RawSetString("status", lua.LString(asset.Status))
	assetTable.RawSetString("scan_count", lua.LNumber(asset.ScanCount))

	// Add properties
	if len(asset.Properties) > 0 {
		propsTable := L.NewTable()
		for key, value := range asset.Properties {
			switch v := value.(type) {
			case string:
				propsTable.RawSetString(key, lua.LString(v))
			case float64:
				propsTable.RawSetString(key, lua.LNumber(v))
			case bool:
				propsTable.RawSetString(key, lua.LBool(v))
			default:
				propsTable.RawSetString(key, lua.LString(fmt.Sprintf("%v", v)))
			}
		}
		assetTable.RawSetString("properties", propsTable)
	}

	// Add DNS records
	if asset.DNSRecords != nil {
		dnsTable := L.NewTable()

		// Add A records
		if len(asset.DNSRecords.A) > 0 {
			aTable := L.NewTable()
			for i, record := range asset.DNSRecords.A {
				aTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("a", aTable)
		}

		// Add AAAA records
		if len(asset.DNSRecords.AAAA) > 0 {
			aaaaTable := L.NewTable()
			for i, record := range asset.DNSRecords.AAAA {
				aaaaTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("aaaa", aaaaTable)
		}

		// Add CNAME records
		if len(asset.DNSRecords.CNAME) > 0 {
			cnameTable := L.NewTable()
			for i, record := range asset.DNSRecords.CNAME {
				cnameTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("cname", cnameTable)
		}

		// Add MX records
		if len(asset.DNSRecords.MX) > 0 {
			mxTable := L.NewTable()
			for i, record := range asset.DNSRecords.MX {
				mxTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("mx", mxTable)
		}

		// Add TXT records
		if len(asset.DNSRecords.TXT) > 0 {
			txtTable := L.NewTable()
			for i, record := range asset.DNSRecords.TXT {
				txtTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("txt", txtTable)
		}

		// Add NS records
		if len(asset.DNSRecords.NS) > 0 {
			nsTable := L.NewTable()
			for i, record := range asset.DNSRecords.NS {
				nsTable.RawSetInt(i+1, lua.LString(record))
			}
			dnsTable.RawSetString("ns", nsTable)
		}

		assetTable.RawSetString("dns_records", dnsTable)
	}

	// Add tags
	if len(asset.Tags) > 0 {
		tagsTable := L.NewTable()
		for i, tag := range asset.Tags {
			tagsTable.RawSetInt(i+1, lua.LString(tag))
		}
		assetTable.RawSetString("tags", tagsTable)
	}

	L.SetGlobal("asset", assetTable)
}

// GetScript returns a script by name
func (s *LuaScanner) getScript(name string) (*model.Script, bool) {
	s.scriptsMu.RLock()
	defer s.scriptsMu.RUnlock()

	script, exists := s.scripts[name]
	return script, exists
}

// getApplicableScripts returns scripts that can process the given asset type
func (s *LuaScanner) getApplicableScripts(assetType string) []string {
	s.scriptsMu.RLock()
	defer s.scriptsMu.RUnlock()

	var applicable []string
	for name, script := range s.scripts {
		if len(script.AssetTypes) == 0 {
			// No type restrictions, can process any asset
			applicable = append(applicable, name)
		} else {
			// Check if asset type is supported
			for _, supportedType := range script.AssetTypes {
				if supportedType == assetType {
					applicable = append(applicable, name)
					break
				}
			}
		}
	}

	return applicable
}

// ListScripts returns all loaded scripts
func (s *LuaScanner) ListScripts() []*model.Script {
	s.scriptsMu.RLock()
	defer s.scriptsMu.RUnlock()

	var scripts []*model.Script
	for _, script := range s.scripts {
		scripts = append(scripts, script)
	}

	return scripts
}

// ReloadScripts reloads all scripts from disk
func (s *LuaScanner) ReloadScripts() error {
	return s.loadScripts()
}

// Close shuts down the scanner
func (s *LuaScanner) Close() error {
	s.cancel()
	close(s.results)
	return nil
}

func logMessage(msg string) {
	fmt.Printf("[LuaScanner] %s\n", msg)
}
