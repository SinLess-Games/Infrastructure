# vault-configure Role

This Ansible role installs, configures, and manages HashiCorp Vault with integrated Raft storage, TLS, and optional high-availability setup using HAProxy and Keepalived.

## Features

- **Vault Installation**: Downloads and installs the official Vault binary with capability-based privilege isolation
- **Raft Storage Backend**: Uses integrated storage (Raft consensus) for persistence
- **TLS/HTTPS**: Generates self-signed certificates or supports external certificates
- **Cluster Support**: Configures Vault for multi-node clustering with automatic peer discovery
- **Load Balancing**: Optional HAProxy setup for distributing requests across nodes
- **Virtual IP (VIP)**: Optional Keepalived for providing a stable VIP across cluster nodes
- **Unseal Keys Management**: Automatically saves unseal keys and root tokens to `.outputs/vault`
- **Audit Logging**: Enables file-based audit logging
- **Systemd Integration**: Full systemd service management with health checks

## Variables

All variables are defined in `Ansible/group_vars/vault/`.

### Core Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_version` | `1.16.0` | Vault binary version to install |
| `vault_user` | `vault` | System user running Vault |
| `vault_group` | `vault` | System group for Vault |
| `vault_home_dir` | `/etc/vault` | Vault configuration directory |
| `vault_data_dir` | `/opt/vault/data` | Raft storage directory |
| `vault_logs_dir` | `/var/log/vault` | Log file directory |

### TLS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_tls_disable` | `false` | Disable TLS (not recommended) |
| `vault_tls_cert_file` | `/etc/vault/tls/vault.crt` | Path to TLS certificate |
| `vault_tls_key_file` | `/etc/vault/tls/vault.key` | Path to TLS private key |
| `vault_skip_verify` | `false` | Skip certificate verification (dev only) |

### Cluster Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_cluster_name` | `vault-cluster` | Name of the cluster |
| `vault_api_addr` | `https://<hostname>:8200` | API endpoint address |
| `vault_cluster_addr` | `https://<hostname>:8201` | Cluster communication endpoint |
| `vault_raft_retry_join` | `[]` | List of peers to join for cluster formation |

### High Availability (HA)

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_ha_enabled` | `false` | Enable HA setup |
| `vault_haproxy_enabled` | `false` | Enable HAProxy load balancing |
| `vault_keepalived_enabled` | `false` | Enable Keepalived VIP |
| `vault_keepalived_priority` | `100` | VRRP priority (higher = preferred) |
| `vault_keepalived_virtual_ip` | `` | Virtual IP address (VLAN 20 recommended) |
| `vault_keepalived_interface` | `eth0` | Network interface for VIP |
| `vault_keepalived_vrid` | `51` | VRRP Router ID |

### Initialization & Unsealing

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_initialize` | `false` | Initialize Vault (run once on first node) |
| `vault_key_shares` | `5` | Number of unseal key shares |
| `vault_key_threshold` | `3` | Unseal key threshold |
| `vault_unseal_keys_output_dir` | `.outputs/vault` | Output directory for keys |
| `vault_unseal_keys_file` | `unseal-keys.json` | Unseal keys filename |

## Usage

### Basic Setup (Single Node)

```yaml
---
# Ansible/inventory/vault.yaml
vault:
  hosts:
    vault-01:
      ansible_host: 10.1.0.51
```

```yaml
---
# playbooks/setup-vault.yaml
- hosts: vault
  roles:
    - vault-configure
```

```bash
# Initialize Vault (first node only, run once)
cd Ansible
../.venv/bin/ansible-playbook playbooks/setup-vault.yaml \
  -e vault_initialize=true \
  --tags vault-init

# Configure remaining nodes
../.venv/bin/ansible-playbook playbooks/setup-vault.yaml \
  --tags vault-install,vault-configure,vault-tls
```

### HA Setup with VIP

