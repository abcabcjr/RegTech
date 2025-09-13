-- @title HTTP Title Extractor
-- @description Extracts <title> from HTTP responses, assumes HTTP already detected
-- @category enrichment
-- @author RegTech
-- @version 1.0
-- @asset_types service
-- @requires_passed http_probe.lua

local function parse_title(body)
  if not body or #body == 0 then return nil end
  local title = body:match("<title>(.-)</title>") or body:match("<TITLE>(.-)</TITLE>")
  if title then
    title = title:gsub("\n", " ")
    title = (title:gsub("^%s+", ""):gsub("%s+$", ""))
  end
  return title
end

if asset.type ~= "service" then return end

local host, rest = asset.value:match("^([^:]+):(.+)$")
local port = nil
if rest then port = tonumber(rest:match("^(%d+)") or "") end
if not (host and port) then return end

local url
if port == 443 or port == 8443 then
  url = "https://" .. host .. ":" .. tostring(port) .. "/"
else
  url = "http://" .. host .. ":" .. tostring(port) .. "/"
end

local status, body, hdrs = http.get(url, { ["Accept"] = "text/html" }, 8)
if not status then return end

local title = parse_title(body)
if title then
  set_metadata("http.title", title)
  pass()
end


