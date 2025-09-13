#!/usr/bin/env python3
"""
Vulnerable Shopify Mock Server for Security Testing
Serves intentionally vulnerable content to test the RegTech scanner
"""

import http.server
import socketserver
import json
import urllib.parse

PORT = 6000

class VulnerableShopifyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        query = urllib.parse.parse_qs(parsed_path.query)

        print(f"🔍 Request: {self.path}")

        if path == '/products.json':
            self.serve_vulnerable_products()
        elif path == '/customers.json':
            self.serve_vulnerable_customers()
        elif path == '/admin/orders.json':
            self.serve_vulnerable_admin_orders()
        elif path == '/debug':
            self.serve_debug_info()
        elif path.endswith('.env'):
            self.serve_env_file()
        elif path.startswith('/assets/constants.js'):
            self.serve_vulnerable_js()
        elif any(param in query for param in ['redirect', 'return_to', 'next', 'callback']):
            self.handle_redirect(query)
        else:
            self.serve_main_page()

    def serve_main_page(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Server', 'nginx/1.18.0 (Shopify)')
        self.send_header('X-Shopify-Stage', 'development')
        self.send_header('X-Shopify-Shop-Id', '12345678901234567890')
        self.end_headers()
        
        html = '''<!DOCTYPE html>
<html>
<head>
    <title>Vulnerable Shopify Demo</title>
    <meta name="shopify-api-key" content="sk_live_demo_vulnerable_12345678901234567890">
    <meta name="generator" content="Shopify">
</head>
<body>
    <h1>🔴 Vulnerable Shopify Demo Store</h1>
    <script>
        window.Shopify = {
            api_key: "sk_live_demo_vulnerable_api_key_12345678901234567890",
            secret_key: "shpss_demo_vulnerable_secret_abcdef1234567890", 
            access_token: "shpat_demo_vulnerable_token_xyz789012345678901234",
            webhook_secret: "whsec_demo_vulnerable_webhook_1234567890abcdef",
            stripe_secret: "sk_live_demo_stripe_vulnerable_secret_123456789",
            paypal_secret: "demo_paypal_vulnerable_client_secret_abc456"
        };
        console.log("🔴 EXPOSED API Key:", window.Shopify.api_key);
    </script>
    
    <p>Test endpoints:</p>
    <ul>
        <li><a href="/products.json">/products.json</a></li>
        <li><a href="/customers.json">/customers.json (CRITICAL)</a></li>
        <li><a href="/admin/orders.json">/admin/orders.json (CRITICAL)</a></li>
        <li><a href="/debug">/debug</a></li>
        <li><a href="/.env">/.env (CRITICAL)</a></li>
        <li><a href="/assets/constants.js">/assets/constants.js</a></li>
    </ul>
    
    <p>Test redirects:</p>
    <ul>
        <li><a href="?redirect=https://evil-site.com">Open Redirect</a></li>
        <li><a href="?return_to=//attacker.com">Protocol Relative</a></li>
    </ul>
    
    <div id="shopify-section-footer" class="shopify-section"></div>
</body>
</html>'''
        
        self.wfile.write(html.encode())

    def serve_vulnerable_products(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        data = {
            "products": [{
                "id": 1234567890123456789,
                "title": "Demo Product",
                "cost_price": 15.50,
                "supplier_email": "supplier@demo-vulnerable.com"
            }],
            "meta": {
                "api_key": "demo_access_token_exposed_in_json_response"
            }
        }
        
        self.wfile.write(json.dumps(data, indent=2).encode())

    def serve_vulnerable_customers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        data = {
            "customers": [{
                "id": 1111111111111111111,
                "email": "john.doe@vulnerable-demo.com",
                "first_name": "John",
                "last_name": "Doe", 
                "phone": "+1-555-0123",
                "addresses": [{
                    "address1": "123 Main St",
                    "city": "Demo City",
                    "zip": "12345"
                }]
            }],
            "warning": "🔴 CRITICAL: Customer data exposed!"
        }
        
        self.wfile.write(json.dumps(data, indent=2).encode())

    def serve_vulnerable_admin_orders(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        data = {
            "orders": [{
                "id": 3333333333333333333,
                "customer_email": "customer@vulnerable-demo.com",
                "billing_address": {"address1": "456 Oak Ave"},
                "payment_details": {
                    "last_four": "4242",
                    "transaction_id": "demo_txn_vulnerable_123456"
                }
            }],
            "warning": "🔴 CRITICAL: Admin data exposed!"
        }
        
        self.wfile.write(json.dumps(data, indent=2).encode())

    def serve_debug_info(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        debug = '''🔴 DEBUG INFO (SHOULD NOT BE PUBLIC)

API Keys:
- Private App: shppa_demo_vulnerable_private_app_xyz789
- Webhook Secret: whsec_demo_vulnerable_webhook_secret_abc123

Database:
- Host: mysql-vulnerable-demo.internal.com
- Password: demo_vulnerable_password_123

This should NEVER be publicly accessible!
'''
        
        self.wfile.write(debug.encode())

    def serve_env_file(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        env = '''SHOPIFY_API_KEY=demo_vulnerable_shopify_api_key_123456789
SHOPIFY_SECRET=demo_vulnerable_shopify_secret_abcdefghijk
DATABASE_URL=mysql://admin:demo_vulnerable_db_password@mysql.com/shop
STRIPE_SECRET_KEY=sk_live_demo_vulnerable_stripe_secret_key_123456789
'''
        
        self.wfile.write(env.encode())

    def serve_vulnerable_js(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/javascript')
        self.end_headers()
        
        js = '''window.SHOPIFY_CONFIG = {
    api_key: "sk_live_demo_vulnerable_12345678901234567890",
    secret_key: "shpss_demo_vulnerable_secret_abcdef1234567890",
    stripe_key: "sk_live_demo_stripe_vulnerable_secret_xyz789"
};
console.log("🔴 EXPOSED:", window.SHOPIFY_CONFIG.api_key);
'''
        
        self.wfile.write(js.encode())

    def handle_redirect(self, query):
        redirect_url = None
        for param in ['redirect', 'return_to', 'next', 'callback']:
            if param in query:
                redirect_url = query[param][0]
                break
        
        if redirect_url:
            print(f"🔴 OPEN REDIRECT: {redirect_url}")
            self.send_response(302)
            self.send_header('Location', redirect_url)
            self.end_headers()

def main():
    print("🔴 Starting Vulnerable Shopify Mock Server")
    print(f"🌐 Server: http://localhost:{PORT}")
    print("🎯 Test: ./scanner.exe --target localhost:6000 --script shopify_security_check.lua")
    
    with socketserver.TCPServer(("", PORT), VulnerableShopifyHandler) as httpd:
        print("🚀 Server running!")
        httpd.serve_forever()

if __name__ == "__main__":
    main()