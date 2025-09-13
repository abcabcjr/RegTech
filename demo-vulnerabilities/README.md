# 🎯 RegTech Shopify Security Demo - Complete Setup Guide

## Overview
This guide helps you create an intentionally vulnerable Shopify environment to demonstrate our security scanning capabilities.

## 🏗️ Setup Options

### Option A: Real Shopify Development Store (Recommended)
1. **Create Free Development Store:**
   - Go to [partners.shopify.com](https://partners.shopify.com)
   - Sign up for free Partner account
   - Create "Development Store" 
   - Choose subdomain: `regtech-security-demo.myshopify.com`

2. **Add Vulnerable Theme Code:**
   - Go to Online Store > Themes > Actions > Edit Code
   - Add contents of `shopify-vulnerable-theme-snippets.liquid` to `theme.liquid`
   - Add `shopify-open-redirect-vulnerable.liquid` content to a new page template

3. **Create Vulnerable Products:**
   - Follow instructions in `shopify-json-exposure-setup.md`
   - Add 3+ products with sensitive data in descriptions
   - Create collections with internal/admin information

### Option B: Mock Website (Quick Setup)
1. **Host Mock Site:**
   - Use `mock-shopify-vulnerable.html` as index page
   - Serve `products.json` and `collections.json` at respective endpoints
   - Can use simple HTTP server: `python -m http.server 8000`

## 🔍 Expected Vulnerabilities Our Plugin Will Detect

| Vulnerability Type | Count | Risk Level | Detection Method |
|-------------------|-------|------------|------------------|
| **Hardcoded API Keys** | 8+ secrets | 🔴 CRITICAL | Regex pattern matching |
| **JSON Data Exposure** | 3+ endpoints | 🟡 MEDIUM | Endpoint enumeration |
| **Open Redirects** | 4+ parameters | 🟠 HIGH | Parameter testing |
| **Information Disclosure** | Multiple | 🟡 MEDIUM | Content analysis |

## 🧪 Testing Commands

### Manual Vulnerability Verification
```bash
# Test 1: Check for hardcoded secrets
curl -s "https://your-demo-store.myshopify.com/" | grep -i "api_key\|secret\|token"

# Test 2: Check JSON endpoint exposure  
curl -s "https://your-demo-store.myshopify.com/products.json" | jq '.products[] | select(.body_html | contains("email"))'

# Test 3: Test open redirect
curl -I "https://your-demo-store.myshopify.com/?redirect=https://evil-site.com"

# Test 4: Check collections exposure
curl -s "https://your-demo-store.myshopify.com/collections.json" | jq '.collections[] | select(.body_html | contains("ADMIN"))'
```

### Run Our Security Scanner
```bash
# Navigate to scanner directory
cd c:\Users\raul\Documents\GitHub\RegTech\backendnew

# Build scanner if needed
go build -o build/scanner.exe ./cmd/scanner

# Run scan against your demo store
./build/scanner.exe -target "your-demo-store.myshopify.com" -script "shopify_security_check.lua"
```

## 📊 Expected Scanner Results

### Shopify Detection
```
✅ Shopify Store Detected: Domain/Header/Asset analysis
Detection Reason: "Shopify domain detected" or "Shopify headers detected"
```

### Security Issues Found
```
🔴 CRITICAL: 8+ hardcoded secrets detected
- shopify_api_key patterns
- shopify_access_token patterns  
- Third-party API keys (Stripe, Mailchimp, etc.)

🟠 HIGH: 4+ open redirect vulnerabilities
- redirect parameter
- return_to parameter
- next parameter
- callback parameter

🟡 MEDIUM: 3+ JSON endpoints with sensitive data
- products.json: Customer emails, internal notes
- collections.json: Admin-only information
- Exposed unpublished products
```

### Compliance Assessment
```
Security Score: < 50% (CRITICAL)
Risk Level: CRITICAL
Compliance Issues: 
- Hardcoded secrets in client-side code
- Sensitive data exposed via JSON endpoints
- Open redirect vulnerabilities present
```

## 🎤 Demo Script for Presentation

### 1. Introduction (2 minutes)
```
"Today I'll demonstrate how RegTech detects Shopify security misconfigurations. 
We've created an intentionally vulnerable Shopify store to showcase our capabilities."
```

### 2. Manual Vulnerability Discovery (3 minutes)
```bash
# Show hardcoded secrets in page source
curl -s "https://regtech-demo.myshopify.com/" | grep -A5 -B5 "api_key"

# Show sensitive data in products
curl -s "https://regtech-demo.myshopify.com/products.json" | jq '.products[0].body_html'

# Demonstrate open redirect
echo "Testing: https://regtech-demo.myshopify.com/?redirect=https://evil-site.com"
curl -I "https://regtech-demo.myshopify.com/?redirect=https://evil-site.com"
```

### 3. RegTech Scanner Analysis (2 minutes)
```bash
# Run comprehensive scan
./scanner -target "regtech-demo.myshopify.com" -script "shopify_security_check.lua" -verbose

# Show specific findings
echo "Scanner detected:"
echo "- Shopify store identification: ✅"
echo "- Hardcoded secrets: 8+ found"  
echo "- JSON exposure: 3+ endpoints"
echo "- Open redirects: 4+ parameters"
echo "- Security score: 35% (CRITICAL)"
```

### 4. Business Impact (2 minutes)
```
"These vulnerabilities could lead to:
- Customer data breaches (GDPR violations)
- Account takeovers via leaked API keys  
- Phishing attacks through open redirects
- Competitive intelligence gathering
- Regulatory compliance failures"
```

## 🛠️ Troubleshooting

### Scanner Not Detecting Shopify Store
- Check domain patterns in script
- Verify HTTP responses contain Shopify indicators
- Add debug logging to `is_shopify_store()` function

### No Secrets Found
- Verify theme snippets are properly added
- Check JavaScript is not minified/obfuscated
- Test regex patterns against known secret formats

### Open Redirects Not Working
- Ensure redirect handling JavaScript is active
- Test different parameter combinations
- Check for Content Security Policy blocking

### JSON Endpoints Empty
- Verify products are published (for products.json)
- Check collection rules and product associations
- Confirm JSON endpoints are accessible without auth

## 📈 Extending the Demo

### Additional Vulnerabilities to Add
1. **XSS via Search Parameters**
2. **CSRF on Form Submissions** 
3. **SQL Injection in Custom Apps**
4. **Missing Security Headers**
5. **Weak Session Management**

### Advanced Testing
```bash
# Batch scan multiple stores
./scanner -batch -input shopify_stores.txt -script shopify_security_check.lua

# Export results to compliance report
./scanner -target demo.myshopify.com -output json -report compliance
```

## 🎯 Key Demo Talking Points

1. **Automated Detection**: "Our scanner automatically identifies Shopify stores and applies platform-specific security checks"

2. **Real-World Relevance**: "These aren't theoretical issues - we're testing actual misconfigurations we see in production"

3. **Compliance Integration**: "Results map directly to compliance frameworks like SOC2, ISO27001, and GDPR requirements"

4. **Actionable Remediation**: "Each finding includes specific remediation steps and business impact assessment"

5. **Continuous Monitoring**: "This scan can run continuously to catch new vulnerabilities as stores evolve"

## ✅ Success Metrics

After running the demo, you should achieve:
- ✅ 100% Shopify store detection rate
- ✅ 8+ hardcoded secrets found
- ✅ 3+ JSON endpoint exposures detected  
- ✅ 4+ open redirect vulnerabilities confirmed
- ✅ Security score < 50% (demonstrating critical issues)
- ✅ Clear compliance assessment with actionable recommendations

---

*Remember: This is a controlled security testing environment. All vulnerabilities are intentional and should never be deployed to production systems.*