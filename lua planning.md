# pure-Lua scanner: module plan and script list (no Nmap)

Goal: implement the CyberCare MVP checks in Lua, without Nmap. This is a practical, buildable inventory of Lua modules you can code now. It mirrors the previous NSE list but uses our own event loop, sockets, and parsers.

## runtime and deps (minimal, portable)

Choose one event loop stack and stick to it:

- Event loop and sockets: `cqueues` (TCP/UDP timers, DNS resolver)
- TLS/crypto: `luaossl` (OpenSSL bindings)
- HTTP client: `lua-http` (built on cqueues)
- JSON: `lua-cjson`
- YAML (for optional rule templates): `lyaml`
- Filesystem/util: `luafilesystem`, `lpeg` (parsing helpers)

Optional (phase 2 or where available):

- ARP and packet capture: LuaJIT FFI to `libpcap` or a `luapcap` binding (otherwise skip ARP and use TCP “light ping”)
- SSH handshake details: LuaJIT FFI to `libssh2` (otherwise banner-only)
- SMB2 negotiate: pure-Lua binary serializer (we’ll provide a minimal frame)

Directory layout:

```/engine
  scheduler.lua        -- cqueues loop, rate limiting, task orchestration
  net.lua              -- connect/read/write with timeouts; UDP helpers
  dns.lua              -- TXT/A/AAAA lookups via cqueues.dns
  tlsprobe.lua         -- TLS handshakes with version/cipher controls
  httpclient.lua       -- thin wrapper over lua-http with sane defaults
  evidence.lua         -- normalize, hash, serialize JSON
/probes                -- collect raw evidence (safe, read-only)
  host_discovery.lua
  portscan_tcp.lua
  banners.lua
  tls_baseline.lua
  http_headers.lua
  hsts_redirect.lua
  smtp_starttls.lua
  ssh_params.lua
  smb_negotiate.lua
  rdp_security.lua
  dns_recursion.lua
  spf.lua
  dmarc.lua
  dkim.lua
  datastore_open.lua   -- redis/mongo/elastic/rabbit, etc.
/checks                -- derive findings from evidence
  tls_policies.lua
  web_sec_headers.lua
  cookie_flags.lua
  cors_misconfig.lua
  service_cpe_guess.lua
  legacy_services.lua  -- telnet/rsh/finger/tftp
  smb_policies.lua     -- smb1/signing/ntlmv1
  rdp_policies.lua
  mail_transport.lua   -- STARTTLS, min TLS
  exposure_console.lua -- backup/admin UIs
  availability.lua
/ui-mapping
  law_tags.lua         -- Article 11/12 mapping helpers
/reports
  json_export.lua
  pdf_export.lua       -- optional, via wkhtmltopdf wrapper or latex later

```

## execution profiles (built into scheduler)

- Safe (default): small concurrency (e.g., 64 sockets), no credential attempts, HEAD/GET only, per-host backoff on loss/RTT spikes.
- Standard: moderate concurrency, broader benign paths.
- Intensive (opt-in): allow optional tests (e.g., SNMP public, null session) on an allowlist.

## script/module list

Each probe returns a table:  
`{ target={ip,port,proto}, summary, details={...}, confidence, safety_note, refs }`  
Checks consume evidence and output normalized findings with law tags.

### 1) discovery and inventory

- `probes/host_discovery.lua`  
    TCP “light ping” to {443, 80, 22, 3389, 445, 53}; optional ARP if `libpcap` present.  
    Evidence: live hosts, RTT, MAC/OUI (if ARP).  
    Article 11: asset visibility.
- `probes/portscan_tcp.lua`  
    TCP connect scan over a curated top-ports set; token-bucket rate limiter.  
    Evidence: open/closed/filtered, per-port RTT sample.  
    Article 11: internet exposure.
- `probes/banners.lua`  
    First-line banners for SMTP/FTP/POP/IMAP/SSH/Redis/AMQP, HTTP server header and HTML title.  
    Evidence: banner strings, proto guess.  
    Article 11: service inventory.

