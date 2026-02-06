# Vault Cluster Terraform Module

Terraform module for deploying a highly-available HashiCorp Vault cluster on Proxmox VE with Raft integrated storage.

## Overview

This module creates a production-ready Vault cluster with:

- **Raft Integrated Storage**: No external storage backend required
- **High Availability**: 3+ node cluster with automatic failover
- **Distributed Placement**: VMs spread across multiple Proxmox hosts (pve-01, pve-04, pve-05)
- **Proxmox HA Integration**: Optional HA resource management
- **Automated Backups**: Proxmox Backup Server integration
- **Cloud-Init**: Automated VM provisioning
- **Ansible Integration**: Auto-generated inventory for configuration management

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Vault Cluster (Raft)                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  vault-01    │  │  vault-02    │  │  vault-03    │      │
│  │  (pve-01)    │  │  (pve-04)    │  │  (pve-05)    │      │
│  │  Leader      │  │  Follower    │  │  Follower    │      │
│  │  10.10.20.2  │  │  10.10.20.3  │  │  10.10.20.4  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                 │                 │                │
│         └─────────────────┴─────────────────┘                │
│              Raft Consensus Protocol                         │
│         (Leader Election + Log Replication)                  │
└─────────────────────────────────────────────────────────────┘
```

## Features

### ✅ High Availability
- Odd-numbered node count (3, 5, 7) for Raft quorum
- Distributed placement across Proxmox hosts for fault tolerance
- Automatic leader election and failover
- Proxmox HA resource management (optional)

### ✅ Security
- TLS encryption for API and cluster communication
- Network isolation via VLANs (default: VLAN 20 - Services)
- VM deletion protection
- SSH key-based authentication

### ✅ Operational Excellence
- Automated Ansible inventory generation
- Cloud-init for rapid provisioning
- QEMU guest agent integration
- Structured monitoring endpoints
- Prometheus metrics export

### ✅ Storage & Backup
- Raft integrated storage (no external dependencies)
- Ceph-backed VM disks for replication
- Proxmox Backup Server integration
- Configurable backup schedules

## Usage

### Basic Example

```hcl
module "vault_cluster" {
  source = "./modules/vault-cluster"

  cluster_name = "vault-prod"
  environment  = "prod"

  # Distributed placement across Proxmox nodes
  target_nodes   = ["pve-01", "pve-04", "pve-05"]
  clone_template = "debian-12-template"

  # Network configuration
  ip_addresses = ["10.10.20.2", "10.10.20.3", "10.10.20.4"]
  gateway      = "10.10.20.1"
  vlan_id      = 20

  # Resource allocation
  cpu_cores = 2
  memory_mb = 4096
  disk_size = "40G"
  storage   = "vm-fast"

  # SSH access
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2E... user@host"
  ]

  # HA and Backup
  ha_enabled     = true
  backup_enabled = true
}
```

### Advanced Example with Custom Configuration

```hcl
module "vault_cluster_staging" {
  source = "./modules/vault-cluster"

  cluster_name     = "vault-staging"
  environment      = "staging"
  node_count       = 3
  node_name_prefix = "vault-stg"

  # Proxmox placement
  target_nodes   = ["pve-01", "pve-04", "pve-05"]
  clone_template = "debian-12-template"

  # Network configuration
  ip_addresses = ["10.10.20.12", "10.10.20.13", "10.10.20.14"]
  gateway      = "10.10.20.1"
  cidr_subnet  = "/24"
  vlan_id      = 20
  nameservers  = "10.10.20.253 1.1.1.1"

  # Resource allocation
  cpu_cores   = 2
  cpu_sockets = 1
  memory_mb   = 4096
  disk_size   = "60G"
  storage     = "vm-fast"

  # Vault configuration
  vault_version      = "1.15.4"
  vault_port         = 8200
  vault_cluster_port = 8201
  vault_storage_path = "/opt/vault/data"
  vault_log_path     = "/opt/vault/logs"

  # TLS configuration
  vault_tls_enabled  = true
  vault_tls_cert_path = "/opt/vault/tls/vault.crt"
  vault_tls_key_path  = "/opt/vault/tls/vault.key"

  # Users and access
  default_user = "ubuntu"
  ansible_user = "ansible"
  ssh_keys = [
    file("~/.ssh/id_rsa.pub"),
    file("~/.ssh/automation.pub")
  ]

  # HA configuration
  ha_enabled = true
  ha_group   = "vault-staging-ha"

  # Backup configuration
  backup_enabled  = true
  backup_schedule = "0 3 * * *" # 3 AM daily

  # VM options
  onboot        = true
  protection    = true
  startup_order = 10
  agent_enabled = true

  # Tags
  tags = ["vault", "staging", "tier-0", "ha"]
}
```

### Multi-Environment Deployment

```hcl
# Development Vault Cluster
module "vault_dev" {
  source = "./modules/vault-cluster"

  cluster_name   = "vault-dev"
  environment    = "dev"
  target_nodes   = ["pve-01", "pve-04", "pve-05"]
  clone_template = "debian-12-template"
  
