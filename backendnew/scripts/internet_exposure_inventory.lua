-- @title Internet Exposure Inventory (Article 11 Compliance)
-- @description Comprehensive inventory of internet-exposed services, open ports, and service banners in compliance with Moldovan Cybersecurity Law Article 11 (Security Measures)
-- @category Network Security
-- @compliance_article Article 11 - Security Measures  
-- @moldovan_law Law no. 142/2023
-- @author RegTech Scanner
-- @version 1.0
-- @asset_types service,domain,subdomain,ip
-- @requires_passed basic_info.lua

-- This script provides a comprehensive overview of internet exposure
log("Starting internet exposure inventory analysis")

-- Determine asset type and extract relevant information
local asset_host = nil
local asset_port = nil
local asset_protocol = nil

if asset.type == "service" then
    -- Extract host, port, and protocol from service value
    asset_host, asset_port, asset_protocol = string.match(asset.value, "([^:]+):(%d+)/(%w+)")
    if not asset_host or not asset_port or not asset_protocol then
        log("Could not parse service format: " .. asset.value)
        return
    end
    asset_port = tonumber(asset_port)
    
elseif asset.type == "domain" or asset.type == "subdomain" then
    asset_host = asset.value
    log("Analyzing exposure for domain: " .. asset_host)
    
elseif asset.type == "ip" then
    asset_host = asset.value
    log("Analyzing exposure for IP: " .. asset_host)
    
else
    log("Unsupported asset type for exposure inventory: " .. asset.type)
    return
end

-- Service categorization and risk assessment
local service_categories = {
    -- Critical services (require special attention)
    critical = {
        ports = {22, 3389, 23, 21, 135, 139, 445, 1433, 3306, 5432, 6379, 27017},
        names = {"SSH", "RDP", "Telnet", "FTP", "RPC", "NetBIOS", "SMB", "MSSQL", "MySQL", "PostgreSQL", "Redis", "MongoDB"},
        risk_level = "HIGH",
        description = "Administrative and database services - high risk if exposed"
    },
    
    -- Web services (common but need security)
    web = {
        ports = {80, 443, 8080, 8443, 8000, 8008, 3000, 5000, 9000},
        names = {"HTTP", "HTTPS", "HTTP-ALT", "HTTPS-ALT", "HTTP-DEV"},
        risk_level = "MEDIUM",
        description = "Web services - require proper security headers and configuration"
    },
    
    -- Mail services
    mail = {
        ports = {25, 587, 465, 110, 995, 143, 993, 2525},
        names = {"SMTP", "SMTP-SUB", "SMTPS", "POP3", "POP3S", "IMAP", "IMAPS"},
        risk_level = "MEDIUM", 
        description = "Email services - require authentication and encryption"
    },
    
    -- Network services
    network = {
        ports = {53, 123, 161, 162, 514, 69},
        names = {"DNS", "NTP", "SNMP", "SNMP-TRAP", "Syslog", "TFTP"},
        risk_level = "MEDIUM",
        description = "Network infrastructure services"
    },
    
    -- Development and monitoring
    development = {
        ports = {8081, 9090, 9091, 9200, 5601, 3000, 4000, 5000, 8888, 9999},
        names = {"Jenkins", "Prometheus", "Grafana", "Elasticsearch", "Kibana"},
        risk_level = "HIGH",
        description = "Development and monitoring tools - should not be publicly exposed"
    },
    
    -- Unknown/Other services
    unknown = {
        ports = {},
        names = {"Unknown"},
        risk_level = "MEDIUM",
        description = "Unidentified services - require investigation"
    }
}

-- Function to categorize a service by port
local function categorize_service(port)
    for category_name, category_data in pairs(service_categories) do
        if category_name ~= "unknown" then
            for _, cat_port in ipairs(category_data.ports) do
                if port == cat_port then
                    return category_name, category_data
                end
            end
        end
    end
    return "unknown", service_categories.unknown
end

