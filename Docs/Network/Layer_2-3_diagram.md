# Layer 2 / Layer 3 Network Design

This document describes the **logical network design** (L2 + L3) for the SinLess Games infrastructure as configured in the UniFi Controller.

It includes:
- VLAN IDs, names, and subnets (as per UniFi)
- Gateway addressing & routing model
- Layer 2 topology (switching, trunks)
- DHCP configuration per VLAN
- IP assignment plan for infrastructure devices

---

## 1. VLAN & Subnet Overview

All VLANs are routed by the **USG Pro 4**, using a classic "router-on-a-stick" design with VLAN interfaces on the LAN side. This configuration matches the UniFi Controller network settings.

| VLAN ID | Name             | Subnet         | Gateway IP     | DHCP Range        | Purpose                                      |
|--------:|------------------|----------------|----------------|-------------------|----------------------------------------------|
| 1       | Infrastructure   | 10.10.10.0/24  | 10.10.10.1     | 10.10.10.100–199  | Proxmox mgmt, cluster, core infrastructure   |
| 20      | Development      | 10.10.20.0/24  | 10.10.20.1     | 10.10.20.100–199  | Dev VMs, development workloads                |
| 30      | Testing          | 10.10.30.0/24  | 10.10.30.1     | 10.10.30.100–199  | QA, staging, testing environment             |
| 40      | Production       | 10.10.40.0/24  | 10.10.40.1     | 10.10.40.100–199  | Production workloads & VMs                    |
| 50      | DMZ              | 10.10.50.0/24  | 10.10.50.1     | 10.10.50.100–199  | Edge/reverse proxies, bastions, tunnels       |
| 60      | Ceph             | 10.10.60.0/24  | 10.10.60.1     | 10.10.60.100–199  | Ceph cluster storage network                  |

---

## 2. IP Allocation Plan

### 2.1 General Allocation Strategy

For each /24 subnet:

- `.1` = VLAN gateway (USG Pro 4)
- `.2–.19` = Core infrastructure (Proxmox nodes, DNS, etc.)
- `.20–.99` = Additional servers and static assignments
- `.100–.199` = DHCP range for dynamic allocation
- `.200–.254` = Reserved for future use

### 2.2 VLAN 1 – Infrastructure (10.10.10.0/24)

Core management and cluster networking:

- **10.10.10.1** – USG Pro 4 gateway
- **10.10.10.15** – pve-01 (Proxmox management)
- **10.10.10.16** – pve-02 (Proxmox management)
- **10.10.10.17** – pve-03 (Proxmox management)
- **10.10.10.18** – pve-04 (Proxmox management)
- **10.10.10.19** – pve-05 (Proxmox management)
- **10.10.10.100–199** – DHCP range (205 available IPs)

### 2.3 VLAN 20 – Development (10.10.20.0/24)

Development workloads and VMs:

- **10.10.20.1** – USG Pro 4 gateway
- **10.10.20.2–.99** – Reserved for dev VM static assignments
- **10.10.20.100–199** – DHCP range (249 available IPs)

### 2.4 VLAN 30 – Testing (10.10.30.0/24)

Testing and QA environment:

- **10.10.30.1** – USG Pro 4 gateway
- **10.10.30.2–.99** – Reserved for test VM static assignments
- **10.10.30.100–199** – DHCP range (249 available IPs)

### 2.5 VLAN 40 – Production (10.10.40.0/24)

Production workloads:

- **10.10.40.1** – USG Pro 4 gateway
- **10.10.40.2–.99** – Reserved for production VM static assignments
- **10.10.40.100–199** – DHCP range (249 available IPs)

### 2.6 VLAN 50 – DMZ (10.10.50.0/24)

Edge and externally-facing systems:

- **10.10.50.1** – USG Pro 4 gateway
- **10.10.50.2–.99** – Reserved for DMZ systems (reverse proxies, bastions)
- **10.10.50.100–199** – DHCP range (249 available IPs)

### 2.7 VLAN 60 – Ceph (10.10.60.0/24)

Dedicated Ceph cluster storage network:

- **10.10.60.1** – USG Pro 4 gateway
- **10.10.60.2–.99** – Reserved for Ceph nodes and storage endpoints
- **10.10.60.100–199** – DHCP range (249 available IPs)

---

## 3. Layer 2 Topology

### 3.1 Physical Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         ISP / WAN                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  USG Pro 4   │
                  │  (Gateway)   │
                  └──────┬───────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
      (LAN1)        (LAN2)      (SFP+ Trunk)
          │              │              │
    ┌─────────┐    ┌─────────┐    ┌────────────┐
    │ USW-24  │◄──►│ USW-24  │◄──►│ USW Agg    │
    │(Core)   │    │(Access) │    │(8-SFP+)    │
    │Switch 1 │    │Switch 2 │    │            │
    └────┬────┘    └────┬────┘    └─────┬──────┘
         │              │                │
    ┌────┴──────────────┴────────────────┴────┐
    │                                         │
    ▼              ▼              ▼           ▼
  pve-01        pve-02        pve-03     pve-04/05
 (10Gb Trunk)  (10Gb Trunk)  (10Gb Trunk)  (1Gb)
