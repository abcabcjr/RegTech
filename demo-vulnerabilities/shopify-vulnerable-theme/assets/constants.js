// 🔴 VULNERABILITY: JavaScript constants with exposed secrets
window.THEME_CONSTANTS = {
  // Shop configuration
  SHOP_ID: '12345678901234567890',
  SHOP_DOMAIN: 'demo-vulnerable.myshopify.com',
  
  // API endpoints and keys
  API_BASE_URL: 'https://{{ shop.domain }}/api',
  STOREFRONT_ACCESS_TOKEN: 'storefront_demo_vulnerable_token_abc123456789',
  ADMIN_API_KEY: 'admin_demo_vulnerable_api_key_xyz789012345',
  CHECKOUT_API_KEY: 'checkout_demo_vulnerable_key_def456789012',
  
  // Webhook configuration  
  WEBHOOK_ENDPOINTS: {
    orders: 'https://backend-vulnerable-demo.com/webhooks/orders',
    customers: 'https://backend-vulnerable-demo.com/webhooks/customers',
    inventory: 'https://backend-vulnerable-demo.com/webhooks/inventory'
  },
  WEBHOOK_SECRETS: {
    orders: 'whsec_orders_demo_vulnerable_secret_123',
    customers: 'whsec_customers_demo_vulnerable_secret_456', 
    inventory: 'whsec_inventory_demo_vulnerable_secret_789'
  },
  
  // Third-party integrations
  INTEGRATIONS: {
    stripe: {
      public_key: 'pk_live_demo_stripe_vulnerable_public_key_12345',
      webhook_secret: 'whsec_demo_stripe_vulnerable_webhook_abc123'
    },
    paypal: {
      client_id: 'demo_paypal_vulnerable_client_id_xyz789',
      client_secret: 'demo_paypal_vulnerable_client_secret_abc456'
    },
    mailchimp: {
      api_key: 'demo123456789abcdef-us1',
      list_id: 'demo_vulnerable_mailchimp_list_123456'
    },
    klaviyo: {
      public_key: 'pk_demo_klaviyo_vulnerable_public_key_xyz',
      private_key: 'pk_demo_klaviyo_vulnerable_private_key_abc'
    }
  },
  
  // Analytics and tracking
  ANALYTICS: {
    google_analytics_id: 'UA-12345678-1',
    google_tag_manager_id: 'GTM-DEMO123',
    facebook_pixel_id: '1234567890123456',
    mixpanel_token: 'demo_mixpanel_vulnerable_token_123456789',
    segment_write_key: 'demo_segment_vulnerable_write_key_abcdefg',
    hotjar_id: '1234567'
  },
  
  // Internal system configuration
  INTERNAL: {
    database_host: 'db-vulnerable-demo.internal.com',
    redis_host: 'redis-vulnerable-demo.internal.com', 
    elasticsearch_url: 'https://es-vulnerable-demo.internal.com:9200',
    admin_panel_url: 'https://admin-vulnerable-demo.internal.com',
    staging_api_key: 'staging_demo_vulnerable_api_key_internal_123'
  },
  
  // Customer service and support
  SUPPORT: {
    zendesk_api_key: 'zendesk_demo_vulnerable_api_key_support_456',
    intercom_app_id: 'demo_intercom_vulnerable_app_id_789',
    freshdesk_api_key: 'freshdesk_demo_vulnerable_api_key_xyz123'
  }
};

// 🔴 Additional vulnerable constants for comprehensive testing
window.DEVELOPMENT_CONFIG = {
  // Development and staging secrets
  dev_api_key: 'dev_demo_vulnerable_api_key_development_123',
  staging_secret: 'staging_demo_vulnerable_secret_test_456',
  test_webhook_url: 'https://webhook-test-vulnerable-demo.com/test',
  
  // Debug flags that expose information
  debug_mode: true,
  log_api_calls: true,
  expose_errors: true,
  
  // Development database credentials
  dev_database: {
    host: 'localhost',
    username: 'shop_dev_user',
    password: 'dev_vulnerable_password_123',
    database: 'shopify_vulnerable_dev_db'
  }
};

// 🔴 Vulnerable utility functions
window.VULNERABLE_UTILS = {
  // Function that logs sensitive data
  logConfig: function() {
    console.group('🔴 THEME CONFIGURATION (EXPOSED)');
    console.log('Shop ID:', window.THEME_CONSTANTS.SHOP_ID);
    console.log('API Keys:', window.THEME_CONSTANTS.ADMIN_API_KEY);
    console.log('Webhook Secrets:', window.THEME_CONSTANTS.WEBHOOK_SECRETS);
    console.log('Integration Keys:', window.THEME_CONSTANTS.INTEGRATIONS);
    console.groupEnd();
  },
  
  // Function that makes API calls with exposed tokens
  testApiConnection: function() {
    console.log('🔴 Testing API connection with exposed token...');
    
    fetch(window.THEME_CONSTANTS.API_BASE_URL + '/products.json', {
      headers: {
        'X-Shopify-Storefront-Access-Token': window.THEME_CONSTANTS.STOREFRONT_ACCESS_TOKEN,
        'Authorization': 'Bearer ' + window.THEME_CONSTANTS.ADMIN_API_KEY
      }
    }).then(function(response) {
      console.log('API Response Status:', response.status);
    }).catch(function(error) {
      console.log('Expected API error for demo:', error);
    });
  },
  
  // Function that exposes customer data
  exposeCustomerData: function() {
    // Simulated customer data for demo
    console.group('🔴 CUSTOMER DATA EXPOSED');
    console.log('Customer ID:', 'demo_customer_123456789');
    console.log('Email:', 'customer@vulnerable-demo.com');
    console.log('Name:', 'Demo Customer');
    console.log('Phone:', '+1-555-0123');
    console.log('Total Spent:', '$1,234.56');
    console.log('Orders Count:', '15');
    console.groupEnd();
  }
};

// Auto-execute vulnerable functions for demonstration
console.log('🔴 THEME CONSTANTS LOADED - VULNERABILITIES ACTIVE');
console.log('Available vulnerable functions:');
console.log('- VULNERABLE_UTILS.logConfig()');
console.log('- VULNERABLE_UTILS.testApiConnection()'); 
console.log('- VULNERABLE_UTILS.exposeCustomerData()');

// Auto-log configuration on load
setTimeout(function() {
  window.VULNERABLE_UTILS.logConfig();
}, 1000);

// Export to global scope for easy access
window.shopifyVulnerableConfig = window.THEME_CONSTANTS;
window.shopifyVulnerableUtils = window.VULNERABLE_UTILS;