### 2) TLS and HTTPS hygiene

- `probes/tls_baseline.lua`  
    Attempt handshakes for TLSv1.0/1.1/1.2/1.3; collect selected cipher lists per version. Uses `luaossl` to set min/max protocol and cipher list; retry per version.  
    Evidence: min/max accepted TLS, weak suites seen (RC4/3DES/NULL/EXPORT).  
    Article 11: transport security.
- `probes/http_headers.lua`  
    Fetch `GET /` over HTTPS; capture security headers (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy).  
    Evidence: header presence and values.  
    Article 11: web hardening.
- `probes/hsts_redirect.lua`  
    Try `http://` and observe 301/302 to `https://`; inspect `Strict-Transport-Security`.  
    Evidence: redirect present, HSTS present/max-age/includeSubDomains/preload.  
    Article 11: strict transport.
- `checks/tls_policies.lua`  
    Evaluate TLS version floor, weak ciphers, cert key size/sig alg/expiry (cert parsed from tls handshake).  
    Finding IDs: `tls_min_version`, `tls_weak_ciphers`, `cert_expiring_<bucket>`.  
    Article 11.

### 3) email authentication

- `probes/spf.lua`  
    TXT lookup for root and `_spf.` includes; parse `all` qualifier.  
    Evidence: spf record, mechanisms, qualifier.  
    Article 11: domain spoofing protection.
- `probes/dmarc.lua`  
    `_dmarc` TXT lookup; parse `p=`, `rua`, `ruf`, `adkim`, `aspf`.  
    Evidence: policy, reports, alignment.  
    Article 11.
- `probes/dkim.lua`  
    Probe common selectors (`default`, `s1`, vendor patterns) for `selector._domainkey.example TXT`.  
    Evidence: selectors found, key length.  
    Article 11.
- `probes/smtp_starttls.lua`  
    EHLO features; attempt STARTTLS; post-upgrade min TLS version via `luaossl`.  
    Evidence: `starttls_supported`, `min_tls_after_starttls`.  
    Article 11.
- `checks/mail_transport.lua`  
    Combine SPF/DMARC/DKIM/STARTTLS into clear findings.

### 4) exposure, versions, and risky services

- `probes/ssh_params.lua`  
    Read SSH banner; optionally perform KEXINIT to list KEX/ciphers/MACs (minimal SSH packet builder in Lua).  
    Evidence: server version, weak alg presence.  
    Article 11.
- `probes/smb_negotiate.lua`  
    Send SMB2 NEGOTIATE (pure Lua binary) to get dialect and signing flags; detect SMB1 by NetBIOS session service fallback.  
    Evidence: dialect, `signing_required`, `smb1_enabled`.  
    Article 11.
- `probes/rdp_security.lua`  
    Perform X.224/TPKT and security negotiation; detect NLA required and TLS.  
    Evidence: `nla_required`, `tls_layer`.  
    Article 11.
- `probes/dns_recursion.lua`  
    Recursion test for a non-authoritative name; verify RA flag and answer source.  
    Evidence: `recursion_allowed`.  
    Article 11.
- `probes/datastore_open.lua`  
    Lightweight unauth checks: Redis `PING`, Mongo `isMaster`, Elasticsearch `/_cluster/health`, RabbitMQ mgmt banner.  
    Evidence: `unauth_ok`, product hints.  
    Article 11.
- `checks/service_cpe_guess.lua`  
    Normalize banners to CPE candidates (heuristics + regex), for later CVE overlay in your backend.  
    Evidence: `cpe[]`, version fields.  
    Article 11 (CVE footprint seed).
- `checks/legacy_services.lua`  
    Flag telnet/rsh/finger/tftp if responsive.  
    Article 11.
- `checks/smb_policies.lua`, `checks/rdp_policies.lua`  
    Derive simple pass/fail findings for SMB1/Signing and RDP/NLA.
- `checks/exposure_console.lua`  
    Detect exposed backup/admin consoles (Veeam, Proxmox Backup, Bacula web) and whether served over HTTP or weak TLS.

