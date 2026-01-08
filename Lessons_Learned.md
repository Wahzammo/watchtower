# Lessons Learned: The 5-Hour Wazuh Deployment Debug Marathon

## TL;DR - The One-Line Fix

```bash
# Wrong (5 hours of pain):
git clone https://github.com/wazuh/wazuh-docker.git -b v4.9.0

# Right (10 minutes of joy):
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.1
```

**Root Cause:** Version v4.9.0 has broken certificate generation. The cert generator creates **directories** instead of **files**, causing cascading SSL failures across all three Wazuh components.

---

## The Journey (Because Pain = Learning)

### Hour 0-2: Initial Deployment Attempts

**Problem:** Wazuh Indexer wouldn't start, throwing SSL certificate errors.

**Symptoms:**
```
OpenSearchException[Is a directory: /usr/share/wazuh-indexer/certs/wazuh.indexer.pem 
Expected a file for plugins.security.ssl.transport.pemcert_filepath]
```

**Actions Taken:**
1. Manually created `opensearch.yml` with SSL configuration
2. Mounted custom config into indexer container
3. Verified certificate files existed in `wazuh-certs/` directory

**Outcome:** Indexer started successfully. Moved to next component.

---

### Hour 2-3: Dashboard SSL Configuration

**Problem:** Dashboard crash-looping with "EISDIR: illegal operation on a directory, read" errors.

**Root Cause Discovery:** Dashboard was trying to read certificate **files** but `wazuh-certs/` contained **directories** with certificate names.

**Actions Taken:**
1. Created `opensearch_dashboards.yml` with SSL paths
2. Set `opensearch.ssl.verificationMode: none` to bypass cert validation
3. Mounted config file into dashboard container

**Outcome:** Dashboard started but couldn't communicate with Manager API.

---

### Hour 3-4: Manager-to-Indexer Communication

**Problem:** Manager's Filebeat component couldn't connect to Indexer due to SSL certificate trust issues.

**Symptoms:**
```
Failed to connect to backoff(elasticsearch(https://wazuh.indexer:9200)): 
Get "https://wazuh.indexer:9200": x509: certificate signed by unknown authority
```

**Actions Taken:**
1. Created `filebeat.yml` with SSL verification disabled
2. Mounted filebeat config into manager container
3. Restarted manager multiple times with permission fixes

**Outcome:** Manager connected to Indexer. Dashboard showed login page.

---

### Hour 4-5: API Authentication & Final Debugging

**Problem:** Dashboard showed "Application Not Found" after successful login.

**Root Cause:** Wazuh Manager API credentials weren't configured in dashboard.

**Actions Taken:**
1. Attempted to add API config via YAML (rejected as invalid in v4.9.0)
2. Created `wazuh.yml` for API connection settings
3. Debugged through manager API authentication

**Outcome:** Stack functionally working but unstable.

---

### Hour 5: The Breakthrough

**Discovery:** Fresh clone from official repo **still failed** with same directory-instead-of-file issue.

**Investigation:**
```bash
cd ~/wazuh-docker/single-node/config/
ls -la certs.yml
# Output: drwxr-xr-x 2 aclifft aclifft 4096 Jan  7 14:38 certs.yml
# ^ It's a DIRECTORY, not a file!
```

**Final Solution:** Checked Wazuh GitHub releases, found v4.14.1 was current stable. Redeployed with correct version → immediate success.

---

## Technical Insights Gained

### 1. Wazuh Architecture (The Hard Way)

Learned the complete SSL certificate chain:
```
Root CA (root-ca.pem)
  ├─ Indexer Certificate (indexer.pem + indexer.key)
  ├─ Dashboard Certificate (dashboard.pem + dashboard.key)  
  ├─ Manager Certificate (manager.pem + manager.key)
  └─ Admin Certificate (admin.pem + admin-key.pem)
```

Each component needs:
- Its own certificate + key
- The root CA to trust other components
- Explicit config files pointing to cert paths