-- Function to get service name by port
local function get_service_name(port, protocol)
    -- Common service names by port
    local service_names = {
        [21] = "FTP", [22] = "SSH", [23] = "Telnet", [25] = "SMTP",
        [53] = "DNS", [80] = "HTTP", [110] = "POP3", [135] = "RPC",
        [139] = "NetBIOS", [143] = "IMAP", [443] = "HTTPS", [445] = "SMB",
        [465] = "SMTPS", [587] = "SMTP", [993] = "IMAPS", [995] = "POP3S",
        [1433] = "MSSQL", [3306] = "MySQL", [3389] = "RDP", [5432] = "PostgreSQL",
        [6379] = "Redis", [8080] = "HTTP-ALT", [8443] = "HTTPS-ALT"
    }
    
    local base_name = service_names[port] or "Unknown"
    
    if protocol then
        return base_name .. "/" .. string.upper(protocol)
    else
        return base_name
    end
end

-- Function to assess exposure risk
local function assess_exposure_risk(port, category_data, banner_info)
    local risk_factors = {
        base_risk = 0,
        port_risk = 0,
        banner_risk = 0,
        total_risk = 0,
        risk_level = "LOW",
        risk_reasons = {}
    }
    
    -- Base risk from service category
    if category_data.risk_level == "HIGH" then
        risk_factors.base_risk = 3
    elseif category_data.risk_level == "MEDIUM" then
        risk_factors.base_risk = 2
    else
        risk_factors.base_risk = 1
    end
    
    -- Additional port-specific risk factors
    if port < 1024 then
        risk_factors.port_risk = risk_factors.port_risk + 1
        table.insert(risk_factors.risk_reasons, "Privileged port")
    end
    
    -- Critical administrative ports
    local critical_ports = {22, 3389, 23, 135, 139, 445}
    for _, critical_port in ipairs(critical_ports) do
        if port == critical_port then
            risk_factors.port_risk = risk_factors.port_risk + 2
            table.insert(risk_factors.risk_reasons, "Administrative service")
            break
        end
    end
    
    -- Database ports
    local db_ports = {1433, 3306, 5432, 6379, 27017}
    for _, db_port in ipairs(db_ports) do
        if port == db_port then
            risk_factors.port_risk = risk_factors.port_risk + 2
            table.insert(risk_factors.risk_reasons, "Database service")
            break
        end
    end
    
    -- Banner-based risk assessment
    if banner_info and banner_info ~= "" then
        local banner_lower = string.lower(banner_info)
        
        -- Look for version information (can indicate outdated software)
        if string.match(banner_lower, "%d+%.%d+") then
            table.insert(risk_factors.risk_reasons, "Version disclosed in banner")
            risk_factors.banner_risk = risk_factors.banner_risk + 0.5
        end
        
        -- Look for concerning service indicators
        local risky_indicators = {
            "default", "admin", "root", "test", "demo", "debug", 
            "old", "legacy", "backup", "temp"
        }
        
        for _, indicator in ipairs(risky_indicators) do
            if string.match(banner_lower, indicator) then
                table.insert(risk_factors.risk_reasons, "Concerning banner: " .. indicator)
                risk_factors.banner_risk = risk_factors.banner_risk + 1
                break
            end
        end
    else
        -- No banner might indicate basic security (banner hiding) or failed detection
        table.insert(risk_factors.risk_reasons, "No banner information")
        risk_factors.banner_risk = 0.5
    end
    
    -- Calculate total risk
    risk_factors.total_risk = risk_factors.base_risk + risk_factors.port_risk + risk_factors.banner_risk
    
    -- Determine risk level
    if risk_factors.total_risk >= 4 then
        risk_factors.risk_level = "CRITICAL"
    elseif risk_factors.total_risk >= 3 then
        risk_factors.risk_level = "HIGH"
    elseif risk_factors.total_risk >= 2 then
        risk_factors.risk_level = "MEDIUM"
    else
        risk_factors.risk_level = "LOW"
    end
    
    return risk_factors
end

