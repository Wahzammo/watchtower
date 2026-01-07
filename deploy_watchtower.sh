#!/bin/bash

# Elitebook 820 G2 Wazuh Deployment Script
# Usage: sudo ./deploy_watchtower.sh

echo ">>> [INIT] Checking System Configuration..."

# 1. Increase Max Map Count (Critical for Wazuh Indexer/Elasticsearch)
# The default is usually too low (65530), we need 262144.
current_map_count=$(sysctl -n vm.max_map_count)
required_map_count=262144

if [ "$current_map_count" -lt "$required_map_count" ]; then
    echo ">>> [FIX] vm.max_map_count is too low ($current_map_count). Increasing to $required_map_count..."
    sysctl -w vm.max_map_count=$required_map_count
    # Make it permanent
    echo "vm.max_map_count=$required_map_count" > /etc/sysctl.d/wazuh.conf
else
    echo ">>> [OK] vm.max_map_count is set correctly."
fi

# 2. Check for Docker
if ! command -v docker &> /dev/null; then
    echo ">>> [ERROR] Docker is not installed. Please run: sudo apt install docker.io docker-compose-plugin"
    exit 1
fi

# 3. Security Warning
echo ">>> [WARN] Using default credentials (admin / SecretPassword123!). Change these in production!"

# 4. Certificate Generation (Simplified for Single Node)
# Note: For a strict setup, we would run the wazuh-certs-tool here.
# For this quick-start, we rely on the containers handling self-signed certs or
# failing gracefully to non-SSL if configured (Wazuh 4.9 enforces SSL, be aware).
# If the stack fails on SSL, we will need to run the cert generator.

# 5. Launch
echo ">>> [LAUNCH] Starting The Watchtower..."
docker compose up -d

echo ">>> [STATUS] Waiting for services to stabilize..."
sleep 10
docker compose ps

echo "---------------------------------------------------"
echo "Deployment Complete."
echo "Dashboard available at: https://<YOUR_LAPTOP_IP>"
echo "Username: admin"
echo "Password: SecretPassword123!"
echo "---------------------------------------------------"
