# 🎯 Vulnerable Shopify Theme - Installation Instructions

## 📦 Complete Theme Package Ready for Upload

This folder contains a complete, intentionally vulnerable Shopify theme that our `shopify_security_check.lua` script will detect multiple security issues in.

## 🚀 Installation Steps

### Method 1: ZIP Upload to Shopify Admin

1. **Create ZIP file:**
   ```bash
   # Navigate to the theme folder
   cd demo-vulnerabilities/shopify-vulnerable-theme
   
   # Create ZIP (exclude this README)
   zip -r ../vulnerable-shopify-theme.zip . -x "README.md"
   ```

2. **Upload to Shopify:**
   - Go to your Shopify Admin → Online Store → Themes
   - Click "Add theme" → "Upload ZIP file"
   - Select `vulnerable-shopify-theme.zip`
   - Click "Upload"

3. **Activate Theme:**
   - Click "Actions" → "Publish" on the uploaded theme

### Method 2: Individual File Upload

If ZIP upload fails, manually add files:

1. **Edit existing theme:**
   - Go to Actions → Edit Code on any theme

2. **Replace/Add files:**
   - Replace `layout/theme.liquid` with our vulnerable version
   - Add other template files to respective folders
   - Upload CSS/JS assets

## 🔍 Vulnerabilities Included

### **Critical (8+ instances):**
- Hardcoded API keys in JavaScript
- Webhook secrets in comments
- Database credentials exposed
- Third-party integration keys

### **High (4+ instances):**
- Open redirect vulnerabilities
- Unvalidated redirect parameters
- PostMessage security issues
- CSRF token bypass

### **Medium (6+ instances):**
- Information disclosure in meta tags
- Customer data exposure
- Internal configuration leaks
- Sensitive data in CSS

## 📊 Expected Scanner Results

When you run our RegTech scanner against this theme:

```bash
./scanner -target "your-demo-store.myshopify.com" -script "shopify_security_check.lua"
```

**Expected Output:**
- ✅ **Shopify Store Detected:** YES
- 🔴 **Security Score:** < 30% (CRITICAL)
- 🔴 **Hardcoded Secrets:** 15+ detected
- 🟠 **Open Redirects:** 6+ parameters vulnerable
- 🟡 **Data Exposure:** Multiple endpoints

## 🎤 Demo Script

### 1. **Show Manual Discovery (2 min)**
```bash
# View source to show hardcoded secrets
curl -s "https://your-demo.myshopify.com/" | grep -i "api_key\|secret"

# Test open redirect
curl -I "https://your-demo.myshopify.com/?redirect=https://evil-site.com"
```

### 2. **Run RegTech Scanner (2 min)**
```bash
# Comprehensive security scan
./scanner -target "your-demo.myshopify.com" -script "shopify_security_check.lua" -verbose
```

### 3. **Show Results (1 min)**
- Point out CRITICAL security score
- Highlight specific vulnerabilities found
- Explain business impact

## 🛠️ Troubleshooting

### "Invalid Theme" Error
- Ensure all required files are present:
  - `layout/theme.liquid` (required)
  - `templates/index.liquid` (required)
  - At least one other template file

### No Vulnerabilities Detected
- Check browser console for JavaScript errors
- Verify theme is active and published
- Test individual URLs manually

### ZIP Upload Fails
- Ensure ZIP doesn't contain nested folders
- Remove any `.DS_Store` or system files
- Use individual file upload method instead

## 🎯 Test URLs

After theme installation, test these URLs:

```
# Homepage with exposed secrets
https://your-demo.myshopify.com/

# Open redirect tests  
https://your-demo.myshopify.com/?redirect=https://evil-site.com
https://your-demo.myshopify.com/?return_to=http://malicious.com

# Data exposure endpoints
https://your-demo.myshopify.com/products.json
https://your-demo.myshopify.com/collections.json

# Vulnerable page
https://your-demo.myshopify.com/pages/security-demo
```

## ✅ Success Checklist

- [ ] Theme uploads without errors
- [ ] Homepage loads and displays vulnerability warnings
- [ ] Browser console shows exposed API keys
- [ ] Open redirect links work (show redirect warnings)
- [ ] JSON endpoints contain sensitive data
- [ ] RegTech scanner detects all vulnerabilities

---

**⚠️ WARNING:** This theme is intentionally vulnerable and should only be used in development/demo environments. Never use in production!