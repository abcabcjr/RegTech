-- @title OSS Bucket Detection
-- @description Detect Object Storage Service (OSS) buckets from various cloud providers
-- @category cloud_security
-- @author RegTech Security Team
-- @version 1.0
-- @asset_types domain,subdomain,service
-- @requires_passed basic_info.lua

log("Starting OSS bucket detection for: " .. asset.value)

-- OSS bucket patterns for different cloud providers
local oss_patterns = {
    -- Amazon S3
    s3 = {
        patterns = {
            "%.s3%.amazonaws%.com$",
            "%.s3%..*%.amazonaws%.com$",
            "%.s3%-website%..*%.amazonaws%.com$",
            "%.s3%-website%-.*%.amazonaws%.com$",
            "s3://",
            "s3%-.*%.amazonaws%.com$"
        },
        provider = "Amazon S3",
        service_type = "s3"
    },
    
    -- Google Cloud Storage
    gcs = {
        patterns = {
            "%.storage%.googleapis%.com$",
            "%.googleusercontent%.com$",
            "storage%.cloud%.google%.com",
            "gs://",
            "%.appspot%.com$"
        },
        provider = "Google Cloud Storage",
        service_type = "gcs"
    },
    
    -- Microsoft Azure Blob Storage
    azure = {
        patterns = {
            "%.blob%.core%.windows%.net$",
            "%.file%.core%.windows%.net$",
            "%.queue%.core%.windows%.net$",
            "%.table%.core%.windows%.net$",
            "%.azurewebsites%.net$"
        },
        provider = "Microsoft Azure",
        service_type = "azure_blob"
    },
    
    -- Alibaba Cloud OSS
    aliyun = {
        patterns = {
            "%.oss%-.*%.aliyuncs%.com$",
            "%.oss%.aliyuncs%.com$",
            "oss://",
            "%.aliyuncs%.com$"
        },
        provider = "Alibaba Cloud OSS",
        service_type = "aliyun_oss"
    },
    
    -- Tencent Cloud COS
    tencent = {
        patterns = {
            "%.cos%..*%.myqcloud%.com$",
            "%.file%.myqcloud%.com$",
            "cos://",
            "%.myqcloud%.com$"
        },
        provider = "Tencent Cloud COS",
        service_type = "tencent_cos"
    },
    
    -- Huawei Cloud OBS
    huawei = {
        patterns = {
            "%.obs%..*%.myhuaweicloud%.com$",
            "obs://",
            "%.myhuaweicloud%.com$"
        },
        provider = "Huawei Cloud OBS",
        service_type = "huawei_obs"
    },
    
    -- DigitalOcean Spaces
    digitalocean = {
        patterns = {
            "%..*%.digitaloceanspaces%.com$",
            "%..*%.cdn%.digitaloceanspaces%.com$"
        },
        provider = "DigitalOcean Spaces",
        service_type = "do_spaces"
    },
    
    -- Backblaze B2
    backblaze = {
        patterns = {
            "%.backblazeb2%.com$",
            "f.*%.backblazeb2%.com$",
            "s3%..*%.backblazeb2%.com$"
        },
        provider = "Backblaze B2",
        service_type = "backblaze_b2"
    },
    
    -- Wasabi
    wasabi = {
        patterns = {
            "%.wasabisys%.com$",
            "s3%..*%.wasabisys%.com$"
        },
        provider = "Wasabi",
        service_type = "wasabi"
    },
    
    -- IBM Cloud Object Storage
    ibm = {
        patterns = {
            "%.objectstorage%..*%.cloud%.ibm%.com$",
            "%.cloud%-object%-storage%..*%.cloud%.ibm%.com$"
        },
        provider = "IBM Cloud Object Storage",
        service_type = "ibm_cos"
    },
    
    -- Oracle Cloud Infrastructure Object Storage
    oracle = {
        patterns = {
            "%.objectstorage%..*%.oraclecloud%.com$",
            "objectstorage%..*%.oraclecloud%.com$"
        },
        provider = "Oracle Cloud Object Storage",
        service_type = "oracle_oss"
    },
    
    -- Generic CDN patterns that might indicate OSS backends
    cdn = {
        patterns = {
            "%.cloudfront%.net$",
            "%.fastly%.com$",
            "%.cloudflare%.com$",
            "%.jsdelivr%.net$",
            "%.unpkg%.com$"
        },
        provider = "CDN (potential OSS backend)",
        service_type = "cdn_oss"
    }
}

