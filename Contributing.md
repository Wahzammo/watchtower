# Contributing to The Watchtower

Thank you for your interest in The Watchtower project! This repository serves as both a reference implementation and a potential commercial product offering for SMB security operations.

## Project Status

**Current Phase:** Portfolio/Reference Implementation  
**Maintainer:** Aaron Clifft ([GitHub](https://github.com/aclifft))  
**License:** MIT

## Project Goals

1. **Education:** Provide a well-documented, real-world SIEM deployment for learning
2. **SMB Security:** Enable small businesses to access enterprise-grade security monitoring
3. **MSP Offering:** Create a baseline "Watchtower-as-a-Service" product for managed security providers

## How to Contribute

### 1. Documentation Improvements

The most valuable contributions are improvements to:
- **Deployment guides** for different environments (AWS, Azure, bare metal)
- **Use case examples** (e.g., PCI-DSS compliance monitoring)
- **Troubleshooting scenarios** from real-world deployments
- **Agent configuration** for specific applications (Docker, Kubernetes, databases)

### 2. Configuration Templates

Share optimized configs for:
- Custom detection rules
- Compliance scanning configurations
- Integration with other security tools
- Performance tuning for specific hardware

### 3. Automation Scripts

Scripts that enhance deployment or operations:
- Automated agent deployment
- Backup/restore procedures
- Health monitoring dashboards
- Alert management automation

### 4. Testing & Bug Reports

Help validate the deployment process:
- Test on different Linux distributions
- Document hardware performance metrics
- Report compatibility issues
- Suggest optimizations

## Contribution Guidelines

### Code Style

- **Bash Scripts:** Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **YAML:** Use 2-space indentation, alphabetize keys where logical
- **Markdown:** Use sentence case for headers, include code examples

### Documentation Standards

- **Be Concise:** This is a LEAN project - avoid verbosity
- **Be Practical:** Focus on real-world scenarios, not theoretical edge cases
- **Be Clear:** Write for sysadmins with 2-3 years experience, not security experts

### Commit Messages

Use conventional commit format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `docs`: Documentation only changes
- `feat`: New feature or capability
- `fix`: Bug fix
- `perf`: Performance improvement
- `refactor`: Code restructuring without functional changes

**Example:**
```
docs(deployment): add Raspberry Pi 4 deployment guide

Added step-by-step instructions for deploying Watchtower on RPi4
with 8GB RAM. Includes performance benchmarks and tuning recommendations
for ARM architecture.

Closes #42
```

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/agent-automation`)
3. **Make** your changes with clear commit messages
4. **Test** your changes thoroughly
5. **Submit** a pull request with:
   - Clear description of what changed
   - Why the change is beneficial
   - Any testing performed
   - Screenshots (if UI/dashboard changes)

## What We're NOT Looking For

- **Feature creep:** This is a single-node deployment focused on simplicity
- **Over-engineering:** No Kubernetes, no service mesh, no microservices
- **Commercial integrations:** Free/open-source tools only
- **Breaking changes:** Maintain backwards compatibility with v4.14.1+

## Code of Conduct

### Our Standards

- **Be Respectful:** Technical disagreements are fine, personal attacks are not
- **Be Helpful:** If you see a mistake, suggest a fix (don't just criticize)
- **Be Patient:** Everyone learns at different speeds
- **Give Credit:** Acknowledge sources and prior work

### Unacceptable Behavior

- Harassment, discrimination, or trolling
- Publishing others' private information
- Spam, off-topic discussions, or self-promotion
- Any conduct that would be unprofessional in a workplace

## Recognition

Contributors who make significant improvements will be:
- Listed in the project README
- Credited in release notes
- Acknowledged in documentation

## Commercial Use

This project is MIT licensed. You're free to:
- Use it commercially
- Modify it for your needs
- Offer it as a managed service

We ask that you:
- Maintain the original copyright notice
- Link back to this repository
- Share improvements that benefit the community

## Questions?

- **Technical Support:** Open an issue with the `question` label
- **Security Concerns:** Email security@[domain].com (if sensitive)
- **Commercial Inquiries:** Contact via LinkedIn

## Project Roadmap

### Current Sprint (Q1 2026)
- [ ] Raspberry Pi 4/5 deployment guide
- [ ] Terraform templates for cloud deployment
- [ ] Ansible playbook for agent installation
- [ ] Performance benchmarking documentation

### Future Considerations
- [ ] Container registry for pre-built images
- [ ] Helm chart for Kubernetes (if demand exists)
- [ ] Integration templates (Slack, PagerDuty, etc.)
- [ ] Video walkthrough series

---

## About the Maintainer

**Aaron Clifft** is a cybersecurity GRC professional transitioning from 10+ years in electrical infrastructure and project management. The Watchtower project combines his operational technology background with formal GRC training (ISO 27001 Lead Auditor, PMP) to create practical security solutions for resource-constrained environments.

**Professional Background:**
- 15 years electrical contracting & infrastructure
- 10 years technical project management
- Recent completion of GRC Mastery training
- Experience with hyperscale data center projects
- Focus on pragmatic, LEAN security implementations

**Why This Project Matters:**
SMBs deserve enterprise-grade security without enterprise budgets. The Watchtower proves that recycled hardware + open-source software + solid architecture can deliver meaningful defense-in-depth for organizations that can't afford Splunk or QRadar.

---

*Last Updated: January 2026*