### 5) Wi-Fi and LAN guardrails

- `engine/scheduler.lua` (built-in behavior)  
    Adaptive throttle: monitor connect error rate and RTT p95; reduce concurrency when thresholds are exceeded.  
    Evidence: `throttle_events`, `avg_rtt`, `loss_estimate` attached to scan metadata.
- `probes/lan_isolation.lua`  
    Heuristic: gateway reachable, peers time out, ARP unicast ignored (if `libpcap`), mark “client isolation suspected”.  
    Article 11: discovery limitation evidence.

### 6) availability snapshots for incident reporting (Article 12)

- `probes/availability.lua`  
    For selected ports/URLs, sample 3× during the run; compute availability and median latency.  
    Evidence: `success_ratio`, `latency_ms`.  
    Article 12: Initial/Update facts.
- `checks/availability.lua`  
    Turn samples into a simple status and a note usable in the report wizard.

### 7) optional, consent-gated

- `probes/snmp_public.lua`  
    v2c “public” test only on allowlisted IPs.
- `probes/smb_null.lua`  
    Legacy null session attempt on allowlist.
- `probes/default_creds.lua`  
    One safe vendor-specific probe when explicitly configured.  
    All disabled by default; require explicit consent and allowlist.

## evidence schema (shared)

`-- evidence.lua -- normalize(e) returns a stable table ready for cjson.encode -- { host, port, proto, summary, details, confidence, safety_note, refs, law_tags }`

Law tags (for UI filtering and report exports):

- `{"article":11, "area":"transport_security"}`
- `{"article":11, "area":"email_auth"}`
- `{"article":12, "area":"availability"}`

## concurrency and rate limits

- Global token bucket for outbound connects (default 64 concurrent sockets; configurable).
- Per-host limit (default 4 concurrent connections).
- Adaptive backoff when connect error rate >15% over 10s or p95 RTT >1.5× baseline.
- Hard per-socket timeouts (connect 2s, read 2s; exponential backoff).
## minimal skeletons (ready to paste)

`engine/net.lua`
```lua
local cqueues = require "cqueues"
local socket  = require "cqueues.socket"

local M = {}

function M.tcp_connect(host, port, timeout)
  local s, err = socket.connect(host, tostring(port))
  if not s then return nil, ("connect error: %s"):format(err) end
  s:setmode("nb")
  s:settimeout(timeout or 2.0)
  return s
end

function M.read_line(s, maxlen)
  return s:read("*l", maxlen or 4096)
end

function M.write(s, data)
  return s:write(data)
end

function M.close(s) pcall(function() s:close() end) end

return M

```
`probes/http_headers.lua`
```lua
local http      = require "http.request"
local cjson     = require "cjson.safe"
local evidence  = require "evidence"

return function(host, port)
  local url = ("https://%s:%d/"):format(host, port or 443)
  local req = http.new_from_uri(url)
  req.headers:upsert(":method", "GET")
  local headers, status, err
  local headers_out = {}

  local headers_obj, stream = req:go(2.0) -- 2s timeout
  if not headers_obj then
    return evidence.make(host, port or 443, "tcp",
      "HTTPS fetch failed", { error = err or "timeout" }, 0.5, "safe", {"RFC7231"})
  end
  status = tonumber(headers_obj:get(":status")) or 0
  for k, v in headers_obj:each() do headers_out[k:lower()] = v end
  return evidence.make(host, port or 443, "tcp",
    "Collected HTTP security headers",
    {
      status = status,
      csp = headers_out["content-security-policy"],
      xfo = headers_out["x-frame-options"],
      xcto = headers_out["x-content-type-options"],
      referrer = headers_out["referrer-policy"],
      permissions = headers_out["permissions-policy"],
      hsts = headers_out["strict-transport-security"],
    },
    0.9,
    "safe",
    {"RFC6797","CSP"}
  )
end
```
`probes/tls_baseline.lua
```lua
local ssl      = require "openssl.ssl"
local x509     = require "openssl.x509"
local ev       = require "evidence"
local socket   = require "cqueues.socket"