-- Main inventory analysis function
local function analyze_internet_exposure()
    local inventory = {
        asset_type = asset.type,
        asset_value = asset.value,
        host = asset_host,
        port = asset_port,
        protocol = asset_protocol,
        service_info = {},
        exposure_summary = {
            total_services = 0,
            critical_risk_count = 0,
            high_risk_count = 0,
            medium_risk_count = 0,
            low_risk_count = 0,
            categories = {},
            total_risk_score = 0,
            compliance_issues = {}
        },
        recommendations = {}
    }
    
    if asset.type == "service" then
        -- Analyze single service
        local service_name = get_service_name(asset_port, asset_protocol)
        local category, category_data = categorize_service(asset_port)
        
        -- Banner information not available from scanner - using service detection
        local banner_info = ""
        
        -- Assess risk
        local risk_assessment = assess_exposure_risk(asset_port, category_data, banner_info)
        
        local service_info = {
            port = asset_port,
            protocol = asset_protocol,
            service_name = service_name,
            category = category,
            banner = banner_info,
            risk_level = risk_assessment.risk_level,
            risk_score = risk_assessment.total_risk,
            risk_reasons = risk_assessment.risk_reasons,
            category_description = category_data.description
        }
        
        inventory.service_info[asset_port] = service_info
        inventory.exposure_summary.total_services = 1
        
        -- Count by risk level
        if risk_assessment.risk_level == "CRITICAL" then
            inventory.exposure_summary.critical_risk_count = 1
        elseif risk_assessment.risk_level == "HIGH" then
            inventory.exposure_summary.high_risk_count = 1
        elseif risk_assessment.risk_level == "MEDIUM" then
            inventory.exposure_summary.medium_risk_count = 1
        else
            inventory.exposure_summary.low_risk_count = 1
        end
        
        inventory.exposure_summary.total_risk_score = risk_assessment.total_risk
        inventory.exposure_summary.categories[category] = (inventory.exposure_summary.categories[category] or 0) + 1
        
        -- Generate compliance issues
        if risk_assessment.risk_level == "CRITICAL" or risk_assessment.risk_level == "HIGH" then
            table.insert(inventory.exposure_summary.compliance_issues, 
                "High-risk service exposed: " .. service_name .. " on port " .. asset_port)
        end
        
        for _, reason in ipairs(risk_assessment.risk_reasons) do
            if reason ~= "No banner information" then
                table.insert(inventory.exposure_summary.compliance_issues, 
                    "Port " .. asset_port .. ": " .. reason)
            end
        end
        
        log("Analyzed service: " .. service_name .. " (Risk: " .. risk_assessment.risk_level .. ")")
        
    else
        -- For domain/IP assets, we analyze based on related service discoveries
        -- This is a simplified approach - in practice you'd aggregate multiple services
        log("Domain/IP asset analysis - checking for service metadata")
        
        -- Use direct service detection since get_metadata is not available
        inventory.exposure_summary.total_services = 0
        
        -- We'll count services based on exposure detection above
        for category, services in pairs(inventory.services_by_category) do
            inventory.exposure_summary.total_services = inventory.exposure_summary.total_services + #services
        end
        
        if inventory.exposure_summary.total_services == 0 then
            table.insert(inventory.exposure_summary.compliance_issues, 
                "No service inventory available - comprehensive scanning required")
        end
        
        log("Found " .. inventory.exposure_summary.total_services .. " exposed services")
    end
    
    return inventory
end

-- Perform exposure analysis
local exposure_results = analyze_internet_exposure()

-- Set comprehensive metadata
set_metadata("exposure.asset_type", exposure_results.asset_type)
set_metadata("exposure.asset_value", exposure_results.asset_value)
set_metadata("exposure.host", exposure_results.host or "")

if exposure_results.port then
    set_metadata("exposure.port", exposure_results.port)
    set_metadata("exposure.protocol", exposure_results.protocol or "")
end

-- Service inventory metadata
set_metadata("exposure.total_services", exposure_results.exposure_summary.total_services)
set_metadata("exposure.critical_risk_count", exposure_results.exposure_summary.critical_risk_count)
set_metadata("exposure.high_risk_count", exposure_results.exposure_summary.high_risk_count) 
set_metadata("exposure.medium_risk_count", exposure_results.exposure_summary.medium_risk_count)
set_metadata("exposure.low_risk_count", exposure_results.exposure_summary.low_risk_count)
set_metadata("exposure.total_risk_score", exposure_results.exposure_summary.total_risk_score)