-- Function to extract bucket name from different URL patterns
local function extract_bucket_name(value, service_type)
    local bucket_name = nil
    
    if service_type == "s3" then
        -- S3 patterns: bucket.s3.amazonaws.com or s3.amazonaws.com/bucket
        bucket_name = string.match(value, "^([^%.]+)%.s3%.") or
                     string.match(value, "^([^%.]+)%.s3%-") or
                     string.match(value, "s3://([^/]+)")
    elseif service_type == "gcs" then
        -- GCS patterns: bucket.storage.googleapis.com or storage.cloud.google.com/bucket
        bucket_name = string.match(value, "^([^%.]+)%.storage%.googleapis%.com") or
                     string.match(value, "gs://([^/]+)")
    elseif service_type == "azure_blob" then
        -- Azure patterns: account.blob.core.windows.net
        bucket_name = string.match(value, "^([^%.]+)%.blob%.core%.windows%.net")
    elseif service_type == "aliyun_oss" then
        -- Aliyun patterns: bucket.oss-region.aliyuncs.com
        bucket_name = string.match(value, "^([^%.]+)%.oss%-") or
                     string.match(value, "oss://([^/]+)")
    elseif service_type == "tencent_cos" then
        -- Tencent patterns: bucket.cos.region.myqcloud.com
        bucket_name = string.match(value, "^([^%.]+)%.cos%.") or
                     string.match(value, "cos://([^/]+)")
    elseif service_type == "huawei_obs" then
        -- Huawei patterns: bucket.obs.region.myhuaweicloud.com
        bucket_name = string.match(value, "^([^%.]+)%.obs%.") or
                     string.match(value, "obs://([^/]+)")
    elseif service_type == "do_spaces" then
        -- DigitalOcean patterns: bucket.region.digitaloceanspaces.com
        bucket_name = string.match(value, "^([^%.]+)%..*%.digitaloceanspaces%.com")
    elseif service_type == "backblaze_b2" then
        -- Backblaze patterns: f001.backblazeb2.com/file/bucket/
        bucket_name = string.match(value, "backblazeb2%.com/file/([^/]+)")
    elseif service_type == "wasabi" then
        -- Wasabi patterns: s3.region.wasabisys.com/bucket
        bucket_name = string.match(value, "^([^%.]+)%..*%.wasabisys%.com")
    end
    
    return bucket_name
end

-- Function to probe OSS bucket endpoints
local function probe_oss_endpoint(url, service_type)
    local headers = {
        ["User-Agent"] = "RegTech-OSS-Scanner/1.0",
        ["Accept"] = "*/*"
    }
    
    -- Try different common endpoints
    local endpoints = {url}
    
    -- Add common OSS endpoints based on service type
    if service_type == "s3" then
        table.insert(endpoints, url .. "/")
        table.insert(endpoints, url .. "/?list-type=2")
    elseif service_type == "gcs" then
        table.insert(endpoints, url .. "/")
        table.insert(endpoints, url .. "/?list")
    elseif service_type == "azure_blob" then
        table.insert(endpoints, url .. "/")
        table.insert(endpoints, url .. "/?restype=container&comp=list")
    end
    
    local best_response = nil
    local best_status = 0
    
    for _, endpoint in ipairs(endpoints) do
        local status, body, response_headers, err = http.get(endpoint, headers, 10)
        if status then
            log("OSS probe " .. endpoint .. " -> HTTP " .. status)
            
            -- Store the most informative response
            if status > best_status and status ~= 404 then
                best_response = {
                    status = status,
                    body = body or "",
                    headers = response_headers or {},
                    url = endpoint
                }
                best_status = status
            end
            
            -- Check response headers for OSS indicators
            if response_headers then
                for header, value in pairs(response_headers) do
                    local lower_header = string.lower(header)
                    if lower_header == "server" or lower_header == "x-amz-server" or 
                       lower_header == "x-goog-server" or lower_header == "x-ms-server" then
                        log("OSS server header: " .. header .. ": " .. value)
                        set_metadata("oss_server_header", value)
                    end
                end
            end
        else
            log("OSS probe failed for " .. endpoint .. ": " .. (err or "unknown error"))
        end
        
        -- Rate limiting
        sleep(0.5)
    end
    
    return best_response
end

