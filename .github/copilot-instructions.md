# Copilot Instructions for SinLess Games Infrastructure

## Project Overview

This is an **Infrastructure-as-Code** monorepo for managing a production Proxmox cluster with integrated Ceph storage, Kubernetes workloads, and zero-trust networking. The platform serves SinLess Games LLC with development, staging, and production environments.

**Core Technologies:**
- **Proxmox VE** (5-node cluster: pve-01 through pve-05)
- **Ceph** for shared storage (Proxmox-integrated)
- **Ansible** for configuration management
- **Kubernetes** (RKE2) with FluxCD GitOps
- **Packer** for VM template building
- **Terraform** for infrastructure provisioning
- **HashiCorp Vault** for secrets management

## Architecture Principles

1. **Taskfile-First Interface**: Always use `task` commands—never run tools directly. See [taskfile.yaml](taskfile.yaml) and `.taskfiles/` subdirectories.
2. **VLAN-Based Network Segmentation**: Management (VLAN 10), Services (VLAN 20), K8s (VLAN 30), Storage (VLAN 40), DMZ (VLAN 50)
3. **Idempotent Operations**: All playbooks and tasks are safe to re-run
4. **Environment Separation**: [Environments/](Environments/) contains dev/staging/prod overlays
5. **Secrets in Ansible Vault**: Sensitive values prefixed with `vault_` in [Ansible/group_vars/](Ansible/group_vars/)

## Critical Workflows

### Initializing the Repository

```bash
# Bootstrap the environment (installs dependencies, creates venv)
task init

# Configure localhost as Ansible control node
task ansible:configure-localhost
```

**What happens:**
- Creates Python venv at `Ansible/.venv/`
- Installs Ansible + dependencies from [Ansible/requirements.txt](Ansible/requirements.txt)
- Installs Galaxy collections to `Ansible/.collections/`

### Running Ansible Playbooks

**Never invoke `ansible-playbook` directly.** Use task wrappers:

```bash
# Setup Proxmox cluster nodes
task ansible:setup-proxmox-nodes

# Setup Technitium DNS
task ansible:setup-technitium
```

**Tag-based execution:**
```bash
# Run only certificate management role
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml \
  --tags proxmox,certs --ask-vault-pass
```

Common tags: `proxmox`, `cluster`, `ceph`, `certs`, `ha-ui`, `network`, `hardware`

### Ansible Vault Pattern

Sensitive variables follow this convention:
- **Public variables**: [Ansible/group_vars/proxmox/certificate.yaml](Ansible/group_vars/proxmox/certificate.yaml) references `{{ vault_cloudflare_dns_token }}`
- **Secret values**: [Ansible/group_vars/proxmox/vault-certs.yaml](Ansible/group_vars/proxmox/vault-certs.yaml) (encrypted with `ansible-vault encrypt`)

To edit vault files:
```bash
ansible-vault edit Ansible/group_vars/proxmox/vault-certs.yaml
```

## Project-Specific Conventions

### Role Structure

