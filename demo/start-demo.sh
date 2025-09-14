#!/bin/bash

# Vulnerable Services Demo Environment Startup Script

echo "🚨 Starting Vulnerable Services Demo Environment"
echo "⚠️  WARNING: This contains intentionally vulnerable services!"
echo "   Only use in isolated test environments."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed or not in PATH."
    exit 1
fi

echo "🐳 Starting Docker containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

echo ""
echo "✅ Vulnerable services are now running!"
echo ""
echo "🌐 Web Interface: http://localhost:8081"
echo "🔒 HTTPS (expired cert): https://localhost:8443"
echo ""
echo "📋 Service Status:"

# Check service status
services=(
    "localhost:8081:HTTP Web Server"
    "localhost:8443:HTTPS Web Server (expired cert)"
    "localhost:25:SMTP Mail Server"
    "localhost:3306:MySQL Database"
    "localhost:21:FTP Server"
    "localhost:2222:SSH Server"
    "localhost:6379:Redis"
    "localhost:27017:MongoDB"
    "localhost:9200:Elasticsearch"
    "localhost:11211:Memcached"
    "localhost:389:LDAP Server"
    "localhost:53:DNS Server"
    "localhost:161:SNMP Service"
    "localhost:23:Telnet Server"
    "localhost:5901:VNC Server"
)

for service in "${services[@]}"; do
    IFS=':' read -r host port name <<< "$service"
    if nc -z "$host" "$port" 2>/dev/null; then
        echo "✅ $name ($host:$port)"
    else
        echo "❌ $name ($host:$port) - Not responding"
    fi
done

echo ""
echo "🛠️  Quick Test Commands:"
echo "   nmap -sS -sV localhost                    # Port scan"
echo "   curl http://localhost:8081                # Web server"
echo "   mysql -h localhost -u root -proot         # MySQL (password: root)"
echo "   redis-cli -h localhost                    # Redis"
echo "   mongo localhost:27017                     # MongoDB"
echo ""
echo "📖 See README.md for detailed testing instructions"
echo ""
echo "🛑 To stop: docker-compose down"
echo "🗑️  To cleanup: docker-compose down -v && docker system prune -f"
