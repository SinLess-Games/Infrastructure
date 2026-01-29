# Proxmox HA UI Role

This Ansible role configures **HAProxy** and **Keepalived** to provide a highly available interface for Proxmox cluster management.

## Overview

The role sets up:
- **HAProxy**: Reverse proxy and load balancer for the Proxmox UI (port 8006)
- **Keepalived**: VRRP protocol for virtual IP failover and automatic master election
- **SSL/TLS**: Self-signed certificate generation for HTTPS
- **Health Checks**: Continuous monitoring of HAProxy and backend Proxmox nodes
- **Automatic Failover**: Seamless failover between cluster nodes using a virtual IP

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Browsers                           │
│              (https://proxmox-ha-ui:443)                    │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │   Virtual IP (VIP)               │
        │   keepalived_vip                │
        └────────────────┬────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │         HAProxy                  │
        │    (Load Balancer)               │
        │  Port 443 → 8006                 │
        └────────────────┬────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
    ┌───┴────┐    ┌──────┴───┐    ┌──────┴───┐
    │Proxmox1│    │Proxmox2  │    │Proxmox3  │
    │:8006   │    │:8006     │    │:8006     │
    └────────┘    └──────────┘    └──────────┘
   (Keepalived)   (Keepalived)    (Keepalived)
```

## Requirements

- Debian/Ubuntu-based system
- Proxmox cluster already configured
- Ansible 2.10+
- Network connectivity between cluster nodes on management network

## Role Variables

### Critical Variables (Must be set in group_vars or inventory)

```yaml
# Virtual IP for HA UI access
keepalived_vip: "192.168.1.50"

# Router ID - must be consistent across cluster
keepalived_router_id: "100"

# Authentication password (should use vault)
keepalived_auth_pass: "{{ vault_keepalived_password }}"
```

### Optional Variables (Use defaults or override)

```yaml
# Interface binding
keepalived_vip_interface: "vmbr0"          # Network interface for VIP
keepalived_vip_netmask: 24                 # Subnet mask

# Priority (100=master, lower=backup)
keepalived_priority: 100

# Health checks
keepalived_health_check_interval: 2        # Check every 2 seconds
keepalived_health_check_timeout: 5         # 5 second timeout
keepalived_health_check_fall: 3            # Mark down after 3 failures
keepalived_health_check_rise: 2            # Mark up after 2 successes

# HAProxy
haproxy_frontend_port: 443                 # Public HTTPS port
haproxy_stats_port: 8404                   # Statistics page port
proxmox_ui_port: 8006                      # Proxmox internal UI port
haproxy_use_ssl: true                      # Use SSL/TLS
```

## Configuration

### 1. Update group_vars for Proxmox nodes

Add to `group_vars/proxmox.yaml`:

```yaml
# HA UI Configuration
keepalived_vip: "192.168.1.50"             # Set your VIP
keepalived_router_id: "100"
keepalived_priority: "{{ 100 if inventory_hostname == 'pve1' else 90 }}"
keepalived_auth_pass: "{{ vault_keepalived_password }}"
```

### 2. Set up vault secret (recommended)

In `group_vars/proxmox/vault.yaml`:

```yaml
vault_keepalived_password: "your-secure-password-here"
```

### 3. Add role to playbook

In your Proxmox setup playbook:

```yaml
- hosts: proxmox
  roles:
    - proxmox-node
    - proxmox-cluster
    - proxmox-ha-ui  # Add this role
```

## Usage

### Deploy HA UI

```bash
ansible-playbook -i inventory/proxmox.yaml playbooks/setup-proxmox-nodes.yaml
```

### Verify Installation

```bash
# On any Proxmox node
systemctl status haproxy
systemctl status keepalived

# Check Keepalived status
ip addr show | grep "{{ keepalived_vip }}"

# Check HAProxy stats
curl -k https://proxmox-ha-ui:8404/stats

# Test frontend
curl -k https://proxmox-ha-ui/
```

### Access Proxmox UI

- **URL**: `https://proxmox-ha-ui` or `https://{{ keepalived_vip }}`
- **Port**: 443 (redirects from 80)
- **Stats**: `https://proxmox-ha-ui:8404/stats`

## Failover Behavior

### Master Election

1. Keepalived uses VRRP protocol for automatic master election
2. Node with highest priority becomes master
3. Master holds the VIP and services all requests
4. If master fails, next highest priority becomes master automatically

### Health Checks

- HAProxy is monitored by a custom health check script
- Checks HAProxy process and stats page every 2 seconds
- If health check fails 3 times, Keepalived removes VIP and elects new master
- Backend Proxmox nodes are checked via `/api2/json/version` HTTP endpoint

## SSL/TLS

- Self-signed certificates are auto-generated on first run
- Located at: `/etc/ssl/private/proxmox-ha-ui.pem`
- Valid for 365 days
- For production, replace with signed certificates

### Update Certificate

```bash
# Generate new certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/proxmox-ha-ui.key \
  -out /etc/ssl/private/proxmox-ha-ui.crt \
  -subj "/CN=proxmox-ha-ui"

# Combine
cat /etc/ssl/private/proxmox-ha-ui.crt /etc/ssl/private/proxmox-ha-ui.key > \
    /etc/ssl/private/proxmox-ha-ui.pem

# Reload HAProxy
systemctl reload haproxy
```

## Session Stickiness

HAProxy uses cookie-based session stickiness to ensure client requests go to the same backend node. This is important for Proxmox authentication and session persistence.

## Monitoring & Troubleshooting

### Check Keepalived Logs

```bash
journalctl -u keepalived -f
```

### Check HAProxy Logs

```bash
journalctl -u haproxy -f
```

### View HAProxy Stats

```bash
curl -k https://proxmox-ha-ui:8404/stats
```

### Check VIP Status

```bash
# Master will have VIP
ip addr show dev {{ keepalived_vip_interface }}

# Monitor VRRP transitions
tcpdump -i {{ keepalived_vip_interface }} vrrp
```

### Common Issues

1. **VIP not appearing**: Check Keepalived priority, auth_pass, and health checks
2. **Backend unreachable**: Verify proxmox_ui_port (8006) is accessible from load balancer
3. **SSL certificate errors**: Check `/etc/ssl/private/proxmox-ha-ui.pem` exists
4. **HAProxy won't start**: Run `haproxy -c -f /etc/haproxy/haproxy.cfg` to check config

## Performance Tuning

### Timeout Values

Adjust in `defaults/main.yaml` based on your environment:

```yaml
keepalived_health_check_interval: 2    # More frequent = faster failover
keepalived_health_check_fall: 3        # Higher = more tolerance to blips
```

### HAProxy Timeouts

Edit `templates/haproxy.cfg.j2`:

```yaml
timeout client 3600000          # 1 hour for client connections
timeout server 3600000          # 1 hour for backend connections
timeout connect 5000            # 5 seconds to connect to backend
```

## Security Considerations

1. **Change default passwords**: Update `keepalived_auth_pass` in vault
2. **Use signed certificates**: Replace self-signed certs in production
3. **Restrict VIP network**: Ensure VIP is on isolated management network
4. **Firewall rules**: 
   - Port 443 (HTTPS frontend)
   - Port 112 (VRRP protocol between keepalived nodes)
   - Port 8404 (HAProxy stats - restrict access)

## References

- [HAProxy Documentation](http://www.haproxy.org/)
- [Keepalived Documentation](https://www.keepalived.org/)
- [Proxmox Cluster Documentation](https://pve.proxmox.com/wiki/Cluster_Manager)

## License

MIT