```yaml
---
# Environments/production/group_vars/vault/ha.yaml
vault_ha_enabled: true
vault_keepalived_enabled: true
vault_haproxy_enabled: true
vault_keepalived_virtual_ip: "10.20.0.50"  # Services VLAN
vault_keepalived_interface: "ens0"

vault_cluster_nodes:
  - name: "vault-01"
    ip_address: "10.1.0.51"
    api_addr: "https://10.1.0.51:8200"
    raft_node_id: "vault-01"
  - name: "vault-02"
    ip_address: "10.1.0.52"
    api_addr: "https://10.1.0.52:8200"
    raft_node_id: "vault-02"
  - name: "vault-03"
    ip_address: "10.1.0.53"
    api_addr: "https://10.1.0.53:8200"
    raft_node_id: "vault-03"
```

```bash
# Run on all nodes
cd Ansible
../.venv/bin/ansible-playbook playbooks/setup-vault.yaml \
  -i inventory/production.yaml \
  -e vault_initialize=true \
  --tags vault
```

## Unseal Keys & Root Token

After initialization, files are created in `.outputs/vault/`:

```bash
ls -la .outputs/vault/
# unseal-keys.json    - Unseal key shares (base64 encoded)
# root-token.json     - Root token (KEEP SECURE!)
```

**Important**: Store these files securely and distribute unseal keys to different individuals/systems.

## Raft Cluster Formation

The role automatically handles Raft cluster formation:

1. **First node**: Initializes the cluster
2. **Subsequent nodes**: Join via `retry_join` configuration
3. **Autopilot**: Automatically manages cluster health and promotions

## Certificate Management

The role generates self-signed certificates by default:

```bash
# Use external certificates instead
ansible-playbook setup-vault.yaml \
  -e vault_tls_cert_file=/path/to/vault.crt \
  -e vault_tls_key_file=/path/to/vault.key \
  --tags vault-tls
```

## Vault API Access

After setup:

```bash
# Via direct node access
export VAULT_ADDR=https://10.1.0.51:8200
export VAULT_SKIP_VERIFY=true  # Dev only
vault status

# Via VIP (if HA enabled)
export VAULT_ADDR=https://10.20.0.50:8200
vault status
```

## Logs & Troubleshooting

```bash
# Check Vault service
ssh vault-01 "systemctl status vault"

# View Vault logs
ssh vault-01 "journalctl -u vault -f"

# Check Raft cluster status
ssh vault-01 "VAULT_ADDR=https://127.0.0.1:8200 vault operator raft list-peers"

# View audit logs
ssh vault-01 "tail -f /var/log/vault/audit.log"
```

## Role Tags

- `vault` - Run all Vault configuration
- `vault-install` - Install Vault binary only
- `vault-configure` - Configure Vault settings
- `vault-tls` - Configure TLS certificates
- `vault-init` - Initialize Vault (first node only)
- `vault-unseal` - Unseal Vault
- `vault-raft` - Setup Raft cluster
- `vault-ha` - Configure HA setup
- `vault-haproxy` - Setup HAProxy
- `vault-keepalived` - Setup Keepalived VIP
- `vault-service` - Manage systemd service

## Dependencies

- Python 3.8+
- Ansible 2.9+
- Debian/Ubuntu Linux
- Network connectivity for downloading Vault binary

## Security Considerations

1. **Unseal Keys**: Store in secure locations (HashiCorp Vault, HSM, etc.)
2. **Root Token**: Use only for initial setup, revoke after bootstrapping
3. **Certificates**: Use proper CA-signed certificates in production
4. **Network**: Restrict access to Vault ports (8200, 8201)
5. **Audit Logs**: Regularly collect and analyze audit logs
6. **mlock**: Enabled by default to prevent memory swapping

## References

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Raft Storage](https://www.vaultproject.io/docs/configuration/storage/raft)
- [TLS Configuration](https://www.vaultproject.io/docs/configuration/listener/tcp)
- [High Availability](https://www.vaultproject.io/docs/concepts/ha)
