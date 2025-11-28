#!/bin/bash
# BULLETPROOF DEPLOYMENT SCRIPT
# This script runs on the Load Balancer and deploys everything

set -e  # Exit on any error

echo "========================================="
echo "  3-Tier Infrastructure Deployment"
echo "========================================="
echo ""

# Function to deploy with retry logic
deploy_with_retry() {
    local server_ip=$1
    local server_name=$2
    local install_cmd=$3
    local max_attempts=3
    local attempt=1
    
    echo "→ Deploying $server_name ($server_ip)..."
    
    while [ $attempt -le $max_attempts ]; do
        echo "  Attempt $attempt/$max_attempts..."
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$server_ip "$install_cmd" 2>&1 | tee /tmp/deploy_${server_ip}.log; then
            echo "  ✓ $server_name deployed successfully!"
            return 0
        else
            echo "  ✗ Attempt $attempt failed, retrying..."
            attempt=$((attempt + 1))
            sleep 5
        fi
    done
    
    echo "  ✗ $server_name deployment FAILED after $max_attempts attempts"
    return 1
}

# Web Server installation command
WEB_INSTALL='
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y nginx
echo "<h1>Web Server - $(hostname)</h1><p>3-Tier Infrastructure Demo</p>" | sudo tee /var/www/html/index.html
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx --no-pager
'

# App Server installation command  
APP_INSTALL='
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2
mkdir -p /opt/app
cd /opt/app
cat > app.js << "EOF"
const http = require("http");
const os = require("os");
const server = http.createServer((req, res) => {
    res.writeHead(200, {"Content-Type": "application/json"});
    res.end(JSON.stringify({
        message: "Hello from " + os.hostname(),
        timestamp: new Date().toISOString(),
        hostname: os.hostname()
    }));
});
server.listen(3000, () => console.log("Server running on port 3000"));
EOF
pm2 start app.js --name backend
pm2 save
pm2 startup systemd -u ubuntu --hp /home/ubuntu | tail -1 | bash || true
pm2 list
'

# DB Server installation command
DB_INSTALL='
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y postgresql postgresql-contrib
echo "listen_addresses = '\''*'\''" | sudo tee -a /etc/postgresql/14/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/14/main/pg_hba.conf
sudo systemctl enable postgresql
sudo systemctl restart postgresql
sudo systemctl status postgresql --no-pager
'

# DB Master additional setup
DB_MASTER_SETUP='
sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD '\''securepass'\'';" 2>/dev/null || echo "User exists"
sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser;" 2>/dev/null || echo "Database exists"
sudo -u postgres psql -c "\l"
'

echo "[1/6] Deploying Web Server 1..."
deploy_with_retry "10.0.2.3" "Web Server 1" "$WEB_INSTALL"

echo ""
echo "[2/6] Deploying Web Server 2..."
deploy_with_retry "10.0.2.2" "Web Server 2" "$WEB_INSTALL"

echo ""
echo "[3/6] Deploying App Server 1..."
deploy_with_retry "10.0.3.2" "App Server 1" "$APP_INSTALL"

echo ""
echo "[4/6] Deploying App Server 2..."
deploy_with_retry "10.0.3.3" "App Server 2" "$APP_INSTALL"

echo ""
echo "[5/6] Deploying DB Master..."
deploy_with_retry "10.0.4.2" "DB Master" "$DB_INSTALL"
echo "  → Setting up database..."
ssh -o StrictHostKeyChecking=no ubuntu@10.0.4.2 "$DB_MASTER_SETUP"

echo ""
echo "[6/6] Deploying DB Replica..."
deploy_with_retry "10.0.4.3" "DB Replica" "$DB_INSTALL"

echo ""
echo "========================================="
echo "  ✓ DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "Verification:"
echo "  - Web Servers: curl http://localhost (from LB)"
echo "  - App Servers: curl http://10.0.3.2:3000"
echo "  - Database: nc -zv 10.0.4.2 5432"
echo ""
