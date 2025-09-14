-- Create vulnerable database schema
CREATE DATABASE IF NOT EXISTS vulnerable_app;
USE vulnerable_app;

-- Create users table with weak security
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,  -- Plain text passwords (vulnerable)
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users with weak passwords
INSERT INTO users (username, password, email, role) VALUES
('admin', 'admin123', 'admin@vulnerable.local', 'admin'),
('user1', 'password', 'user1@vulnerable.local', 'user'),
('test', 'test123', 'test@vulnerable.local', 'user'),
('guest', 'guest', 'guest@vulnerable.local', 'guest'),
('root', 'toor', 'root@vulnerable.local', 'admin');

-- Create sensitive data table
CREATE TABLE sensitive_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    credit_card VARCHAR(20),
    ssn VARCHAR(11),
    api_key VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Insert sample sensitive data
INSERT INTO sensitive_data (user_id, credit_card, ssn, api_key) VALUES
(1, '4111-1111-1111-1111', '123-45-6789', 'sk_test_123456789abcdef'),
(2, '5555-5555-5555-4444', '987-65-4321', 'pk_live_abcdef123456789'),
(3, '3782-8224-6310-005', '555-44-3333', 'api_key_vulnerable_123');

-- Create logs table
CREATE TABLE access_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    endpoint VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample log data
INSERT INTO access_logs (user_id, ip_address, user_agent, endpoint) VALUES
(1, '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '/admin/dashboard'),
(2, '10.0.0.50', 'curl/7.68.0', '/api/users'),
(3, '172.16.0.10', 'Python-requests/2.25.1', '/api/sensitive-data');

-- Create a user with excessive privileges (vulnerable)
CREATE USER IF NOT EXISTS 'webapp'@'%' IDENTIFIED BY 'webapp123';
GRANT ALL PRIVILEGES ON *.* TO 'webapp'@'%' WITH GRANT OPTION;

-- Create backup user with weak password
CREATE USER IF NOT EXISTS 'backup'@'%' IDENTIFIED BY 'backup';
GRANT SELECT ON *.* TO 'backup'@'%';

FLUSH PRIVILEGES;
