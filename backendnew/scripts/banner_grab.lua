-- @title TCP Banner Grab
-- @description Connects to a service and attempts to read a banner (e.g., SSH/SMTP)
-- @category service_detection
-- @author RegTech
-- @version 1.0
-- @asset_types service
-- @requires_passed basic_info.lua

local function parse_service_from_value(v)
  -- expects "host:port/proto"
  local host, rest = v:match("^([^:]+):(.+)$")
  if not host or not rest then return nil, nil end
  local port = tonumber(rest:match("^(%d+)") or "")
  return host, port
end

if asset.type ~= "service" then
  return
end

local host, port = parse_service_from_value(asset.value)
if not host or not port then
  return
end

local fd, err = tcp.connect(host, port, 5)
if fd then
  local b = tcp.recv(fd, 1024, 3)
  if b and #b > 0 then
    set_metadata("banner.port." .. tostring(port), b)
    -- Quick heuristics
    if b:match("^SSH-") then set_metadata("service.port." .. tostring(port), "ssh") end
    if b:match("^220") and b:lower():match("smtp") then set_metadata("service.port." .. tostring(port), "smtp") end
    pass()
  end
  tcp.close(fd)
else
  log("banner connect failed " .. host .. ":" .. tostring(port) .. " -> " .. tostring(err))
end


