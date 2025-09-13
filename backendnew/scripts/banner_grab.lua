-- @title TCP Banner & Service Fingerprint
-- @description Determine service type and version for a service asset using banners and protocol nudges
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

local function trim(s)
  if not s then return s end
  s = s:gsub("\r", " ")
  s = s:gsub("\n", " ")
  s = s:gsub("%s+", " ")
  return s:match("^%s*(.-)%s*$")
end

local function guess_by_port(port)
  local known = {
    [21] = "ftp", [22] = "ssh", [23] = "telnet", [25] = "smtp",
    [53] = "dns", [80] = "http", [110] = "pop3", [143] = "imap",
    [443] = "https", [465] = "smtps", [587] = "smtp",
    [993] = "imaps", [995] = "pop3s", [8080] = "http", [8443] = "https",
    [3306] = "mysql", [5432] = "postgres", [6379] = "redis",
    [27017] = "mongodb", [3389] = "rdp"
  }
  return known[port] or "unknown"
end

local function detect_from_banner(port, banner)
  if not banner or banner == "" then return nil, nil end
  local b = banner:lower()
  -- SSH: SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.3
  if b:match("^ssh%-") then
    local ver = banner:match("OpenSSH[_%-]([%d%._%p]+)") or banner:match("^SSH%-([%d%.]+)")
    return "ssh", ver or "unknown"
  end
  -- SMTP: 220 mail ESMTP Postfix (Ubuntu)
  if b:match("^220") and b:match("smtp") then
    local ver = banner:match("Postfix[%s%(%)]*([%d%._%-]+)") or banner:match("Exim[%s%(%)]*([%d%._%-]+)") or banner:match("Sendmail[%s%(%)]*([%d%._%-]+)")
    return "smtp", ver or "unknown"
  end
  -- FTP: 220 (vsFTPd 3.0.3) / 220-FileZilla Server 0.9.41
  if b:match("ftp") or (b:match("^220") and (port == 21)) then
    local ver = banner:match("vsFTPd%s*([%d%._%-]+)") or banner:match("FileZilla Server%s*([%d%._%-]+)") or banner:match("Pure%-FTPd%s*([%d%._%-]+)") or banner:match("ProFTPD%s*([%d%._%-]+)")
    return "ftp", ver or "unknown"
  end
  -- HTTP: look for HTTP/ and possible Server header line in raw
  if b:match("http/1%.") or b:match("http/2") then
    local server = banner:match("[Ss]erver:%s*([^\r\n]+)")
    return (port == 443 or port == 8443) and "https" or "http", server or "unknown"
  end
  -- POP3
  if b:match("pop3") or (b:match("^%+ok") and port == 110) then
    local ver = banner:match("Dovecot%s*([%d%._%-]+)") or banner:match("Courier%-POP3%s*([%d%._%-]+)")
    return "pop3", ver or "unknown"
  end
  -- IMAP
  if b:match("imap") or (b:match("%*%s+ok") and port == 143) then
    local ver = banner:match("Dovecot%s*([%d%._%-]+)")
    return "imap", ver or "unknown"
  end
  -- Redis
  if b:match("%+pong") or b:match("%-noauth") or b:match("redis") then
    return "redis", "unknown"
  end
  -- MySQL (binary), PostgreSQL (needs startup), MongoDB (often needs handshake) -> unknown version
  if port == 3306 then return "mysql", "unknown" end
  if port == 5432 then return "postgres", "unknown" end
  if port == 27017 then return "mongodb", "unknown" end
  -- RDP
  if port == 3389 then return "rdp", "unknown" end
  return nil, nil
end

local function http_probe(host, port)
  local scheme = (port == 443 or port == 8443) and "https" or "http"
  local url = scheme .. "://" .. host .. ":" .. tostring(port)
  local status, body, headers = http.get(url, { ["Accept"] = "*/*" }, 6)
  if status then
    local server = nil
    if headers and headers["Server"] then
      server = headers["Server"]
    end
    return (scheme == "https" and "https" or "http"), server or "unknown"
  end
  return nil, nil
end

if asset.type ~= "service" then
  return
end

local host, port = parse_service_from_value(asset.value)
if not host or not port then
  return
end

local svc_type = nil
local svc_version = nil
local banner_text = nil

-- Try TCP connect and passive banner read
do
  local fd, err = tcp.connect(host, port, 3)
  if fd then
    local b = tcp.recv(fd, 1400, 2)
    if b and #b > 0 then
      banner_text = b
      local t, v = detect_from_banner(port, b)
      if t then svc_type = t end
      if v then svc_version = v end
    else
      -- Active nudge for HTTP-ish ports: use real HTTP client instead for accurate Server header
      if port == 80 or port == 8080 or port == 8000 or port == 443 or port == 8443 then
        local t, v = http_probe(host, port)
        if t then svc_type = t end
        if v then svc_version = v end
      end
    end
    tcp.close(fd)
  else
    -- Connection failed; we will fall back to port guess below, but still record the failure
    log("banner connect failed " .. host .. ":" .. tostring(port) .. " -> " .. tostring(err))
  end
end

-- If still unknown, try to infer from banner once more, or from port mapping
if not svc_type then
  if banner_text then
    local t, v = detect_from_banner(port, banner_text)
    svc_type = t
    svc_version = v
  end
end
if not svc_type then
  svc_type = guess_by_port(port)
  svc_version = svc_version or "unknown"
end

-- Always set metadata for type and version; also store banner snippet if present
set_metadata("service.port." .. tostring(port), svc_type)
set_metadata("service.version.port." .. tostring(port), tostring(svc_version or "unknown"))
if banner_text and #banner_text > 0 then
  set_metadata("banner.port." .. tostring(port), banner_text)
end
add_tag(svc_type)

-- Log human-readable line
local snippet = banner_text and trim(banner_text):sub(1, 200) or "<none>"
log("service " .. host .. ":" .. tostring(port) .. " type=" .. svc_type .. " version=\"" .. tostring(svc_version or "unknown") .. "\" banner=\"" .. snippet .. "\"")

pass()


