# SHOPIFY JSON ENDPOINT VULNERABILITY SETUP
# Instructions for creating intentionally vulnerable product data

## Products to Create in Your Shopify Admin

### Product 1: "Demo Product with Sensitive Data"
- **Title**: "Demo Product with Customer Data Exposed"
- **Description**: Include sensitive-looking data:
  ```
  Internal Note: Customer emails collected: john@demo.com, mary@test.com
  Supplier Contact: supplier@vulnerable-demo.com
  Internal SKU: INT-VULN-001
  Cost Price: $12.50 (Markup: 300%)
  Inventory Location: Warehouse A, Section 5, Row 12
  Staff Notes: Handle with care - customer complained about privacy
  ```

### Product 2: "Internal System Test Product" 
- **Title**: "INTERNAL - System Test Product (Do Not Display)"
- **Description**:
  ```
  INTERNAL USE ONLY
  Database ID: 987654321
  Admin Email: admin@regtech-demo.myshopify.com
  Test Customer: test@customer-data.com
  Payment Gateway: Stripe Test Key pk_test_vulnerable_demo_123
  ```

### Product 3: "Unpublished Product with Secrets"
- **Title**: "Unpublished Product - Contains API Keys"
- **Status**: Leave as "Draft" (unpublished but still accessible via JSON)
- **Description**:
  ```
  API Configuration:
  - Webhook URL: https://backend-demo.com/webhook
  - Secret Key: webhook_secret_demo_vulnerable_123
  - Customer ID Range: 100001-150000
  - Order ID Range: 200001-250000
  ```

## Collections to Create

### Collection 1: "Internal Data Collection"
- **Title**: "Internal Customer Data Collection"
- **Description**: "Contains products with customer information for testing"

### Collection 2: "Admin Only Products"
- **Title**: "Admin-Only Internal Products"
- **Description**: "Products containing sensitive business data"

## How to Access the Vulnerable Endpoints

After setting up these products, the following endpoints will expose sensitive data:

1. **All Products**: `https://your-store.myshopify.com/products.json`
2. **Specific Product**: `https://your-store.myshopify.com/products/demo-product-with-sensitive-data.json`
3. **Collections**: `https://your-store.myshopify.com/collections.json`
4. **Collection Products**: `https://your-store.myshopify.com/collections/internal-data-collection/products.json`

## Expected Plugin Detection

Our `shopify_security_check.lua` script will detect:
- Sensitive keywords in product descriptions (email, admin, api, secret)
- Unpublished products accessible via JSON
- Collections containing internal data
- Products with cost/pricing information exposed
- Contact information and internal notes

## Demo Script

You can use this curl command to show the vulnerability:

```bash
# Show exposed product data
curl -s "https://your-store.myshopify.com/products.json" | jq .

# Show specific vulnerable product
curl -s "https://your-store.myshopify.com/products/demo-product-with-sensitive-data.json" | jq .
```