#!/bin/bash
#
# The Watchtower - Wazuh v4.14.1 Deployment Script
# Designed for: HP EliteBook 820 G2 (or similar resource-constrained hardware)
#
# Usage: sudo ./deploy_watchtower.sh
#

set -e  # Exit on any error

echo "=========================================="
echo "   The Watchtower - SIEM Deployment"
echo "   Wazuh v4.14.1 Single-Node Stack"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script must be run as root (use sudo)"
   exit 1
fi

echo -e "${GREEN}[CHECK]${NC} System Configuration..."

# 1. Verify Docker Installation
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Docker is not installed."
    echo "Install with: sudo apt install docker.io docker-compose-plugin"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Docker Compose plugin is not installed."
    echo "Install with: sudo apt install docker-compose-plugin"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Docker Engine: $(docker --version)"
echo -e "${GREEN}[OK]${NC} Docker Compose: $(docker compose version)"

# 2. System Tuning (Critical for OpenSearch)
echo ""
echo -e "${GREEN}[CHECK]${NC} System tuning for OpenSearch..."

current_map_count=$(sysctl -n vm.max_map_count)
required_map_count=262144

if [ "$current_map_count" -lt "$required_map_count" ]; then
    echo -e "${YELLOW}[FIX]${NC} vm.max_map_count is too low ($current_map_count)"
    echo "      Setting to $required_map_count..."
    sysctl -w vm.max_map_count=$required_map_count
    
    # Make permanent
    echo "vm.max_map_count=$required_map_count" > /etc/sysctl.d/99-wazuh.conf
    echo -e "${GREEN}[OK]${NC} System tuning applied (persistent across reboots)"
else
    echo -e "${GREEN}[OK]${NC} vm.max_map_count is already set correctly"
fi

# 3. Check Available Resources
echo ""
echo -e "${GREEN}[CHECK]${NC} Hardware resources..."

total_ram=$(free -g | awk '/^Mem:/{print $2}')
if [ "$total_ram" -lt 8 ]; then
    echo -e "${YELLOW}[WARN]${NC} Total RAM is ${total_ram}GB (8GB minimum recommended)"
    echo "      Wazuh may experience performance issues"
fi

available_disk=$(df -h / | awk 'NR==2 {print $4}')
echo -e "${GREEN}[OK]${NC} Available disk space: $available_disk"

# 4. Clone Wazuh Docker Repository
echo ""
echo -e "${GREEN}[DEPLOY]${NC} Cloning Wazuh Docker repository (v4.14.1)..."

WAZUH_DIR="$HOME/wazuh-docker"

if [ -d "$WAZUH_DIR" ]; then
    echo -e "${YELLOW}[WARN]${NC} Directory $WAZUH_DIR already exists"
    read -p "Remove and re-clone? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WAZUH_DIR"
    else
        echo -e "${RED}[ABORT]${NC} Deployment cancelled"
        exit 1
    fi
fi

git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.1 "$WAZUH_DIR"
cd "$WAZUH_DIR/single-node"

# 5. Verify Configuration Files
echo ""
echo -e "${GREEN}[CHECK]${NC} Verifying configuration files..."

if [ ! -f "config/certs.yml" ]; then
    echo -e "${RED}[ERROR]${NC} config/certs.yml not found"
    exit 1
fi

# Verify it's a FILE, not a directory (this was the v4.9.0 bug)
if [ -d "config/certs.yml" ]; then
    echo -e "${RED}[ERROR]${NC} config/certs.yml is a directory (broken version detected)"
    echo "      This indicates a corrupt clone. Re-clone and try again."
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Configuration files validated"

# 6. Generate SSL Certificates
echo ""
echo -e "${GREEN}[GENERATE]${NC} Creating SSL certificates..."

docker compose -f generate-indexer-certs.yml run --rm generator

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Certificate generation failed"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} SSL certificates generated"

# 7. Deploy the Stack
echo ""
echo -e "${GREEN}[LAUNCH]${NC} Starting The Watchtower..."

docker compose up -d

# 8. Wait for Services to Initialize
echo ""
echo -e "${YELLOW}[WAIT]${NC} Allowing services to initialize (30 seconds)..."
sleep 30

# 9. Health Check
echo ""
echo -e "${GREEN}[CHECK]${NC} Service health status..."

docker compose ps

# Get container status
indexer_status=$(docker compose ps wazuh.indexer --format json | jq -r '.State')
manager_status=$(docker compose ps wazuh.manager --format json | jq -r '.State')
dashboard_status=$(docker compose ps wazuh.dashboard --format json | jq -r '.State')

echo ""
if [ "$indexer_status" = "running" ] && [ "$manager_status" = "running" ] && [ "$dashboard_status" = "running" ]; then
    echo -e "${GREEN}=========================================="
    echo "   ✓ Deployment Successful!"
    echo "==========================================${NC}"
    echo ""
    echo "Dashboard URL: https://$(hostname -I | awk '{print $1}')"
    echo "Username: admin"
    echo "Password: SecretPassword"
    echo ""
    echo -e "${YELLOW}⚠️  CRITICAL: Change the default password immediately!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Access the dashboard and change credentials"
    echo "  2. Deploy Wazuh agents to monitored endpoints"
    echo "  3. Configure custom FIM rules for your assets"
    echo ""
else
    echo -e "${RED}=========================================="
    echo "   ✗ Deployment Incomplete"
    echo "==========================================${NC}"
    echo ""
    echo "Some services failed to start. Check logs with:"
    echo "  docker compose logs wazuh.indexer --tail 50"
    echo "  docker compose logs wazuh.manager --tail 50"
    echo "  docker compose logs wazuh.dashboard --tail 50"
fi

echo ""
echo "Logs location: $WAZUH_DIR/single-node"
echo "Stop services: cd $WAZUH_DIR/single-node && docker compose down"
echo ""