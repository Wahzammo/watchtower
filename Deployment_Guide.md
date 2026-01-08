# The Watchtower - Complete Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying Wazuh v4.14.1 as "The Watchtower" - a portable, production-ready SIEM solution for SMBs, MSPs, or personal security labs.

**Estimated Time:** 15-20 minutes (including system prep)

---

## Pre-Deployment Checklist

### Hardware Requirements

| Component | Minimum | Recommended | The Watchtower (Reference) |
|-----------|---------|-------------|---------------------------|
| **CPU** | 2 cores | 4 cores | Intel i7-5600U (2C/4T) |
| **RAM** | 8GB | 16GB | 16GB DDR3 |
| **Storage** | 50GB | 100GB SSD | 256GB SATA SSD |
| **Network** | 100Mbps | 1Gbps | Gigabit Ethernet |

### Software Requirements

- **OS:** Ubuntu 20.04+ / Debian 11+ / Any modern Linux
- **Docker:** Version 20.10+
- **Docker Compose:** Plugin version (v2.x)
- **Git:** For cloning official repository

### Network Requirements

- **Static IP:** Recommended for agent connectivity
- **Open Ports:**
  - `1514/tcp`: Agent communication (Wazuh Manager)
  - `443/tcp` or `5601/tcp`: Dashboard access
  - `9200/tcp`: Indexer API (internal)

---

## Installation Steps

### Step 1: System Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y \
    docker.io \
    docker-compose-plugin \
    git \
    curl \
    jq

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Apply OpenSearch tuning (CRITICAL)
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-wazuh.conf

# Verify Docker installation
docker --version
docker compose version
```

### Step 2: Clone Wazuh Repository

```bash
# Clone official Wazuh Docker repo (v4.14.1)
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.1

# Navigate to single-node deployment
cd wazuh-docker/single-node
```

**⚠️ CRITICAL:** Always specify `-b v4.14.1` or later. Earlier versions (v4.9.0) have broken certificate generation.

### Step 3: Review Configuration

```bash
# Inspect default configuration
cat docker-compose.yml

# Verify certificate template exists (should be a FILE, not a directory)
file config/certs.yml
```

**Expected output:** `config/certs.yml: YAML document text`

### Step 4: Generate SSL Certificates

```bash
# Run certificate generator
docker compose -f generate-indexer-certs.yml run --rm generator

# Verify certificates were created
ls -lh config/wazuh_indexer_ssl_certs/
ls -lh config/wazuh_dashboard_ssl_certs/
```

You should see `.pem` and `.key` files (NOT directories).

### Step 5: Deploy The Stack

```bash
# Start all services
docker compose up -d

# Verify all containers are running
docker compose ps
```

**Expected output:** All three services (indexer, manager, dashboard) should show "Up" status.

### Step 6: Wait for Initialization

The first startup takes 1-2 minutes as services:
- Initialize databases
- Load security configurations
- Establish SSL connections

```bash
# Monitor initialization
docker compose logs -f

# Press Ctrl+C to exit logs once you see:
# wazuh.dashboard | Server running at https://0.0.0.0:5601
```

### Step 7: Access the Dashboard

Open your browser and navigate to:
```
https://<your-server-ip>
```

**Default Credentials:**
- **Username:** `admin`
- **Password:** `SecretPassword`

**⚠️ SECURITY:** Change this password immediately in production environments.

---

## Post-Deployment Configuration

### 1. Change Default Password

```bash
# Access the indexer container
docker exec -it single-node-wazuh.indexer-1 bash

# Run password reset tool
export JAVA_HOME=/usr/share/wazuh-indexer/jdk
bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh -p <NEW_PASSWORD>

# Copy the hash, then edit internal users
vi /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/internal_users.yml

# Find the admin user and replace the hash
# Save and exit, then reload security config

bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/ \
  -icl -nhnv \
  -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
  -cert /usr/share/wazuh-indexer/config/certs/admin.pem \
  -key /usr/share/wazuh-indexer/config/certs/admin-key.pem
```

### 2. Configure Firewall

```bash
# Allow agent connections
sudo ufw allow 1514/tcp comment 'Wazuh Agent Communication'

# Allow dashboard access (restrict to internal network in production)
sudo ufw allow 443/tcp comment 'Wazuh Dashboard'