-- Individual service metadata (for service assets)
for port, service_info in pairs(exposure_results.service_info) do
    set_metadata("exposure.service_" .. port .. ".name", service_info.service_name)
    set_metadata("exposure.service_" .. port .. ".category", service_info.category)
    set_metadata("exposure.service_" .. port .. ".risk_level", service_info.risk_level)
    set_metadata("exposure.service_" .. port .. ".risk_score", service_info.risk_score)
    set_metadata("exposure.service_" .. port .. ".banner", service_info.banner or "")
    
    if #service_info.risk_reasons > 0 then
        set_metadata("exposure.service_" .. port .. ".risk_reasons", 
            table.concat(service_info.risk_reasons, "; "))
    end
end

-- Category distribution
local category_summary = {}
for category, count in pairs(exposure_results.exposure_summary.categories) do
    table.insert(category_summary, category .. ":" .. count)
end
if #category_summary > 0 then
    set_metadata("exposure.categories", table.concat(category_summary, ", "))
end

-- Compliance issues
if #exposure_results.exposure_summary.compliance_issues > 0 then
    set_metadata("exposure.compliance_issues", 
        table.concat(exposure_results.exposure_summary.compliance_issues, "; "))
end

log("Exposure inventory: " .. exposure_results.exposure_summary.total_services .. " services analyzed")
log("Risk distribution - Critical: " .. exposure_results.exposure_summary.critical_risk_count .. 
    ", High: " .. exposure_results.exposure_summary.high_risk_count ..
    ", Medium: " .. exposure_results.exposure_summary.medium_risk_count ..
    ", Low: " .. exposure_results.exposure_summary.low_risk_count)

-- Determine compliance status for Moldovan Cybersecurity Law Article 11
local compliance_level = "excellent"
local compliance_status = "pass"

-- Evaluate based on exposure risk profile
if exposure_results.exposure_summary.critical_risk_count > 0 then
    compliance_level = "critical_exposure"
    compliance_status = "fail"
    log("Critical exposure detected - immediate remediation required")
    
elseif exposure_results.exposure_summary.high_risk_count > 2 then
    compliance_level = "high_exposure"
    compliance_status = "fail"
    log("Multiple high-risk services exposed")
    
elseif exposure_results.exposure_summary.high_risk_count > 0 then
    compliance_level = "moderate_exposure" 
    compliance_status = "conditional"
    log("High-risk services detected - review security measures")
    
elseif exposure_results.exposure_summary.medium_risk_count > 5 then
    compliance_level = "elevated_exposure"
    compliance_status = "conditional"
    log("Multiple medium-risk services - monitor and harden")
    
elseif exposure_results.exposure_summary.total_services > 10 then
    compliance_level = "broad_exposure"
    compliance_status = "conditional"
    log("Large service footprint - ensure proper security measures")
    
elseif exposure_results.exposure_summary.total_services > 0 then
    compliance_level = "controlled_exposure"
    compliance_status = "pass"
    log("Reasonable service exposure with acceptable risk levels")
    
else
    compliance_level = "minimal_exposure"
    compliance_status = "pass"
    log("Minimal or no internet exposure detected")
end

set_metadata("exposure.compliance_level", compliance_level)
set_metadata("exposure.compliance_status", compliance_status)

-- Generate recommendations based on findings
local recommendations = {}

if exposure_results.exposure_summary.critical_risk_count > 0 then
    table.insert(recommendations, "Immediately review and restrict access to critical services")
end

if exposure_results.exposure_summary.high_risk_count > 0 then
    table.insert(recommendations, "Implement strong authentication for administrative services")
end

-- Category-specific recommendations
for category, count in pairs(exposure_results.exposure_summary.categories) do
    if category == "critical" then
        table.insert(recommendations, "Consider VPN or firewall restrictions for administrative services")
    elseif category == "development" then
        table.insert(recommendations, "Remove development tools from public internet exposure")
    elseif category == "web" then
        table.insert(recommendations, "Ensure web services have proper security headers and authentication")
    end
end

-- General recommendations
if exposure_results.exposure_summary.total_services > 5 then
    table.insert(recommendations, "Conduct regular service inventory and disable unnecessary services")
end

table.insert(recommendations, "Implement network monitoring and intrusion detection systems")
table.insert(recommendations, "Regular security assessments and penetration testing")

if #recommendations > 0 then
    set_metadata("exposure.recommendations", table.concat(recommendations, "; "))
end

