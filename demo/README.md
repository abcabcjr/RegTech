# Vulnerable Services Demo Environment

⚠️ **WARNING: This environment contains intentionally vulnerable services for security testing purposes only. Do NOT expose these services to the internet or use in production environments.**

## Overview

This Docker Compose setup provides a comprehensive vulnerable environment for security scanning and penetration testing exercises. It includes various services with intentional security misconfigurations, weak credentials, and exposed sensitive data.

## Quick Start

1. **Start the environment:**
   ```bash
   docker-compose up -d
   ```

2. **Access the web interface:**
   - HTTP: http://localhost:8081
   - HTTPS: https://localhost:8443 (expired certificate)

3. **Stop the environment:**
   ```bash
   docker-compose down
   ```

## Vulnerable Services

### 🌐 Web Server (Nginx)
- **Ports:** 8081 (HTTP), 8443 (HTTPS)
- **Vulnerabilities:**
  - Expired SSL certificate (dated 2023-01-01)
  - Weak SSL configuration (supports TLS 1.0/1.1)
  - Directory listing enabled
  - Exposed backup files (.bak)
  - Git files accessible
  - Server status page exposed
- **Test Commands:**
  ```bash
  curl -k https://localhost:8443
  curl http://localhost:8081/server-info
  curl http://localhost:8081/backup.sql.bak
  ```

### 📧 SMTP Server (Postfix)
- **Ports:** 25, 587, 993
- **Vulnerabilities:**
  - Weak authentication
  - Open relay potential
  - Default credentials
- **Credentials:** admin:weakpassword123
- **Test Commands:**
  ```bash
  telnet localhost 25
  nmap -p 25 --script smtp-enum-users localhost
  ```

### 🗄️ MySQL Database
- **Port:** 3306
- **Vulnerabilities:**
  - Weak passwords
  - Insecure configuration
  - Weak authentication methods
  - Plain text passwords in database
  - Excessive user privileges
- **Credentials:**
  - Root: root:root
  - Admin: admin:admin123
  - Webapp: webapp:webapp123
  - Backup: backup:backup
- **Test Commands:**
  ```bash
  mysql -h localhost -u root -p
  mysql -h localhost -u admin -padmin123 -e "SHOW DATABASES;"
  ```

### 📁 FTP Server
- **Port:** 21
- **Vulnerabilities:**
  - Weak authentication
  - Exposed sensitive files
- **Credentials:** ftpuser:ftppass123
- **Test Commands:**
  ```bash
  ftp localhost
  nmap -p 21 --script ftp-anon localhost
  ```

### 🔐 SSH Server
- **Port:** 2222
- **Vulnerabilities:**
  - Weak password authentication
  - Root login enabled
  - Weak ciphers and MACs
  - Empty passwords allowed
- **Credentials:** sshuser:weakpassword123
- **Test Commands:**
  ```bash
  ssh -p 2222 sshuser@localhost
  nmap -p 2222 --script ssh-auth-methods localhost
  ```

### 🔴 Redis (No Authentication)
- **Port:** 6379
- **Vulnerabilities:**
  - No authentication required
  - Protected mode disabled
- **Test Commands:**
  ```bash
  redis-cli -h localhost
  redis-cli -h localhost INFO
  ```

### 🍃 MongoDB (No Authentication)
- **Port:** 27017
- **Vulnerabilities:**
  - No authentication required
  - Sensitive data exposed
- **Test Commands:**
  ```bash
  mongo localhost:27017
  mongo localhost:27017/vulnerable_app --eval "db.users.find()"
  ```

### 🔍 Elasticsearch (No Authentication)
- **Ports:** 9200, 9300
- **Vulnerabilities:**
  - No authentication
  - X-Pack security disabled
- **Test Commands:**
  ```bash
  curl http://localhost:9200/_cluster/health
  curl http://localhost:9200/_cat/indices
  ```

### 💾 Memcached (No Authentication)
- **Port:** 11211
- **Vulnerabilities:**
  - No authentication
  - Exposed to network
- **Test Commands:**
  ```bash
  telnet localhost 11211
  echo "stats" | nc localhost 11211
  ```

### 📋 LDAP Server
- **Ports:** 389, 636
- **Vulnerabilities:**
  - Weak passwords
  - Anonymous bind allowed
