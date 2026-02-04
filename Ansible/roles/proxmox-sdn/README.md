# proxmox-sdn

Configures Proxmox Software-Defined Network (SDN) for VLAN-based network segmentation across the cluster.

## Overview

This role sets up and manages Proxmox SDN features including:

- **VLAN Zones** - Centralized VLAN configuration across all nodes
- **Virtual Networks** - Logical networks mapped to VLANs
- **Subnets** - IP address ranges and gateways for each network
- **Network Verification** - Status validation and reporting

## Network Architecture

Organized by function and environment:

| Network | VLAN | Subnet | Purpose |
|---------|------|--------|---------|
| infrastructure | 1 | 10.10.10.0/24 | Management and control plane |
| development | 20 | 10.10.20.0/24 | Development environment |
| testing | 30 | 10.10.30.0/24 | Testing/staging environment |
| production | 40 | 10.10.40.0/24 | Production workloads |
| dmz | 50 | 10.10.50.0/24 | DMZ/public-facing services |
| ceph | 60 | 10.10.60.0/24 | Ceph storage replication |

## Requirements

- Proxmox VE 6.2+ (SDN support)
- Cluster must be initialized
- All nodes must have network bridge configured (vmbr0)
- Root SSH access to nodes

## Role Variables

### Zone Configuration

```yaml
proxmox_sdn_zones:
  - name: "local-vlan"
    type: "vlan"
    nodes: "pve-01,pve-02,pve-03,pve-04,pve-05"
    disable_arp_nd_suppression: 0
```

### Network Configuration

```yaml
proxmox_sdn_networks:
  - name: "infrastructure"
    zone: "local-vlan"
    vlanid: 1
    subnet: "10.10.10.0/24"
    gateway: "10.10.10.1"
    enabled: true
```

**Fields:**
- `name` - Network identifier (must be unique)
- `zone` - SDN zone to use
- `vlanid` - VLAN ID (1-4094)
- `subnet` - IPv4 CIDR notation
- `gateway` - Default gateway IP
- `enabled` - Enable/disable network (true/false)

### DNS and NTP

```yaml
proxmox_sdn_dns_servers:
  - "1.1.1.1"
  - "8.8.8.8"

proxmox_sdn_ntp_servers:
  - "ntp.ubuntu.com"
  - "time.cloudflare.com"
```

## Dependencies

- `proxmox-cluster` - Cluster must be initialized
- `proxmox-node` - Base node configuration

## Tags

- `proxmox` - All Proxmox configuration
- `sdn` - All SDN configuration
- `zones` - Zone creation only
- `networks` - Network creation only
- `verify` - Verification and status checks

## Example Playbook

```yaml
---
- name: Configure Proxmox SDN networks
  hosts: proxmox
  vars:
    proxmox_sdn_enabled: true
    proxmox_sdn_zones:
      - name: "local-vlan"
        type: "vlan"
        nodes: "pve-01,pve-02,pve-03,pve-04,pve-05"

    proxmox_sdn_networks:
      - name: "management"
        zone: "local-vlan"
        vlanid: 10
        subnet: "10.0.0.0/24"
        gateway: "10.0.0.1"
        enabled: true
      - name: "storage"
        zone: "local-vlan"
        vlanid: 40
        subnet: "10.40.0.0/24"
        gateway: "10.40.0.1"
        enabled: true

  roles:
    - proxmox-sdn
```

## Task Flow

1. **Pre-flight checks**
   - Verify SDN is available on cluster
   - Display SDN capability status

2. **Zone Creation**
   - Create VLAN zones if they don't exist
   - Configure zone-wide settings
   - Notify handlers to apply configuration

3. **Network Creation**
   - Create virtual networks mapped to zones
   - Apply VLAN tagging

4. **Subnet Assignment**
   - Configure IP subnets per network
   - Set gateway addresses

5. **Verification**
   - Display zone and network status
   - Verify subnet configurations
   - Report overall SDN health

## Network Segmentation Strategy

### Infrastructure Network (VLAN 1)
- **Purpose**: Proxmox cluster communication, API access
- **Typical Hosts**: pve-01 through pve-05
- **Services**: HAProxy, pve-ha-manager, control plane

### Development Network (VLAN 20)
- **Purpose**: Development environment workloads
- **Typical Services**: Dev VMs, dev Kubernetes nodes
- **Isolation**: From production traffic

### Testing Network (VLAN 30)
- **Purpose**: Testing and staging environment
- **Typical Services**: Test VMs, staging Kubernetes
- **Isolation**: From production traffic

### Production Network (VLAN 40)
- **Purpose**: Production workloads and services
- **Typical Services**: Production VMs, K8s cluster
- **Priority**: High availability, monitoring

### DMZ Network (VLAN 50)
- **Purpose**: Public-facing services
- **Typical Services**: Web servers, reverse proxies
- **Access**: Restricted ingress/egress rules

### Ceph Network (VLAN 60)
- **Purpose**: Ceph storage replication
- **Typical Hosts**: pve-01 through pve-05
- **Isolation**: Dedicated for storage traffic
- **Note**: Should have high bandwidth, low latency

## Firewall Integration

After SDN creation, consider implementing:

```bash
# Allow inter-VLAN routing (if needed)
pve-firewall enable

# Configure firewall rules per VLAN
pvesh create /nodes/{node}/firewall/rules ...
```

## Troubleshooting

### SDN Not Available
```bash
# Check if SDN is supported
pvesh get /cluster/sdn

# Verify Proxmox version (6.2+)
pveversion
```

### Network Not Appearing
```bash
# Check zone status
pvesh get /cluster/sdn/zones

# Check network status
pvesh get /cluster/sdn/vnets

# Reload SDN configuration
pvesh set /cluster/sdn --reload 1
```

### VLAN Tagging Issues
- Verify bridge interface configuration
- Check upstream switch VLAN trunk configuration
- Confirm VLAN IDs match switch configuration

## Next Steps

1. Configure firewall rules per VLAN
2. Set up inter-VLAN routing (if multi-datacenter)
3. Configure failover gateways
4. Implement network monitoring
5. Plan IP address management (IPAM)

## References

- [Proxmox SDN Documentation](https://pve.proxmox.com/wiki/Software-Defined_Networking_(SDN))
- [VLAN Configuration](https://pve.proxmox.com/wiki/Network_Configuration#VLAN_(802.1q))
