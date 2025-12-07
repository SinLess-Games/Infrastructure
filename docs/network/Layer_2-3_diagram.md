# Layer 2 / Layer 3 Network Design

This document describes the **logical network design** (L2 + L3) for the SinLess Games infrastructure rack:

- VLAN IDs, names, colors, and subnets  
- Gateway addressing & routing model  
- Layer 2 topology (switching, trunks, access ports)  
- DHCP vs static allocation plan  
- Example IP assignments for core devices  

It is intended to complement:

- `docs/network/Port-Map.md`  
- `docs/network/Rack-Diagram.*`  

---

## 1. VLAN & Subnet Overview

All VLANs are routed by the **USG Pro 4**, using a classic “router-on-a-stick” design with VLAN interfaces on the LAN side.

| VLAN ID | Name             | Color  | Subnet         | Gateway IP     | Purpose                                      |
|--------:|------------------|--------|----------------|----------------|----------------------------------------------|
| 10      | Mgmt             | Blue   | 10.10.10.0/24  | 10.10.10.1     | Proxmox mgmt, iDRAC, switch mgmt, infra OOB  |
| 20      | Infra / Services | Green  | 10.10.20.0/24  | 10.10.20.1     | Vault, GitLab, MinIO, Technitium, Authentik… |
| 30      | Kubernetes       | Purple | 10.10.30.0/24  | 10.10.30.1     | Flatcar K8s nodes (control-plane & workers)  |
| 40      | Storage / Ceph   | Orange | 10.10.40.0/24  | 10.10.40.1     | Proxmox Ceph, Rook/Ceph traffic              |
| 50      | DMZ              | Red    | 10.10.50.0/24  | 10.10.50.1     | Edge / reverse proxies / bastions / tunnels  |
| 60      | Dev / Desktop    | Yellow | 10.10.60.0/24  | 10.10.60.1     | Workstations, laptops, AP clients            |

> **Note:** VLAN 40 may also have a dedicated “cluster” Ceph subnet later (e.g. 10.10.41.0/24) carried on the same trunks; that can be documented separately under storage.

---

## 2. IP Allocation Plan

### 2.1 General Allocation Strategy

For each /24:

- `.1` = VLAN gateway (USG Pro 4)  
- `.2–.19` = Core infra (switches, Proxmox, Ceph, DNS, Vault, GitLab, MinIO, Boundary, Authentik…)  
- `.20–.99` = Servers / nodes (K8s nodes, extra infra VMs)  
- `.100–.199` = DHCP range for that VLAN (if applicable)  
- `.200–.254` = Reserved / future static

### 2.2 VLAN 10 – Mgmt (10.10.10.0/24)

- 10.10.10.1 – USG Pro 4 VLAN10 interface  
- 10.10.10.2 – Core Switch (USW-24-1) mgmt  
- 10.10.10.3 – Access Switch (USW-24-2) mgmt  
- 10.10.10.4 – Aggregation Switch mgmt  
- 10.10.10.5 – pve-01 mgmt (vmbr0 / NIC1)  
- 10.10.10.6 – pve-02 mgmt  
- 10.10.10.7 – pve-03 mgmt  
- 10.10.10.8 – pve-01 iDRAC  
- 10.10.10.9 – (Reserved for possible lights-out mgmt of tower/others)  
- 10.10.10.100–10.10.10.199 – DHCP (optional, for temporary mgmt devices / laptops on mgmt net)  

### 2.3 VLAN 20 – Infra / Services (10.10.20.0/24)

Sample static assignments:

- 10.10.20.1 – USG Pro 4 VLAN20 interface  
- 10.10.20.2 – Vault-01  
- 10.10.20.3 – Vault-02  
- 10.10.20.4 – Vault-03  
- 10.10.20.5 – GitLab-01  
- 10.10.20.6 – MinIO-01  
- 10.10.20.7 – Technitium DNS-01  
- 10.10.20.8 – Technitium DNS-02 (future)  
- 10.10.20.9 – Authentik-01  
- 10.10.20.10 – Boundary Controller  
- 10.10.20.11 – Wazuh Manager  
- 10.10.20.12 – PBS-01 (Proxmox Backup Server)  
- 10.10.20.20–10.10.20.99 – Server & VM statics (infra VMs)  
- 10.10.20.100–10.10.20.199 – DHCP range (if you want PXE or DHCP for infra)  

### 2.4 VLAN 30 – Kubernetes (10.10.30.0/24)

- 10.10.30.1 – USG Pro 4 VLAN30 interface  
- 10.10.30.2–10.10.30.19 – Reserved (future control-plane VIPs, etc.)  
- 10.10.30.20–10.10.30.49 – Staging cluster:
  - 10.10.30.20–22 – stg-cp-[01..03]  
  - 10.10.30.30–31 – stg-wrk-[01..02]  
- 10.10.30.50–10.10.30.99 – Prod cluster:
  - 10.10.30.50–54 – prd-cp-[01..05]  
  - 10.10.30.60–66 – prd-wrk-[01..07]  