```

### 3.2 VLAN Trunk Configuration

**All switches and Proxmox nodes carry the following VLANs on trunk ports:**
- VLAN 1 (Infrastructure) – Native/untagged
- VLAN 20 (Development)
- VLAN 30 (Testing)
- VLAN 40 (Production)
- VLAN 50 (DMZ)
- VLAN 60 (Ceph)

**Trunk Links:**
- USG Pro 4 → USW-24-1 (Core): Full trunk with all VLANs
- USG Pro 4 → USW-24-2 (Access): Full trunk with all VLANs
- USW-24-1 → USW Aggregation: 10Gb SFP+ trunk (VLANs 20, 30, 40, 50)
- USW Aggregation → Proxmox nodes: 10Gb trunk links for each node
- Proxmox nodes: Virtual bridge `vmbr0` with VLAN tagging

### 3.3 Access Ports

- **Management access**: Selected ports on USW-24-1 and USW-24-2 in VLAN 1
- **User/device access**: Separate ports per VLAN or dynamic (port security/802.1X)

---

## 4. Proxmox Bridge Configuration

Each Proxmox node hosts one or more virtual bridges for VM networking:

### 4.1 vmbr0 (Primary VM Bridge)
- **Type**: VLAN-aware bridge
- **Physical ports**: Aggregation switch trunk connections
- **Features**: 
  - VLAN filtering enabled
  - Supports tagged and untagged traffic
  - STP enabled for loop prevention
- **Usage**: Primary bridge for all VMs requiring VLAN access

### 4.2 vmbr1 (Secondary VM Bridge - Optional)
- **Type**: VLAN-aware bridge (future use)
- **Physical ports**: None (reserved)
- **Usage**: Future expansion or isolated VM networks

---

## 5. Network Communication Paths

### 5.1 Intra-VLAN Communication (same subnet)

**Example: Two VMs on VLAN 40 (Production)**

```
VM A (10.10.40.50)
    │
    ▼ (direct MAC switching)
  vmbr0 (pve-03)
    │ (tagged frame on physical trunk)
    ▼
USW Aggregation
    │ (L2 switching)
    ▼
vmbr0 (pve-01)
    │
    ▼ (untagged at VM)
VM B (10.10.40.60)
```

### 5.2 Inter-VLAN Communication (different subnets)

**Example: VM on VLAN 20 → VM on VLAN 40**

```
VM A (10.10.20.50)
    │
    ▼ (sends frame to gateway MAC)
  vmbr0 (pve-03)
    │ (tagged VLAN 20 on trunk)
    ▼
USW Aggregation
    │
    ▼
USG Pro 4 (routing engine)
    │ (checks route table)
    ▼
USW Aggregation
    │ (tagged VLAN 40 on trunk back)
    ▼
vmbr0 (pve-01)
    │
    ▼ (untagged at VM)
VM B (10.10.40.60)
```

---

## 6. DNS & DHCP

### 6.1 DNS Resolution
- **Primary DNS**: Technitium DNS (to be deployed on VLAN 20)
- **Fallback**: Public DNS (1.1.1.1, 8.8.8.8)
- **Per-VLAN**: Each VLAN receives DNS configuration via DHCP

### 6.2 DHCP Services
- **DHCP Server**: USG Pro 4 (built-in)
- **Per-VLAN DHCP ranges**: As specified in section 2
- **DHCP options**: Gateway, DNS, NTP, domain search

---

## 7. Proxmox Integration

### 7.1 Node Network Configuration

Each Proxmox node has:

1. **Management interface** (eno1): VLAN 1 (Infrastructure)
   - Static IP from range 10.10.10.15–19
   - Used for cluster communication and Proxmox API

2. **Virtual bridges** (vmbr0, vmbr1): VLAN-aware
   - Carry traffic for all VMs
   - Support all VLANs (1, 20, 30, 40, 50, 60)
   - Connected to aggregation switch via 10Gb trunk

### 7.2 Cluster Communication

- **Cluster network**: 10.10.10.0/24 (VLAN 1 / Infrastructure)
- **Quorum device**: Proxmox Cluster Quorum (3 nodes minimum)
- **Corosync**: Uses eth0 (eno1) on each node

### 7.3 Ceph Storage Network

- **Dedicated VLAN**: VLAN 60 (Ceph, 10.10.60.0/24)
- **Purpose**: Isolate Ceph replication and heartbeat traffic
- **Configuration**: Ceph network settings in `ceph.conf`

---

## 8. Network Monitoring & Troubleshooting

### 8.1 UniFi Controller
- **Status**: Active and configured
- **Location**: Deployed on one of the infrastructure VMs
- **Data**: Upstream traffic, VLAN stats, device inventory

### 8.2 Network Diagnostics
- **Ping**: Test L3 connectivity (ICMP)
- **MTR/traceroute**: Trace path through gateways
- **tcpdump**: Capture VLAN-tagged frames on Proxmox bridges
- **ethtool**: Check NIC status and link speed

### 8.3 Documentation Maintenance
- Update this file when VLAN definitions change in UniFi
- Sync with UniFi Controller configuration regularly
- Document any custom VLAN or bonding configurations

---

## 9. Future Expansion

### 9.1 Potential Additions
- **VLAN 70**: Reserved for IoT/monitoring devices
- **VLAN 80**: Reserved for guest/temporary access
- **Secondary Ceph network**: Dedicated cluster network (10.10.61.0/24)
- **Out-of-band management**: Dedicated IPMI/iDRAC network

### 9.2 Scaling Considerations
- Current design supports up to 254 devices per VLAN
- 10Gb aggregation allows room for future Proxmox nodes
- Multiple USW Aggregation units can be daisy-chained if needed

---

**Last Updated**: January 29, 2026  
**Source**: UniFi Controller network configuration  
**Maintained By**: Ansible role `proxmox-networking`  
**Related Docs**: 
- `Port-Map.md` – Physical port assignments
- `Rack-Diagram.md` – Hardware layout

