// MongoDB initialization script with vulnerable data

// Switch to vulnerable_app database
db = db.getSiblingDB('vulnerable_app');

// Create users collection with weak data
db.users.insertMany([
    {
        _id: ObjectId(),
        username: "admin",
        password: "admin123", // Plain text password (vulnerable)
        email: "admin@vulnerable.local",
        role: "admin",
        apiKey: "sk_live_vulnerable_key_123",
        createdAt: new Date()
    },
    {
        _id: ObjectId(),
        username: "user1",
        password: "password", // Weak password (vulnerable)
        email: "user1@vulnerable.local",
        role: "user",
        personalInfo: {
            ssn: "123-45-6789",
            creditCard: "4111-1111-1111-1111",
            address: "123 Vulnerable St, Insecure City"
        },
        createdAt: new Date()
    },
    {
        _id: ObjectId(),
        username: "guest",
        password: "guest", // Default password (vulnerable)
        email: "guest@vulnerable.local",
        role: "guest",
        createdAt: new Date()
    }
]);

// Create sensitive documents collection
db.secrets.insertMany([
    {
        _id: ObjectId(),
        type: "api_key",
        value: "AIzaSyDemoKey123456789abcdef",
        service: "google_maps",
        owner: "admin"
    },
    {
        _id: ObjectId(),
        type: "database_password",
        value: "super_secret_db_password_123",
        service: "production_db",
        owner: "admin"
    },
    {
        _id: ObjectId(),
        type: "private_key",
        value: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...",
        service: "ssl_certificate",
        owner: "admin"
    }
]);

// Create logs collection
db.access_logs.insertMany([
    {
        _id: ObjectId(),
        timestamp: new Date(),
        ip: "192.168.1.100",
        user: "admin",
        action: "login",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    },
    {
        _id: ObjectId(),
        timestamp: new Date(),
        ip: "10.0.0.50",
        user: "user1",
        action: "data_access",
        userAgent: "curl/7.68.0"
    }
]);

// Create configuration collection with sensitive data
db.config.insertMany([
    {
        _id: ObjectId(),
        key: "smtp_password",
        value: "smtp_secret_123",
        environment: "production"
    },
    {
        _id: ObjectId(),
        key: "encryption_key",
        value: "this_is_a_weak_encryption_key",
        environment: "production"
    },
    {
        _id: ObjectId(),
        key: "jwt_secret",
        value: "jwt_secret_key_vulnerable",
        environment: "production"
    }
]);

print("Vulnerable MongoDB data initialized successfully!");
