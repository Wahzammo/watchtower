# 🛡️ The Watchtower

**A Portable, Containerized Security Operations Center (SOC) for the North Metro Tech Cluster.**

## 📖 Executive Summary
"The Watchtower" is a strategic initiative to deploy an enterprise-grade SIEM (Security Information and Event Management) system on dedicated, recycled hardware. By isolating security monitoring to a physical node, we ensure that audit logs remain secure even if the primary production servers are compromised.

This repository contains the Infrastructure-as-Code (IaC) required to deploy the **Wazuh** single-node stack via Docker, tuned specifically for resource-constrained environments.

## 🏗️ Architecture

### The Node (Hardware)
* **Model:** HP EliteBook 820 G2
* **CPU:** Intel Core i7-5600U
* **RAM:** 16GB (DDR3)
* **Storage:** 256GB SATA SSD
* **OS:** Ubuntu 25.10 (Kernel 6.x)

### The Stack (Software)
* **Orchestration:** Docker Compose (v2)
* **SIEM Engine:** Wazuh Manager (Latest)
* **Indexer:** OpenSearch (Single-node cluster)
* **Visualization:** Wazuh Dashboard

### Network Role
The Watchtower sits on the local LAN (Static IP: `192.168.0.200`) and ingests logs via the Wazuh Agent from:
1. **Z220 World Server:** Hosting the Neo4j Graph Database.
2. **Ryzen Dev Rig:** Hosting Unity Blueprints and Game Assets.

## 🎯 Key Capabilities
* **File Integrity Monitoring (FIM):** Real-time alerts on unauthorized changes to `/Allogaia/Content/` and wallet keys.
* **Log Analysis:** Centralized ingestion of system auth logs, docker container logs, and application events.
* **Compliance:** Automated reporting against CIS Benchmark standards for Linux hosts.

## ⚙️ Operational Constraints (LEAN Tuning)
This stack runs on the "bare minimum" hardware requirements for a Java-based SIEM. The configuration includes specific tuning to prevent OOM (Out of Memory) kills:
* **Java Heap Limits:** OpenSearch is hard-capped at 4GB RAM (`OPENSEARCH_JAVA_OPTS="-Xms4g -Xmx4g"`).
* **Log Retention:** Aggressive rotation policies (>7 days deletion) to preserve SATA SSD I/O bandwidth.
* **Visualization:** Resource-heavy Kibana/Dashboard visualizers are disabled by default.

## 🚀 Deployment

### Prerequisites
* Ubuntu Host with Docker Engine & Docker Compose installed.
* `vm.max_map_count` set to `262144` (Required for OpenSearch).

### Quick Start
```bash
# 1. Clone the repository
git clone [https://github.com/your-username/the-watchtower.git](https://github.com/your-username/the-watchtower.git)
cd the-watchtower

# 2. Generate generic certs (if not present)
docker-compose -f generate-indexer-certs.yml run --rm generator

# 3. Launch the stack
docker-compose up -d

# 4. Access Dashboard
# [https://192.168.0.200](https://192.168.0.200)
```

## 📜 License
MIT License. See [LICENSE](LICENSE) for details.

---
*Maintained by the North Metro Tech R&D Team.*
EOF

echo "✅ README.md has been generated."