  ip_addresses = ["10.10.20.5", "10.10.20.6", "10.10.20.7"]
  gateway      = "10.10.20.1"
  vlan_id      = 20
  
  cpu_cores      = 1
  memory_mb      = 2048
  disk_size      = "30G"
  ha_enabled     = false
  backup_enabled = true
  
  ssh_keys = [var.ssh_public_key]
}

# Production Vault Cluster
module "vault_prod" {
  source = "./modules/vault-cluster"

  cluster_name   = "vault-prod"
  environment    = "prod"
  target_nodes   = ["pve-01", "pve-04", "pve-05"]
  clone_template = "debian-12-template"
  
  ip_addresses = ["10.10.20.2", "10.10.20.3", "10.10.20.4"]
  gateway      = "10.10.20.1"
  vlan_id      = 20
  
  cpu_cores      = 2
  memory_mb      = 4096
  disk_size      = "60G"
  ha_enabled     = true
  backup_enabled = true
  protection     = true
  
  ssh_keys = [var.ssh_public_key]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4 |
| proxmox | >= 3.0.0 |
| vault | >= 5.7.0 |

## Providers

| Name | Version |
|------|---------|
| proxmox | >= 3.0.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| `target_nodes` | List of Proxmox nodes for VM distribution | `list(string)` |
| `clone_template` | VM template to clone | `string` |
| `environment` | Environment (dev, staging, prod) | `string` |
| `ip_addresses` | List of static IP addresses for nodes | `list(string)` |
| `gateway` | Network gateway | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cluster_name` | Vault cluster name | `string` | `"vault-cluster"` |
| `node_count` | Number of Vault nodes (must be odd) | `number` | `3` |
| `node_name_prefix` | VM name prefix | `string` | `"vault"` |
| `vm_id_start` | Starting VM ID | `number` | `200` |
| `cpu_cores` | CPU cores per node | `number` | `2` |
| `memory_mb` | Memory per node (MB) | `number` | `4096` |
| `disk_size` | Disk size per node | `string` | `"40G"` |
| `storage` | Proxmox storage pool | `string` | `"vm-fast"` |
| `vlan_id` | VLAN ID | `number` | `20` |
| `network_bridge` | Network bridge | `string` | `"vmbr0"` |
| `vault_version` | Vault version | `string` | `"1.15.4"` |
| `vault_port` | Vault API port | `number` | `8200` |
| `vault_cluster_port` | Vault cluster port | `number` | `8201` |
| `vault_tls_enabled` | Enable TLS | `bool` | `true` |
| `ha_enabled` | Enable Proxmox HA | `bool` | `true` |
| `backup_enabled` | Enable backups | `bool` | `true` |

See [variables.tf](./variables.tf) for complete list.

## Outputs

### Cluster Information

| Name | Description |
|------|-------------|
| `cluster_name` | Vault cluster name |
| `cluster_members` | Detailed cluster member information |
| `vm_ids` | List of Proxmox VM IDs |
| `vm_names` | List of VM names |
| `vm_placement` | Map of VMs to Proxmox hosts |

### Connection Information

| Name | Description |
|------|-------------|
| `vault_addr` | VAULT_ADDR environment variable |
| `vault_api_endpoints` | List of API endpoints |
| `vault_leader_endpoint` | Leader node endpoint |
| `vault_connection_string` | CLI connection export |

### Configuration

| Name | Description |
|------|-------------|
| `vault_raft_retry_join` | Raft retry_join configuration |
| `vault_raft_config_hcl` | HCL-formatted Raft config |
| `ansible_inventory_path` | Generated inventory file path |
| `monitoring_endpoints` | Health/metrics endpoints |

See [outputs.tf](./outputs.tf) for complete list.

## Post-Deployment Steps

### 1. Configure VMs with Ansible

The module auto-generates an Ansible inventory file:

```bash
# Location
./inventory/vault-<environment>.yaml

# Run Vault configuration playbook
cd Ansible
../.venv/bin/ansible-playbook playbooks/setup-vault-cluster.yaml \
  -i ../Terraform/inventory/vault-prod.yaml \
  --ask-vault-pass
```

### 2. Initialize Vault Cluster

```bash
# Set environment
export VAULT_ADDR="https://10.10.20.2:8200"

# Initialize the first node
vault operator init -key-shares=5 -key-threshold=3

# Save the unseal keys and root token securely!

# Unseal all nodes
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### 3. Join Additional Nodes to Raft Cluster

```bash
# On vault-02 and vault-03
export VAULT_ADDR="https://10.10.20.3:8200"
vault operator raft join https://10.10.20.2:8200

# Unseal each node after joining
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### 4. Verify Cluster Health

```bash
# Check cluster members
vault operator raft list-peers

# Check leader
vault status

# Verify HA status
vault read sys/leader
```

## Network Configuration

### VLAN Assignment

| VLAN | Name | Purpose | Default Subnet |
|------|------|---------|----------------|
| 20 | Services | Vault, DNS, core services | 10.10.20.0/24 |

### Port Requirements

| Port | Protocol | Purpose |
|------|----------|---------|
| 8200 | TCP | Vault API (HTTPS) |
| 8201 | TCP | Vault cluster communication |
| 22 | TCP | SSH management |

### Firewall Rules

```bash
# Allow Vault API from Kubernetes VLAN
iptables -A INPUT -p tcp -s 10.10.30.0/24 --dport 8200 -j ACCEPT

# Allow cluster communication between Vault nodes
iptables -A INPUT -p tcp -s 10.10.20.2 --dport 8201 -j ACCEPT
iptables -A INPUT -p tcp -s 10.10.20.3 --dport 8201 -j ACCEPT
iptables -A INPUT -p tcp -s 10.10.20.4 --dport 8201 -j ACCEPT
```

## Monitoring

### Prometheus Metrics

Vault exposes Prometheus-compatible metrics:

```yaml
# Prometheus scrape config
scrape_configs:
  - job_name: 'vault'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    static_configs:
      - targets:
          - '10.10.20.2:8200'
          - '10.10.20.3:8200'
          - '10.10.20.4:8200'
    scheme: https
    tls_config:
      insecure_skip_verify: true
```

### Health Checks

```bash
# Health endpoint (returns 200 if initialized and unsealed)
curl -k https://10.10.20.2:8200/v1/sys/health

# Leader status
curl -k https://10.10.20.2:8200/v1/sys/leader

# Raft configuration
vault operator raft list-peers
```

## Backup and Recovery

### Raft Snapshots

```bash
# Create Raft snapshot
vault operator raft snapshot save backup.snap

# Restore from snapshot
vault operator raft snapshot restore backup.snap
```

### Automated Backups

The module configures Proxmox Backup Server integration:

- **VM Snapshots**: Nightly backup of entire VM
- **Backup Schedule**: Configurable via `backup_schedule` variable
- **Retention**: Managed by PBS policies

### Disaster Recovery

1. **Restore VMs** from PBS
2. **Unseal Vault** using unseal keys
3. **Verify Raft** cluster membership
4. **Restore data** from Raft snapshot if needed

## Troubleshooting

### Vault Node Won't Start

```bash
# Check Vault service status
systemctl status vault

# Check logs
journalctl -u vault -f

# Common issues:
# - TLS certificate paths incorrect
# - Storage path permissions
# - Port conflicts
```

### Raft Cluster Issues

```bash
# Check Raft configuration
vault operator raft configuration

# Remove dead peer (emergency only)
vault operator raft remove-peer <node_id>

# Force new cluster (DESTRUCTIVE)
vault operator raft snapshot restore -force backup.snap
```

### Network Connectivity

```bash
# Test API connectivity
curl -k https://10.10.20.2:8200/v1/sys/health

# Test cluster port
nc -zv 10.10.20.2 8201

# Check firewall rules
iptables -L -n | grep 8200
```

## Integration Points

### Kubernetes Authentication

```hcl
# Enable Kubernetes auth in Vault
vault auth enable kubernetes

# Configure auth method
vault write auth/kubernetes/config \
  kubernetes_host="https://k8s-api:6443" \
  kubernetes_ca_cert=@ca.crt
```

### Cert-Manager Integration

```yaml
# Vault PKI Issuer for cert-manager
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    server: https://10.10.20.2:8200
    path: pki_int/sign/kubernetes
    auth:
      kubernetes:
        role: cert-manager
        mountPath: /v1/auth/kubernetes
```

## Security Considerations

### Unseal Keys
- **CRITICAL**: Store unseal keys in multiple secure locations
- Use auto-unseal with Transit backend for production
- Never commit unseal keys to Git

### Root Token
- Revoke initial root token after setup
- Use AppRole or Kubernetes auth for automation
- Enable audit logging immediately

### Network Security
- Enable TLS for all Vault communication
- Use Cloudflare Tunnel or VPN for external access
- Implement network policies in Kubernetes

### Access Control
- Follow principle of least privilege
- Use Vault policies for granular access
- Enable MFA for human access
- Rotate tokens regularly

## References

- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault)
- [Raft Storage Backend](https://developer.hashicorp.com/vault/docs/configuration/storage/raft)
- [Vault Architecture](../../Docs/Architecture/ADRs/ADR-0012.md)
- [Project Overview](../../Docs/Architecture/ARCHITECTURE.md)

## License

Internal use only - SinLess Games LLC Infrastructure

## Maintenance

### Version Updates

```bash
# Update Vault version
terraform apply -var="vault_version=1.16.0"
```

### Scaling

```bash
# Add 2 more nodes (to 5 total)
terraform apply -var="node_count=5" \
  -var='ip_addresses=["10.10.20.2","10.10.20.3","10.10.20.4","10.10.20.8","10.10.20.9"]'
```

## Support

For issues or questions, see:
- [Architecture Decisions](../../Docs/Architecture/DECISIONS.md)
- [Operations Guide](../../Docs/Operations/)
- [Vault Cluster Reference](../../Docs/proxmox/Cluster-Reference.md)