-- Update compliance checklists based on results
if compliance_status == "pass" then
    local pass_message = "Internet exposure properly controlled"
    if exposure_results.exposure_summary.total_services > 0 then
        pass_message = pass_message .. " (" .. exposure_results.exposure_summary.total_services .. " services monitored)"
    end
    
    pass_checklist("network-exposure-inventory-023", pass_message)
    pass_checklist("service-hardening-024", "Service exposure acceptable")
    pass_checklist("development-environment-exposure-024", "No development environments exposed to internet")
    
    log("Exposure compliance: PASS - " .. compliance_level)
    pass()
    
elseif compliance_status == "conditional" then
    local conditional_message = "Internet exposure requires attention"
    if exposure_results.exposure_summary.high_risk_count > 0 or exposure_results.exposure_summary.medium_risk_count > 0 then
        conditional_message = conditional_message .. " (High: " .. exposure_results.exposure_summary.high_risk_count .. 
            ", Medium: " .. exposure_results.exposure_summary.medium_risk_count .. ")"
    end
    if #exposure_results.exposure_summary.compliance_issues > 0 then
        conditional_message = conditional_message .. ": " .. table.concat(exposure_results.exposure_summary.compliance_issues, "; ")
    end
    
    pass_checklist("network-exposure-inventory-023", conditional_message)
    fail_checklist("service-hardening-024", "Service exposure needs hardening")
    
    -- Check for development environment exposure specifically
    if exposure_results.exposure_summary.categories.development and exposure_results.exposure_summary.categories.development > 0 then
        fail_checklist("development-environment-exposure-024", "Development environments detected in public exposure")
    else
        pass_checklist("development-environment-exposure-024", "No development environments exposed")
    end
    
    log("Exposure compliance: CONDITIONAL - " .. conditional_message)
    pass()
    
else
    local fail_message = "Critical internet exposure detected"
    if exposure_results.exposure_summary.critical_risk_count > 0 then
        fail_message = fail_message .. " (" .. exposure_results.exposure_summary.critical_risk_count .. " critical services)"
    end
    if #exposure_results.exposure_summary.compliance_issues > 0 then
        fail_message = fail_message .. ": " .. table.concat(exposure_results.exposure_summary.compliance_issues, "; ")
    end
    
    fail_checklist("network-exposure-inventory-023", fail_message)
    fail_checklist("service-hardening-024", "Critical service exposure")
    
    -- Check for development environment exposure specifically  
    if exposure_results.exposure_summary.categories.development and exposure_results.exposure_summary.categories.development > 0 then
        fail_checklist("development-environment-exposure-024", "CRITICAL: Development environments exposed to internet")
    else
        pass_checklist("development-environment-exposure-024", "No development environments exposed")
    end
    
    log("Exposure compliance: FAIL - " .. fail_message)
    reject("Critical internet exposure")
end

-- Add descriptive tags based on exposure profile
if compliance_level == "minimal_exposure" then
    add_tag("minimal-exposure")
elseif compliance_level == "controlled_exposure" then
    add_tag("controlled-exposure")
elseif compliance_level == "broad_exposure" then
    add_tag("broad-exposure")
elseif compliance_level == "elevated_exposure" then
    add_tag("elevated-exposure")
elseif compliance_level == "moderate_exposure" then
    add_tag("moderate-exposure")
elseif compliance_level == "high_exposure" then
    add_tag("high-exposure")
elseif compliance_level == "critical_exposure" then
    add_tag("critical-exposure")
end

-- Add service category tags
for category, count in pairs(exposure_results.exposure_summary.categories) do
    add_tag("has-" .. category .. "-services")
end

-- Add risk level tags
if exposure_results.exposure_summary.critical_risk_count > 0 then
    add_tag("critical-risk-services")
end
if exposure_results.exposure_summary.high_risk_count > 0 then
    add_tag("high-risk-services")
end

-- Add specific service tags (for service assets)
for port, service_info in pairs(exposure_results.service_info) do
    add_tag("port-" .. port)
    add_tag(string.lower(service_info.service_name:gsub("[^%w]", "-")))
    add_tag(service_info.risk_level:lower() .. "-risk")
end

if exposure_results.exposure_summary.total_services == 0 then
    add_tag("no-services-detected")
elseif exposure_results.exposure_summary.total_services == 1 then
    add_tag("single-service")
else
    add_tag("multiple-services")
end

log("Internet exposure inventory completed for: " .. asset.value)