# Enable firewall
sudo ufw enable
```

### 3. Set Static IP (Ubuntu/Netplan)

Edit `/etc/netplan/01-netcfg.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:  # Replace with your interface name
      dhcp4: no
      addresses:
        - 192.168.0.200/24
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

Apply configuration:
```bash
sudo netplan apply
```

---

## Agent Deployment

### Ubuntu/Debian Agent Installation

```bash
# On the endpoint to monitor
curl -so wazuh-agent.deb \
  https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.1-1_amd64.deb

# Install with manager IP
sudo WAZUH_MANAGER='192.168.0.200' dpkg -i wazuh-agent.deb

# Start agent
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Verify connection
sudo systemctl status wazuh-agent
```

### Windows Agent Installation

1. Download agent from: `https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.1-1.msi`
2. Run installer and enter manager IP: `192.168.0.200`
3. Verify in Dashboard: **Agents** → Should show new agent

---

## Maintenance & Operations

### Daily Health Checks

```bash
# Check service status
docker compose ps

# View recent logs
docker compose logs --tail 100

# Check disk usage
df -h
docker system df
```

### Backup Procedures

```bash
# Stop services
docker compose down

# Backup configuration and certs
tar -czf watchtower-backup-$(date +%F).tar.gz \
  config/ \
  docker-compose.yml

# Backup Wazuh data (if persistent volumes configured)
docker run --rm \
  -v single-node_wazuh-indexer-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/wazuh-data-$(date +%F).tar.gz /data
```

### Updates

```bash
# Pull latest images (for your version)
docker compose pull

# Restart with new images
docker compose down && docker compose up -d
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check specific service logs
docker compose logs wazuh.indexer --tail 50
docker compose logs wazuh.manager --tail 50
docker compose logs wazuh.dashboard --tail 50

# Common issues:
# 1. vm.max_map_count too low → see Step 1
# 2. Port conflicts → check `sudo netstat -tlnp | grep -E '(443|1514|9200)'`
# 3. Insufficient RAM → check `free -h`
```

### Dashboard Shows "Application Not Found"

This usually means the Manager API isn't configured properly.

```bash
# Verify manager is running
docker compose ps wazuh.manager

# Check API endpoint
docker exec -it single-node-wazuh.manager-1 curl -k https://localhost:55000

# Should return: {"title": "Unauthorized"...}  (Good - API is up)
```

### Agents Not Connecting

```bash
# On manager, check for agent registration
docker exec -it single-node-wazuh.manager-1 /var/ossec/bin/manage_agents -l

# Verify firewall allows port 1514
sudo ufw status | grep 1514

# Check manager logs for connection attempts
docker exec -it single-node-wazuh.manager-1 tail -f /var/ossec/logs/ossec.log
```

---

## Production Deployment Considerations

### Security Hardening

1. **Change all default passwords**
2. **Enable SSL/TLS with proper certificates** (not self-signed)
3. **Restrict dashboard access** to internal network only
4. **Enable audit logging** for compliance
5. **Configure log retention** policies based on requirements

### High Availability

For production environments requiring HA:
- Deploy multi-node Wazuh cluster (3+ indexer nodes)
- Use external load balancer for dashboard
- Configure shared storage for manager cluster
- See: [Wazuh HA Documentation](https://documentation.wazuh.com/current/deployment-options/index.html)

### Integration

- **SIEM:** Forward alerts to Splunk, QRadar, or ArcSight
- **Ticketing:** Integrate with Jira, ServiceNow via webhooks
- **Notifications:** Slack, PagerDuty, email alerts
- **Threat Intel:** VirusTotal, AlienVault OTX feeds

---

## Success Criteria

Your deployment is successful when:

- ✅ All three containers show "Up" status
- ✅ Dashboard loads at `https://<server-ip>`
- ✅ You can login with admin credentials
- ✅ At least one agent appears in **Agents** tab
- ✅ Alerts are visible in **Security Events** dashboard

---

## Additional Resources

- **Official Docs:** https://documentation.wazuh.com/
- **Community Forum:** https://groups.google.com/g/wazuh
- **GitHub Issues:** https://github.com/wazuh/wazuh/issues
- **Training:** https://wazuh.com/training/

---

## Support

For issues specific to this deployment:
1. Check [LESSONS_LEARNED.md](LESSONS_LEARNED.md) for known gotchas
2. Review Docker logs for error messages
3. Verify version is v4.14.1 or later

**Not affiliated with Wazuh Inc. This is a community reference implementation.**