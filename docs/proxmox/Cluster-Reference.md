# Proxmox Cluster Reference

This document defines the authoritative configuration for the Proxmox cluster, its nodes, Ceph storage design, and the VM allocation model used for core infrastructure services.

It is intended to provide consistent, repeatable documentation for operational use, lifecycle management, troubleshooting, and disaster recovery.

---

# 1. Proxmox Cluster Overview

Cluster Name: **SinLess-Games**  
Nodes: **pve-01**, **pve-02**, **pve-03**  
Backend Storage: **Ceph (Proxmox-integrated)**  
Networking:  

- Management (VLAN 10)  
- Infra/Services (VLAN 20)  
- Kubernetes/Nodes (VLAN 30)  
- Storage (VLAN 40)  
- DMZ (VLAN 50)  

---

# 2. Proxmox Node Reference

Each node section includes CPU, memory, disk layout, NIC diagrams, BIOS settings, and out-of-band management information.

---

## 2.1 Node: pve-01 (Dell R710)

### Hardware Summary

- **Model:** Dell PowerEdge R710  
- **CPU:**  
  - Model: *(Fill in exact CPU model)*  
  - Count: *(e.g., 2× Xeon X5670)*  
- **RAM:** *(e.g., 96 GB DDR3 ECC)*  

### Drive Layout

| Slot     | Device | Capacity | Type     | Purpose                |
|----------|--------|----------|----------|------------------------|
| Bay 1    | …      | …        | SSD/HDD  | Ceph OSD               |
| Bay 2    | …      | …        | SSD/HDD  | Ceph OSD               |
| Bay 3    | …      | …        | SSD/HDD  | OS / Boot              |
| Bay 4    | …      | …        | SSD/HDD  | Ceph OSD               |
| Internal | …      | …        | USB/SATA | Proxmox boot (if used) |

*(Fill in physical drive inventory once finalized.)*

### NIC Layout Diagram

```

[Rear View – pve-01]

Onboard NICs:
NIC1  NIC2  NIC3  NIC4
|      |      |      |
|      |      |      └─→ VLAN 50 (DMZ)
|      |      └────────→ VLAN 20 (Infra)
|      └───────────────→ VLAN 20 (Infra)
└──────────────────────→ VLAN 10 (Mgmt)

Expansion NIC (Quad Port):
EN1  EN2  EN3  EN4
|     |     |     |
|     |     |     └─→ Spare
|     |     └──────→ Spare
|     └────────────→ VLAN 50 (DMZ)
└──────────────────→ VLAN 20 (Infra)

10Gb SFP+ NIC:
SFP+1 — Trunk (20/30/40/50)
SFP+2 — Trunk (20/30/40/50, Ceph priority)

iDRAC (Dedicated):
iDRAC — VLAN 10 (Mgmt)

```

### Boot Order

1. SSD/Primary boot drive  
2. Secondary SSD  
3. PXE (disabled or optional)  
4. USB (disabled)  

### BIOS / Firmware

- **BIOS Version:** *Fill in*  
- **Lifecycle Controller:** *Fill in*  
- **iDRAC:**  
  - Version: *Fill in*  
  - IP: 10.10.10.8  
  - User: documented in Vault  

---

## 2.2 Node: pve-02 (Dell R710 – No iDRAC)

### Hardware Summary

- **Model:** Dell PowerEdge R710  
- **CPU:** *(Fill in)*  
- **RAM:** *(Fill in)*  

### Drive Layout

*(Populate based on actual drives)*

### NIC Layout Diagram

```

[Rear View – pve-02]

Onboard NICs:
NIC1 — VLAN 10 (Mgmt)
NIC2 — VLAN 20 (Infra)
NIC3 — VLAN 50 (DMZ)
NIC4 — Spare (VLAN 20)

10Gb SFP+ NIC:
SFP+1 — Trunk (20/30/40/50)
SFP+2 — Trunk (20/30/40/50, Ceph priority)

(No iDRAC)

```

### Boot Order

Same as pve-01.

### BIOS Version

*Fill in.*

---

## 2.3 Node: pve-03 (Tower Server)

### Hardware Summary

- **Model:** *(Fill in)*  
- **CPU:** *(Fill in)*  
- **RAM:** *(Fill in)*  

### Drive Layout

*(Fill once drive list is known)*

### NIC Diagram

```

Onboard NICs:
NIC1 — VLAN 10 (Mgmt)
NIC2 — VLAN 20 (Infra)
NIC3 — VLAN 50 (DMZ)
NIC4 — Spare (Infra)

10Gb SFP+ NIC:
SFP+1 — Trunk (20/30/40/50)
SFP+2 — Trunk (20/30/40/50, Ceph priority)

```

### Boot Order & BIOS

*Fill in once inventoried.*

---

# 3. Ceph Configuration Documentation

Your Proxmox cluster uses **Ceph for VM storage** and **Rook-Ceph for Kubernetes (separate)**.  
This section documents the Proxmox Ceph cluster only.

---

## 3.1 OSD Layouts

| Node   | OSD ID | Device   | Capacity | Type    | DB/WAL | Notes |
|--------|--------|----------|----------|---------|--------|-------|
| pve-01 | 0      | /dev/sdX | …        | SSD/HDD | …      |       |
| pve-01 | 1      | /dev/sdY | …        | SSD/HDD | …      |       |
| pve-02 | 2      | /dev/sdX | …        | SSD/HDD | …      |       |
| pve-03 | 3      | /dev/sdX | …        | SSD/HDD | …      |       |
*(Fill based on actual Ceph deployment.)*

---

## 3.2 MON / MGR Distribution

