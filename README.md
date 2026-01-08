# 🛡️ The Watchtower

**A Portable, Production-Ready SIEM Stack for SMB Security Operations**

> *"Enterprise-grade security monitoring on recycled hardware — because defense-in-depth shouldn't require a defense budget."*

## 📖 Overview

The Watchtower is a containerized Security Operations Center (SOC) designed for resource-constrained environments. Built on Wazuh v4.14.1, this single-node deployment provides:

- **Real-time threat detection** across your infrastructure
- **File integrity monitoring** for critical assets
- **Compliance reporting** (CIS, PCI-DSS, GDPR)
- **Centralized log aggregation** from distributed agents

Perfect for SMBs, home labs, or MSP service offerings.

## 🏗️ Architecture

### Hardware Specifications
- **Platform:** HP EliteBook 820 G2 (or equivalent)
- **CPU:** Intel Core i7-5600U (2C/4T @ 2.6GHz)
- **RAM:** 16GB DDR3
- **Storage:** 256GB SATA SSD
- **Network:** Gigabit Ethernet (Static IP: 192.168.0.200)

### Software Stack
| Component | Purpose | Version |
|-----------|---------|---------|
| **Wazuh Manager** | SIEM engine, log processing, alerting | 4.14.1 |
| **OpenSearch** | Event indexing and search backend | 2.13.0 |
| **Wazuh Dashboard** | Web UI for visualization and management | 4.14.1 |

### Network Topology
```
[Internet] → [Firewall] → [Switch]
                             ├─ [Watchtower: 192.168.0.200] (SIEM Node)
                             ├─ [Z220 Workstation] (Wazuh Agent)
                             └─ [Ryzen Dev Rig] (Wazuh Agent)
```

## ⚡ Quick Start

### Prerequisites
```bash
# Install Docker and Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose-plugin git

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Set system tuning for OpenSearch
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-wazuh.conf
```

### Deployment (10-Minute Install)
```bash
# Clone official Wazuh Docker repository
# Check here for latest https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.1 
cd wazuh-docker/single-node

# Generate SSL certificates
docker compose -f generate-indexer-certs.yml run --rm generator

# Deploy the stack
docker compose up -d

# Verify all services are running
docker compose ps
```

### Access the Dashboard
- **URL:** `https://192.168.0.200` (or your server IP)
- **Username:** `admin`
- **Password:** `SecretPassword` (⚠️ **Change this immediately**)

## 🎯 Use Cases

### 1. **Personal Lab Security**
Monitor your home lab infrastructure with professional-grade tools. Track:
- SSH brute force attempts
- Unauthorized file modifications
- Container security events
- System configuration drift

### 2. **SMB Managed Security**
Offer Watchtower as a managed service:
- **Monthly Retainer:** $500-800/mo for 24/7 monitoring
- **Compliance Reports:** Automated CIS benchmark reporting for cyber insurance
- **Incident Response:** Alert escalation when anomalies detected

### 3. **Red Team Training**
Use Wazuh's detection capabilities to:
- Test evasion techniques against modern SIEM
- Understand how blue teams detect lateral movement
- Practice operational security (OPSEC) tradecraft

## 🔧 Advanced Configuration

### Agent Deployment
Deploy Wazuh agents to monitored endpoints:
```bash
# On Ubuntu/Debian agent
curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.1-1_amd64.deb
sudo WAZUH_MANAGER='192.168.0.200' dpkg -i wazuh-agent.deb
sudo systemctl enable wazuh-agent && sudo systemctl start wazuh-agent
```

### Custom Rules
File integrity monitoring for game assets:
```xml
<!-- /var/ossec/etc/rules/local_rules.xml -->
<group name="allogaia_fim,">
  <rule id="100001" level="12">
    <if_sid>550</if_sid>
    <field name="file">^/Allogaia/Content/</field>
    <description>Critical game asset modified: $(file)</description>
  </rule>
</group>
```

## ⚠️ Known Issues & Gotchas

### Version Compatibility
**CRITICAL:** Use v4.14.1 or later. Earlier versions (v4.9.0) have broken certificate generation that causes 5+ hour debugging sessions. See [LESSONS_LEARNED.md](LESSONS_LEARNED.md) for the full story.

### Resource Constraints
- Minimum 8GB RAM required (16GB recommended)
- Elasticsearch requires `vm.max_map_count=262144`
- SSD strongly recommended for log ingestion performance

## 📚 Documentation

- [Official Wazuh Docs](https://documentation.wazuh.com/)
- [Agent Deployment Guide](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html)
- [CIS Compliance Scanning](https://documentation.wazuh.com/current/user-manual/capabilities/policy-monitoring/ciscat/ciscat.html)

## 🤝 Contributing

This is a portfolio/reference implementation. For production deployments:
1. Change default passwords
2. Enable TLS/SSL with proper certificates
3. Configure firewall rules (only allow agent connections on port 1514)
4. Set up log retention policies based on compliance requirements

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

**Built with:** Docker, Wazuh, OpenSearch, Late nights, ADHD hyperfocus  
**Maintained by:** Aaron Clifft | Cybersecurity GRC Professional transitioning from 10+ years electrical/PM background