- 10.10.30.100–10.10.30.199 – DHCP if needed for auto-join nodes  

### 2.5 VLAN 40 – Storage / Ceph (10.10.40.0/24)

- 10.10.40.1 – USG Pro 4 VLAN40 interface (for routing/monitoring)  
- 10.10.40.2 – pve-01 Ceph IP  
- 10.10.40.3 – pve-02 Ceph IP  
- 10.10.40.4 – pve-03 Ceph IP  
- 10.10.40.5+ – Additional storage or Rook Ceph traffic entry points  

> For Ceph, you may want:
>
> - `public_network = 10.10.40.0/24`  
> - `cluster_network = 10.10.41.0/24` (future, carried on the same physical 10G trunk)  

### 2.6 VLAN 50 – DMZ (10.10.50.0/24)

- 10.10.50.1 – USG Pro 4 VLAN50 interface  
- 10.10.50.2 – Edge reverse proxy / HA pair (if running on VMs)  
- 10.10.50.3 – Bastion host (SSH / Boundary worker)  
- 10.10.50.4 – Cloudflare Tunnel endpoint(s)  
- 10.10.50.5+ – Any public-edge or internet-facing systems  

### 2.7 VLAN 60 – Dev / Desktop (10.10.60.0/24)

- 10.10.60.1 – USG Pro 4 VLAN60 interface  
- 10.10.60.2 – dev-01 (your main workstation)  
- 10.10.60.3+ – Laptop, other desktops, lab clients, AP clients  
- 10.10.60.100–10.10.60.199 – DHCP pool for general devices  

---

## 3. Layer 2 Topology (Switching & Trunks)

### 3.1 Core Switching Model

- **USG Pro 4** is the **default gateway** for all VLANs.  
- **USW-24-1** is the **core switch** – all trunks converge here.  
- **USW-24-2** is the **secondary/access switch**, linked to both USG (LAN2) and USW-24-1 (SFP+ L2 trunk).  
- **USW Aggregation (8-port SFP+)** provides **10Gb backplane** for all Proxmox nodes.

High-level L2 diagram:

```mermaid
graph TD
  ISP[ISP / Modem] -->|WAN| USG[USG Pro 4]

  USG -->|LAN1 (Trunk 10/20/30/40/50/60)| SW1[USW-24-1 (Core)]
  USG -->|LAN2 (Trunk 10/20/30/40/50/60)| SW2[USW-24-2 (Access)]

  SW1 -->|SFP+ Trunk 20/30/40/50| AGG[USW Aggregation (8-port SFP+)]
  SW1 -->|SFP+ Trunk 10/20/30/40/50/60| SW2

  AGG -->|10Gb Trunks 20/30/40/50| PVE1[pve-01]
  AGG -->|10Gb Trunks 20/30/40/50| PVE2[pve-02]
  AGG -->|10Gb Trunks 20/30/40/50| PVE3[pve-03]

  SW1 -->|Access 10/20/50| Patch[Patch Panel → Servers RJ45]
  SW1 -->|Access 60| DevPorts[Desk / AP Ports]
````

### 3.2 Trunk Links

- **USG LAN1 → SW1 Port 1**

  - Trunk: VLANs 10,20,30,40,50,60

- **USG LAN2 → SW2 Port 1**

  - Trunk: VLANs 10,20,30,40,50,60 (backup uplink)

- **SW1 SFP+ Port 25 → AGG Port 1**

  - Trunk: VLANs 20,30,40,50 (infra/K8s/Storage/DMZ)

- **SW1 SFP+ Port 26 → SW2 SFP+ Port 25**

  - Trunk: VLANs 10,20,30,40,50,60 (inter-switch)

- **AGG Ports 2–7 → pve-01/02/03 SFP+ NICs**

  - Trunks: VLANs 20,30,40,50

### 3.3 Access Ports (Examples)

- **VLAN 10 (Mgmt)**:

  - SW1 ports mapped via patch to pve-0x mgmt NICs and iDRAC.
- **VLAN 20 (Infra)**:

  - SW1 ports → patch → RJ45 NICs of Proxmox/PC/Infra VMs as needed.
- **VLAN 50 (DMZ)**:

  - Dedicated access ports for DMZ RJ45, firewall sidecar appliances, or DMZ VMs if bridged.
- **VLAN 60 (Dev)**:

  - Desk drops & APs on access VLAN 60.

All of this is already mapped concretely in `Port-Map.md`.

---

## 4. Layer 3 Routing Model

### 4.1 Default Gateway & Inter-VLAN Routing

- All VLANs have their **gateway on the USG Pro 4**:

  - `10.10.10.1` (VLAN10), `10.10.20.1`, `10.10.30.1`, etc.
- **USG performs all inter-VLAN routing.**

  - Example: traffic from `10.10.60.0/24` (dev) to `10.10.20.0/24` (infra) goes through USG.

### 4.2 Firewall Policy (High-Level)

You can implement a **default-deny** policy between VLANs and then punch holes as needed. Example conceptual rules:

1. **Mgmt (10)**

   - Allowed to: Infra (20), K8s (30), Ceph (40), DMZ (50) for admin protocols (HTTPS/SSH/ICMP).
   - Blocked from: General Dev (60) initiating back to Mgmt by default.

2. **Infra (20)**

   - Can reach: K8s API (30), Ceph monitoring (40), DMZ (for frontends & tunnels), outbound to internet as needed.

3. **Kubernetes (30)**

   - Nodes need egress to:

     - Infra services (20): DNS, Vault, GitLab, MinIO, Observability.
     - DMZ (50): Ingress/Egress gateways.
   - Lock down inbound to only necessary ports (API, metrics, etc.).

4. **Storage / Ceph (40)**

   - Primarily node-to-node inside same VLAN; route to Mgmt (10) & Infra (20) for monitoring only.

5. **DMZ (50)**

   - Inbound: from Internet via WAN → NAT → DMZ.
   - Outbound: restricted to Infra (20) / K8s (30) / Vault (20) as needed for app backends and auth.

6. **Dev / Desktop (60)**

   - Developers can reach:

     - K8s API (via Boundary or direct, as you prefer).
     - Grafana, GitLab, Vault UIs (via SSO).
   - Optionally block direct access from Dev to Mgmt VLAN except through Boundary / VPN.

> You should mirror this logic in your USG firewall groups and document final rule sets under a separate `Firewall-Policy.md` later.

---

## 5. Unifi Port Profiles

Define Unifi port profiles that match the VLANs and trunk usage:

### 5.1 Access Profiles

- **`Mgmt-Access`**

  - Native VLAN: 10
  - Tagged: none

- **`Infra-Access`**

  - Native VLAN: 20

- **`K8s-Access`** (rarely needed; most K8s traffic runs over 10G trunks)

  - Native VLAN: 30

- **`DMZ-Access`**

  - Native VLAN: 50

- **`Dev-Access`**

  - Native VLAN: 60

### 5.2 Trunk Profiles

- **`Core-Trunk-All`** (USG ↔ SW1, USG ↔ SW2, SW1 ↔ SW2)

  - Tagged VLANs: 10,20,30,40,50,60
  - Native VLAN: none (or Mgmt, if you intentionally choose one – but better to leave none & rely on tagging).

- **`Agg-Trunk`** (SW1 ↔ AGG)

  - Tagged VLANs: 20,30,40,50
  - Native VLAN: none

- **`Server-10G-Trunk`** (AGG ↔ Proxmox nodes SFP+)

  - Tagged VLANs: 20,30,40,50
  - Native VLAN: none

---

## 6. Example Device Summary

### 6.1 Routing Core

- **USG Pro 4**

  - WAN1: ISP
  - WAN2: unused / future
  - LAN1: `Core-Trunk-All` → USW-24-1 Port 1
  - LAN2: `Core-Trunk-All` → USW-24-2 Port 1

### 6.2 Switch Core

- **USW-24-1 (Core)**

  - Port 1: USG LAN1 (Core trunk)
  - Port 25: `Agg-Trunk` → Aggregation SFP+ Port 1
  - Port 26: `Core-Trunk-All` → SW2 SFP+ Port 25

- **USW-24-2 (Access)**

  - Port 1: USG LAN2 (Core trunk / backup)
  - Port 25: `Core-Trunk-All` → SW1 SFP+ Port 26

- **USW Aggregation**

  - Port 1: `Agg-Trunk` → SW1 SFP+ Port 25
  - Ports 2–7: `Server-10G-Trunk` → pve-01/02/03 SFP+

---

## 7. Future Extensions

Potential documented future additions:

- **Ceph cluster_network on 10.10.41.0/24**

  - Use secondary VLAN or IP addressing on same physical 10G links.
- **Out-of-band dedicated mgmt switch**

  - If iDRAC and IPMI expand, document a dedicated mgmt-only switch.
- **Site-to-site / remote-access VPN**

  - WireGuard or IPSec subnets, peers, allowed routes.
- **Cloud extension**

  - Document how hybrid worker nodes in Linode/AWS/GCP/Azure connect:

    - Typically via WireGuard / IPSec into VLAN 30+20 networks.

---

## 8. Files That Should Reference This Diagram

- `docs/network/Port-Map.md` – physical ports → VLAN → IPs
- `docs/network/Rack-Diagram.md` / `.svg` – physical placement
- `docs/network/Firewall-Policy.md` – actual USG firewall rules
- `docs/proxmox/Cluster-Networking.md` – vmbr/VLAN mapping per node
- `docs/kubernetes/Cluster-Networking.md` – PodCIDR, ServiceCIDR, Cilium config

This document is the **authoritative source of truth** for:

- VLAN IDs and addresses
- Gateway IPs
- Trunk vs access designation
- High-level routing model