| Role | Location                  |
|------|---------------------------|
| MON1 | pve-01                    |
| MON2 | pve-02                    |
| MON3 | pve-03                    |
| MGR1 | pve-01                    |
| MGR2 | pve-02 (optional standby) |

---

## 3.3 Ceph Networks

| Network Role    | Subnet        | VLAN        | Notes                                      |
|-----------------|---------------|-------------|--------------------------------------------|
| Public Network  | 10.10.40.0/24 | 40          | Client-facing traffic, OSD heartbeats      |
| Cluster Network | 10.10.41.0/24 | 40 (future) | OSD replication; optional dedicated subnet |

---

## 3.4 Pools & Placement Groups

### Recommended Pools

| Pool Name      | Purpose                | Replication | PG Count | Notes                                 |
|----------------|------------------------|-------------|----------|---------------------------------------|
| vmstorage      | VM disks (Proxmox)     | 3           | Fill in  | Default high-availability data        |
| images         | ISO & template storage | 2 or 3      | Fill in  | Optional                              |
| backups (opt.) | Ceph backup pool       | 2           | Fill in  | Not required if PBS is primary backup |

---

# 4. VM Allocation Plan

This section documents each **core infrastructure VM** hosted on Proxmox.  
These VMs support your entire platform (Vault, GitLab, MinIO, DNS, etc.).

---

## 4.1 Vault Cluster (3 VMs)

| VM Name  | CPU | RAM | Storage Pool | Disk Size | VLAN | IP         | Notes       |
|----------|-----|-----|--------------|-----------|------|------------|-------------|
| vault-01 | 2C  | 4GB | Ceph         | 40GB      | 20   | 10.10.20.2 | Raft leader |
| vault-02 | 2C  | 4GB | Ceph         | 40GB      | 20   | 10.10.20.3 |             |
| vault-03 | 2C  | 4GB | Ceph         | 40GB      | 20   | 10.10.20.4 |             |

**Backup Policy:**  

- Nightly snapshot → PBS  
- Weekly full back-up  
- Monthly export (encrypted)  

---

## 4.2 GitLab VM

| Field | Value                              |
|-------|------------------------------------|
| CPU   | 6 cores                            |
| RAM   | 16 GB                              |
| Disk  | 200GB (Ceph pool)                  |
| VLAN  | 20                                 |
| IP    | 10.10.20.5                         |
| Notes | GitLab, registry, runners optional |

Backup:

- PBS nightly snapshot  
- Weekly MinIO offload for repo tarballs  

---

## 4.3 MinIO VM

| Field | Value                                            |
|-------|--------------------------------------------------|
| CPU   | 4 cores                                          |
| RAM   | 8 GB                                             |
| Disk  | 1× 500GB Ceph RBD                                |
| VLAN  | 20                                               |
| IP    | 10.10.20.6                                       |
| Notes | S3 backend for Mimir/Loki/Tempo/Pyroscope/Velero |

Backup:

- PBS snapshots  
- Optional replication to cloud S3  

---

## 4.4 Technitium DNS VM

| Field | Value      |
|-------|------------|
| CPU   | 2 cores    |
| RAM   | 2 GB       |
| Disk  | 20GB       |
| VLAN  | 20         |
| IP    | 10.10.20.7 |

Backup:

- PBS nightly snapshot  

---

## 4.5 Authentik VM

| Field | Value      |
|-------|------------|
| CPU   | 2 cores    |
| RAM   | 4 GB       |
| Disk  | 40GB       |
| VLAN  | 20         |
| IP    | 10.10.20.9 |

Backup:

- PBS snapshot  
- Backup of PostgreSQL DB (external or local container volume)  

---

## 4.6 Boundary Controller VM

| Field | Value       |
|-------|-------------|
| CPU   | 2 cores     |
| RAM   | 4 GB        |
| Disk  | 40GB        |
| VLAN  | 20          |
| IP    | 10.10.20.10 |

Backup:

- PBS snapshot  
- Config/state stored in PostgreSQL  

---

## 4.7 Mailu (Optional as VM or Kubernetes Deployment)

If VM:

| Field | Value                             |
|-------|-----------------------------------|
| CPU   | 4 cores                           |
| RAM   | 8 GB                              |
| Disk  | 100GB                             |
| VLAN  | 20 or 50 (depending on MX design) |
| Notes | DMZ recommended for inbound mail  |

---

## 4.8 PBS (Proxmox Backup Server)

| Field | Value                              |
|-------|------------------------------------|
| CPU   | 4 cores                            |
| RAM   | 8 GB                               |
| Disk  | Large pool (local SSD or Ceph RBD) |
| VLAN  | 20                                 |
| IP    | 10.10.20.12                        |

Backup:

- Holds VM backup schedules  
- Receives nightly snapshots  
- Optional sync to MinIO or external disk for DR  

---

# 5. Backup Policies Summary

| Component      | Backup Method                         | Frequency        |
|----------------|---------------------------------------|------------------|
| Proxmox VMs    | PBS                                   | Nightly          |
| Vault          | Raft snapshots + PBS + offline export | Nightly / Weekly |
| MinIO          | Versioned S3 replication              | Continuous       |
| GitLab         | PBS + external repo export            | Nightly / Weekly |
| Technitium DNS | PBS                                   | Nightly          |
| Authentik      | PBS + DB backup                       | Nightly          |
| Boundary       | PBS + DB backup                       | Nightly          |
| Ceph           | Automatic replication                 | Continuous       |
| Kubernetes     | Velero to MinIO                       | Nightly          |

---

# 7. Revision History

| Date       | Author     | Change          |
|------------|------------|-----------------|
| YYYY-MM-DD | sinless777 | Initial version |