-- Function to analyze OSS response for additional metadata
local function analyze_oss_response(response, service_type)
    if not response then return end
    
    local body = response.body
    local headers = response.headers
    
    -- Check for XML listing responses (common in S3, GCS, etc.)
    if body and string.match(body, "<ListBucketResult") then
        log("OSS bucket listing detected")
        add_tag("oss-listable")
        set_metadata("oss_listing_detected", true)
        
        -- Extract object count if available
        local objects = {}
        for key in string.gmatch(body, "<Key>(.-)</Key>") do
            table.insert(objects, key)
        end
        
        if #objects > 0 then
            set_metadata("oss_object_count", #objects)
            set_metadata("oss_sample_objects", table.concat(objects, ",", 1, math.min(10, #objects)))
            log("Found " .. #objects .. " objects in bucket")
        end
    end
    
    -- Check for directory-style listings (HTML)
    if body and string.match(body, "<title>Index of") then
        log("OSS directory listing detected (HTML)")
        add_tag("oss-directory-listing")
        set_metadata("oss_directory_listing", true)
    end
    
    -- Check for specific error messages that indicate OSS presence
    if body then
        if string.match(body, "NoSuchBucket") or string.match(body, "BucketNotFound") then
            log("OSS bucket not found error - confirms OSS endpoint")
            add_tag("oss-endpoint-confirmed")
        elseif string.match(body, "AccessDenied") or string.match(body, "Forbidden") then
            log("OSS access denied - bucket exists but is protected")
            add_tag("oss-access-denied")
            set_metadata("oss_access_status", "denied")
        elseif string.match(body, "AllAccessDisabled") then
            log("OSS all access disabled")
            add_tag("oss-all-access-disabled")
            set_metadata("oss_access_status", "disabled")
        end
    end
    
    -- Analyze response headers for OSS-specific information
    if headers then
        for header, value in pairs(headers) do
            local lower_header = string.lower(header)
            if lower_header == "x-amz-bucket-region" then
                set_metadata("oss_region", value)
                log("OSS region detected: " .. value)
            elseif lower_header == "x-goog-storage-class" then
                set_metadata("oss_storage_class", value)
                log("OSS storage class: " .. value)
            elseif lower_header == "x-ms-blob-type" then
                set_metadata("oss_blob_type", value)
                log("OSS blob type: " .. value)
            end
        end
    end
end

-- Main detection logic
local function detect_oss_bucket()
    local target_value = asset.value
    local detected_service = nil
    local detected_provider = nil
    
    -- Check asset value against OSS patterns
    for service_key, service_info in pairs(oss_patterns) do
        for _, pattern in ipairs(service_info.patterns) do
            if string.match(target_value, pattern) then
                log("OSS pattern match: " .. pattern .. " -> " .. service_info.provider)
                detected_service = service_info.service_type
                detected_provider = service_info.provider
                break
            end
        end
        if detected_service then break end
    end
    
    if not detected_service then
        log("No OSS patterns matched for " .. target_value)
        na()
        return
    end
    
    -- Extract bucket name
    local bucket_name = extract_bucket_name(target_value, detected_service)
    if bucket_name then
        log("Extracted bucket name: " .. bucket_name)
        set_metadata("oss_bucket_name", bucket_name)
    end
    
    -- Set basic OSS metadata
    set_metadata("oss_detected", true)
    set_metadata("oss_provider", detected_provider)
    set_metadata("oss_service_type", detected_service)
    
    -- Add tags
    add_tag("oss-bucket")
    add_tag("oss-" .. detected_service)
    add_tag("cloud-storage")
    
    -- Construct URLs for probing
    local probe_urls = {}
    if asset.type == "domain" or asset.type == "subdomain" then
        table.insert(probe_urls, "http://" .. target_value)
        table.insert(probe_urls, "https://" .. target_value)
    elseif asset.type == "service" then
        -- Extract host and port from service asset
        local host, port_str = string.match(target_value, "([^:]+):(%d+)")
        if host and port_str then
            local port = tonumber(port_str)
            local scheme = (port == 443 or port == 8443) and "https" or "http"
            table.insert(probe_urls, scheme .. "://" .. host .. ":" .. port)
        end
    end
    
    -- Probe OSS endpoints
    local response_found = false
    for _, url in ipairs(probe_urls) do
        local response = probe_oss_endpoint(url, detected_service)
        if response then
            response_found = true
            analyze_oss_response(response, detected_service)
            set_metadata("oss_probe_url", url)
            set_metadata("oss_probe_status", response.status)
            break
        end
    end
    
    if response_found then
        log("OSS bucket detection completed successfully")
        add_tag("oss-responsive")
        pass()
    else
        log("OSS bucket pattern detected but endpoint not responsive")
        add_tag("oss-unresponsive")
        pass()  -- Still pass because we detected the pattern
    end
end

-- Execute detection
detect_oss_bucket()

log("OSS bucket detection analysis complete for " .. asset.value)