Custom roles live in [Ansible/roles/](Ansible/roles/). Key roles:
- `proxmox-cluster`: Bootstraps/joins Proxmox cluster (SERIALIZED—never parallel)
- `proxmox-ceph`: Configures Ceph monitors, managers, OSDs, and storage pools
- `proxmox-ha-ui`: Deploys Keepalived VIP + HAProxy for HA dashboard access
- `proxmox-certs`: Manages certificates (self-signed, ACME/Let's Encrypt, or manual CA)
- `proxmox-networking`: Configures VLANs, bridges, and firewall rules

**Role execution order matters**: See [Ansible/playbooks/setup-proxmox-nodes.yaml](Ansible/playbooks/setup-proxmox-nodes.yaml) phases:
1. SSH baseline
2. Node hardening
3. Cluster lifecycle (bootstrap leader, then join members)
4. Hardware inventory
5. HA UI setup
6. Certificate management
7. Networking
8. Ceph storage

### Proxmox Cluster Operations

**CRITICAL**: Proxmox cluster join operations MUST be serialized. The [proxmox-cluster](Ansible/roles/proxmox-cluster/) role handles this with conditional logic:
- First node (defined by `proxmox_cluster_bootstrap_node` in [cluster.yaml](Ansible/group_vars/proxmox/cluster.yaml)) creates cluster
- Remaining nodes join sequentially with `serial: 1`

Never run cluster tasks in parallel—Proxmox's cluster join process is not concurrency-safe.

### Ceph Storage Configuration

Ceph pools and storage classes are defined in [Ansible/group_vars/proxmox/ceph.yaml](Ansible/group_vars/proxmox/ceph.yaml):
- **ISOs**: CephFS filesystem for ISO storage (`/mnt/pve/ISOs`)
- **vm-fast**: RBD pool for high-performance VM disks
- **vm-capacity**: RBD pool for capacity-optimized storage

Mount CephFS manually for testing:
```bash
ssh root@<node> "mount -t ceph <mon1>,<mon2>,<mon3>:/ /mnt/pve/ISOs -o name=admin,fs=ISOs"
```

### Certificate Management

ACME integration uses Cloudflare DNS-01 challenge. Configuration in [certificate.yaml](Ansible/group_vars/proxmox/certificate.yaml):
- Set `proxmox_acme_enabled: true` to activate
- Pre-populated for `sinlessgames.com` domain
- Supports self-signed, ACME, or manual CA-signed certs
- Auto-renewal when within `proxmox_cert_renewal_threshold` days

## File Navigation

**Key documentation paths:**
- [Docs/Start-Here/](Docs/Start-Here/): Sequential guides (00-09) for bootstrapping
- [Docs/Architecture/ARCHITECTURE.md](Docs/Architecture/ARCHITECTURE.md): System blueprint
- [Docs/Architecture/DECISIONS.md](Docs/Architecture/DECISIONS.md): ADR index
- [Docs/Start-Here/01-Repository-Layout.md](Docs/Start-Here/01-Repository-Layout.md): Directory structure rules

**Inventory structure:**
- [Ansible/inventory/](Ansible/inventory/): YAML-based inventory
- [Ansible/inventory/proxmox.yaml](Ansible/inventory/proxmox.yaml): Proxmox nodes
- [Ansible/inventory/dns.yaml](Ansible/inventory/dns.yaml): Technitium DNS servers

**Variable precedence:**
1. [Ansible/group_vars/all/](Ansible/group_vars/all/): Global defaults
2. [Ansible/group_vars/proxmox/](Ansible/group_vars/proxmox/): Proxmox-specific
3. [Ansible/group_vars/technitium/](Ansible/group_vars/technitium/): DNS-specific

## Common Pitfalls

1. **Don't bypass the venv**: Always use `Ansible/.venv/bin/ansible-playbook`, not system Ansible
2. **Don't skip vault passwords**: Most playbooks require `--ask-vault-pass` or `ANSIBLE_VAULT_PASSWORD_FILE`
3. **Don't parallelize cluster joins**: Use `serial: 1` for any Proxmox cluster join tasks
4. **Don't hardcode secrets**: Use `{{ vault_* }}` variable references and Ansible Vault encryption
5. **Don't skip task init**: Run `task init` after fresh clone or when dependencies change

## Testing & Validation

```bash
# Validate Ansible syntax
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml --syntax-check

# Dry-run (check mode)
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml --check --diff

# List available tasks
task --list
```

## Integration Points

- **Cloudflare**: DNS management and Zero Trust access (ACME DNS-01 challenges)
- **HashiCorp Vault**: Centralized secrets management (Raft-based cluster)
- **MinIO**: S3-compatible storage for backups (hosted on pve-02, pve-03)
- **GitLab**: Git hosting and CI/CD (hosted on pve-02, pve-03)
- **FluxCD**: Kubernetes GitOps controller
- **Authentik**: OIDC identity provider

## External References

- ADR Process: See [DECISIONS.md](Docs/Architecture/DECISIONS.md) for architectural decision records
- Network Topology: [Docs/Network/Layer_2-3_diagram.md](Docs/Network/Layer_2-3_diagram.md)
- ACME Setup: [Docs/Start-Here/00-ACME-Implementation-Summary.md](Docs/Start-Here/00-ACME-Implementation-Summary.md)