local versions = {
  {name="TLSv1.0", opt="no_tlsv1_1 no_tlsv1_2 no_tlsv1_3", ctxf=function(ctx) ctx:setOptions(ssl.no_tlsv1_1+ssl.no_tlsv1_2+ssl.no_tlsv1_3) end},
  {name="TLSv1.1", opt="no_tlsv1 no_tlsv1_2 no_tlsv1_3",  ctxf=function(ctx) ctx:setOptions(ssl.no_tlsv1+ssl.no_tlsv1_2+ssl.no_tlsv1_3) end},
  {name="TLSv1.2", opt="no_tlsv1 no_tlsv1_1 no_tlsv1_3",  ctxf=function(ctx) ctx:setOptions(ssl.no_tlsv1+ssl.no_tlsv1_1+ssl.no_tlsv1_3) end},
  {name="TLSv1.3", opt="no_tlsv1 no_tlsv1_1 no_tlsv1_2",  ctxf=function(ctx) ctx:setOptions(ssl.no_tlsv1+ssl.no_tlsv1_1+ssl.no_tlsv1_2) end},
}

return function(host, port)
  local accepted, minv, maxv = {}, nil, nil
  for _, v in ipairs(versions) do
    local ctx = assert(ssl.ctx_new("TLS", false))
    v.ctxf(ctx)
    local s, err = socket.connect(host, tostring(port or 443))
    if not s then goto continue end
    s:settimeout(2.0)
    local ok, tls = pcall(ssl.wrap, ctx, s, {servername=host})
    if ok and tls then
      local okh, e = pcall(tls.handshake, tls)
      if okh then
        table.insert(accepted, v.name)
        minv = minv or v.name
        maxv = v.name
      end
      pcall(function() tls:close() end)
    end
    ::continue::
  end
  local details = {accepted = accepted, min = minv, max = maxv}
  return ev.make(host, port or 443, "tcp", "TLS baseline enumeration", details, #accepted>0 and 0.9 or 0.4, "safe", {"TLS"})
end
```
`probes/spf.lua`
```lua
local dns     = require "cqueues.dns"
local ev      = require "evidence"

return function(domain)
  local r = dns.new()
  local answers = r:query(domain, "TXT")
  local spf
  if answers then
    for _, a in ipairs(answers) do
      local txt = table.concat(a.txt or {}, "")
      if txt:match("^v=spf1") then spf = txt break end
    end
  end
  local qual = spf and spf:match("%s([~%-%?%+])all") or nil
  return ev.make(domain, 0, "dns", "SPF record", {spf=spf, all_qualifier=qual}, spf and 0.9 or 0.5, "safe", {"SPF"})
end
```
## mapping to challenge requirements
- Internet exposure inventory: `host_discovery`, `portscan_tcp`, `banners`
- TLS policies: `tls_baseline`, `tls_policies`, `hsts_redirect`, `http_headers`
- Web security headers: `http_headers`, `cookie_flags`, `cors_misconfig`
- Email authentication: `spf`, `dmarc`, `dkim`, `smtp_starttls`
- CVE footprint: `service_cpe_guess` feeds your backend CVE overlay (NVD/KEV/EPSS)
- IAM/MFA, backup restore, logging: handled via UI checklist and evidence uploads
- Incident reporting: `availability` provides status/latency snapshots for Initial/Update/Final
## test strategy
- Golden fixtures: capture real headers/certs/banners into JSON; unit-test check modules against fixtures.
- Live integration: docker-compose with OpenSSH, Nginx (various TLS configs), Redis, Mongo, RabbitMQ, Bind.
- Wi-Fi safety: run scans against a cheap AP; verify scheduler throttles under induced loss.
## packaging
- CLI: `lua ./cli.lua --target 192.168.1.0/24 --profile safe --out scan.json`
- API: small `lua-http` or OpenResty app exposing `/scan` and `/results/:id` for the Svelte UI.
- Single-binary option later via LuaJIT bytecode + `luastatic` or `srlua