-- @title HTTP Probe
-- @description Probe endpoints to detect HTTP services, fetch headers and page title
-- @category service_detection
-- @author RegTech
-- @version 1.0
-- @asset_types service
-- @requires_passed basic_info.lua

-- small helpers
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_title(body)
  if not body or #body == 0 then return nil end
  local title = body:match("<title>(.-)</title>") or body:match("<TITLE>(.-)</TITLE>")
  if title then
    title = title:gsub("\n", " ")
    title = trim(title)
  end
  return title
end

local function try_request(url)
  local status, body, hdrs = http.get(url, { ["Accept"] = "text/html,application/xhtml+xml,application/xml" }, 8)
  if not status then
    return nil, body -- body contains error string in our http lib
  end
  return { status = status, body = body or "", headers = hdrs }, nil
end

local function set_http_metadata(url, resp)
  set_metadata("http.url", url)
  set_metadata("http.status", resp.status)
  if resp.headers then
    if resp.headers["Server"] then set_metadata("http.server", resp.headers["Server"]) end
    if resp.headers["Content-Type"] then set_metadata("http.content_type", resp.headers["Content-Type"]) end
  end
  local title = parse_title(resp.body)
  if title then set_metadata("http.title", title) end
end

local function probe_urls(urls)
  for _, u in ipairs(urls) do
    local resp, err = try_request(u)
    if resp then
      set_http_metadata(u, resp)
      set_metadata("http.detected", true)
      pass()
      return true
    else
      log("HTTP probe failed for " .. u .. ": " .. tostring(err))
    end
  end
  return false
end

-- Build URL candidates based on service asset
local urls = {}

if asset.type ~= "service" then
  return
end

-- Expect value like "host:port/tcp"
local host, rest = asset.value:match("^([^:]+):(.+)$")
local port = nil
if rest then port = tonumber(rest:match("^(%d+)") or "") end
if host and port then
  if port == 443 or port == 8443 then
    table.insert(urls, "https://" .. host .. ":" .. tostring(port) .. "/")
  elseif port == 80 or port == 8080 or port == 8000 then
    table.insert(urls, "http://" .. host .. ":" .. tostring(port) .. "/")
  else
    -- try both
    table.insert(urls, "http://" .. host .. ":" .. tostring(port) .. "/")
    table.insert(urls, "https://" .. host .. ":" .. tostring(port) .. "/")
  end
end

if #urls == 0 then
  return -- not applicable
end

probe_urls(urls)


