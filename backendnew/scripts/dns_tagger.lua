-- @title DNS Record Tagger
-- @description Analyzes DNS records and adds relevant tags
-- @category dns
-- @author RegTech
-- @version 1.0
-- @asset_types domain,subdomain

-- Only run on domain/subdomain assets
if asset.type ~= "domain" and asset.type ~= "subdomain" then
  return
end

log("Analyzing DNS records for " .. asset.value)

-- Check if we have DNS records
if not asset.dns_records then
  log("No DNS records found for " .. asset.value)
  return
end

-- Tag based on DNS record types
if asset.dns_records.a and #asset.dns_records.a > 0 then
  add_tag("has-ipv4")
  log("Found " .. #asset.dns_records.a .. " A records")
end

if asset.dns_records.aaaa and #asset.dns_records.aaaa > 0 then
  add_tag("has-ipv6")
  log("Found " .. #asset.dns_records.aaaa .. " AAAA records")
end

if asset.dns_records.mx and #asset.dns_records.mx > 0 then
  add_tag("mail-server")
  log("Found " .. #asset.dns_records.mx .. " MX records")
end

if asset.dns_records.cname and #asset.dns_records.cname > 0 then
  add_tag("has-cname")
  log("Found " .. #asset.dns_records.cname .. " CNAME records")
end

if asset.dns_records.txt and #asset.dns_records.txt > 0 then
  add_tag("has-txt")
  log("Found " .. #asset.dns_records.txt .. " TXT records")
  
  -- Check for specific TXT record patterns
  for _, txt in ipairs(asset.dns_records.txt) do
    if txt:match("v=spf1") then
      add_tag("spf-configured")
      log("SPF record found")
    end
    if txt:match("v=DMARC1") then
      add_tag("dmarc-configured")
      log("DMARC record found")
    end
    if txt:match("google%-site%-verification") then
      add_tag("google-verified")
      log("Google site verification found")
    end
  end
end

-- Check existing tags for additional context
if asset.tags then
  for _, tag in ipairs(asset.tags) do
    if tag == "cf-proxied" then
      log("Asset is Cloudflare proxied")
    end
  end
end

pass()