- **Credentials:**
  - Admin: cn=admin,dc=vulnerable,dc=local:admin123
  - Readonly: readonly:readonly123
- **Test Commands:**
  ```bash
  ldapsearch -x -H ldap://localhost:389 -b "dc=vulnerable,dc=local"
  ```

### 🌍 DNS Server (BIND9)
- **Port:** 53
- **Vulnerabilities:**
  - Zone transfer enabled
  - Recursive queries allowed
  - Version disclosure
- **Test Commands:**
  ```bash
  dig @localhost vulnerable.local AXFR
  nmap -p 53 --script dns-zone-transfer localhost
  ```

### 📊 SNMP Service
- **Port:** 161/UDP
- **Vulnerabilities:**
  - Default community string "public"
  - Information disclosure
- **Test Commands:**
  ```bash
  snmpwalk -v2c -c public localhost
  nmap -sU -p 161 --script snmp-info localhost
  ```

### 📺 Telnet Server
- **Port:** 23
- **Vulnerabilities:**
  - Unencrypted protocol
  - No authentication
- **Test Commands:**
  ```bash
  telnet localhost 23
  ```

### 🖥️ VNC Server
- **Ports:** 5901, 6901
- **Vulnerabilities:**
  - Weak password
  - Unencrypted connection
- **Password:** password123
- **Test Commands:**
  ```bash
  vncviewer localhost:5901
  ```

## Security Testing Scenarios

### Network Scanning
```bash
# Port scanning
nmap -sS -sV -p- localhost
nmap -sU --top-ports 1000 localhost

# Service enumeration
nmap -sC -sV localhost

# Vulnerability scanning
nmap --script vuln localhost
```

### Service-Specific Tests
```bash
# Web vulnerabilities
nikto -h http://localhost:8081
dirb http://localhost:8081

# SSL/TLS testing
sslscan localhost:8443
testssl.sh localhost:8443

# Database testing
sqlmap -u "http://localhost:8081/login" --forms --dbs

# SNMP enumeration
snmp-check localhost
```

### Authentication Testing
```bash
# Brute force attacks
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://localhost:2222
hydra -l admin -P /usr/share/wordlists/rockyou.txt ftp://localhost:21

# Default credentials testing
# Try common username/password combinations on all services
```

## RegTech Scanner Integration

This environment is designed to work with your RegTech scanning tools. You can test various Lua scripts against these services:

### Example RegTech Scans
```bash
# Run your scanner against the vulnerable environment
./scanner -target localhost -ports 1-65535

# Test specific services
./scanner -target localhost -service http
./scanner -target localhost -service ssh
./scanner -target localhost -service database
```

### Lua Script Testing
The following RegTech Lua scripts should detect vulnerabilities in this environment:
- `port_scan.lua` - Detect open ports
- `service_detector.lua` - Identify running services
- `ssl_checklist.lua` - Check SSL/TLS configuration
- `weak_service_check.lua` - Detect weak service configurations
- `security_check.lua` - General security assessment

## Network Information

- **Network:** 172.20.0.0/16
- **Services accessible on:** localhost (127.0.0.1)
- **Internal container communication:** Available via service names

## Cleanup

To completely remove the environment:
```bash
docker-compose down -v
docker system prune -f
```

## Security Notes

1. **Never expose these services to the internet**
2. **Use only in isolated test environments**
3. **Contains real-looking but fake sensitive data**
4. **All passwords and keys are intentionally weak**
5. **Services are configured with maximum vulnerabilities**

## Troubleshooting

### Common Issues
- **Port conflicts:** Ensure ports 21, 23, 25, 53, 161, 389, 587, 3306, 5901, 6379, 6901, 8081, 8443, 9200, 9300, 11211, 27017 are available
- **Permission issues:** Run with `sudo` if needed
- **DNS issues:** Add `127.0.0.1 vulnerable.local` to `/etc/hosts`

### Logs
```bash
# View logs for specific service
docker-compose logs vulnerable-web
docker-compose logs vulnerable-db

# View all logs
docker-compose logs
```

## Contributing

This environment is designed for security testing. If you find additional vulnerabilities to add or improvements to make, please ensure they remain within the scope of intentional security weaknesses for educational purposes.

---

**Remember: This is a vulnerable environment by design. Use responsibly and only for authorized security testing.**