### 2. Docker Volume Mounting Gotchas

**Lesson:** When mounting config files, Docker won't error if the source is a directory instead of a file. The container will start, but the application inside will fail cryptically.

**Best Practice:**
```bash
# Always verify file type before mounting
file config/opensearch.yml  # Should say "YAML document text"

# Not:
file config/opensearch.yml  # directory
```

### 3. Filebeat → OpenSearch Pipeline

Wazuh Manager uses Filebeat (Elastic's log shipper) to send processed events to OpenSearch. This requires:
- Filebeat config (`/etc/filebeat/filebeat.yml`)
- SSL settings for OpenSearch connection
- Proper authentication credentials

If this link breaks, Manager appears healthy but no data reaches the Dashboard.

### 4. YAML Configuration Hierarchy

In v4.9.0, API connections were set via `opensearch_dashboards.yml`.  
In v4.14.1, API connections use a separate `wazuh.yml` file.

**Lesson:** Always check version-specific documentation. Config schemas change between releases.

### 5. Debugging Containerized Services

**Effective Workflow:**
1. Check if container is running: `docker compose ps`
2. View logs: `docker compose logs <service> --tail 50`
3. Filter errors: `docker compose logs <service> | grep -i error`
4. Execute into container: `docker exec -it <container> bash`
5. Verify mounted files: `docker exec -it <container> cat /path/to/config`

### 6. When to Stop Debugging

**Red Flag:** When official documentation doesn't match your experience.

If you're manually creating configs that should be auto-generated, you're probably using a broken version. Check:
- GitHub Issues for your version
- Recent commits/PRs
- Latest stable release

---

## Practical Takeaways for Future Deployments

### 1. Always Check Version Compatibility

```bash
# Before deploying ANY containerized app:
git ls-remote --tags https://github.com/wazuh/wazuh-docker.git | tail -5
# Pick the latest stable tag, not what an LLM suggests
```

### 2. Verify Prerequisites Before Troubleshooting

```bash
# These would have saved hours:
docker info  # Confirm Docker works
file config/certs.yml  # Confirm file vs directory
docker compose config  # Validate YAML syntax before running
```

### 3. Use Official Quick-Starts First

**Before customizing:**
1. Deploy the official setup vanilla
2. Verify it works end-to-end
3. Document what configs exist by default
4. Then modify ONE thing at a time

### 4. When LLMs Don't Have Current Info

Both Claude and Gemini suggested v4.9.0 because:
- Training data cutoff (Claude: Jan 2025)
- Outdated documentation in their context
- No real-time access to GitHub releases

**Lesson:** LLMs are great for architecture/debugging logic, but always verify version numbers against official sources.

---

## Estimated Time Savings

| Task | Manual Debugging | With Lessons Learned |
|------|------------------|---------------------|
| Initial deployment | 5 hours | 10 minutes |
| Certificate troubleshooting | 2 hours | Skipped (v4.14.1 works) |
| Config file creation | 1 hour | Skipped (auto-generated) |
| Permission fixes | 30 minutes | Skipped |
| API authentication | 1 hour | Pre-configured |
| **Total** | **~5 hours** | **~10 minutes** |

---

## The Silver Lining

While frustrating, this debugging session provided:
- Deep understanding of Wazuh's multi-tier architecture
- Hands-on Docker troubleshooting experience
- Practice reading application logs to identify root causes
- Proof that I can persist through ambiguous technical problems

**More valuable than following a working tutorial:** I now know *why* each component needs specific configs, not just *what* configs to use.

---

## References

- [Wazuh Docker GitHub](https://github.com/wazuh/wazuh-docker)
- [Wazuh 4.14.1 Release Notes](https://github.com/wazuh/wazuh/releases/tag/v4.14.1)
- [OpenSearch Security Configuration](https://opensearch.org/docs/latest/security/configuration/)

---

**Pro Tip:** When deploying open-source SIEM solutions at 1 AM while grinding MMO dailies, always check the version number first. Future you will thank present you.