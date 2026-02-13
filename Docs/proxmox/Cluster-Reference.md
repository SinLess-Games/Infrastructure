<!-- Docs/proxmox/Cluster-Reference.md -->

# Proxmox Cluster Reference

Authoritative reference for the **SinLess-Games** Proxmox cluster: node inventory, resource envelopes, Ceph integration notes, and placement guidance for core infrastructure workloads.

---

## Node Resource Table

> Source: `pvesh get /cluster/resources --type node` + per-node `lscpu/free/lsblk` outputs.

| Node   | CPU Model                                   | Sockets | Cores/Socket | Threads (maxcpu) | RAM Total (maxmem) | RAM Used (mem) | Local Root Disk Total (maxdisk) | Local Root Used (disk) | Notes |
|--------|---------------------------------------------|---------|--------------|------------------|--------------------|----------------|-------------------------------:|------------------------:|------|
| pve-01 | AMD Ryzen Threadripper 1950X 16-Core        | 1       | 16           | 32               | 102.15 GiB          | 11.39 GiB      | 67.73 GiB                      | 7.45 GiB                | Primary capacity node + multiple Ceph OSDs |
| pve-02 | Intel Core i7-860 @ 2.80GHz                 | 1       | 4            | 8                | 15.61 GiB           | 1.85 GiB       | 66.35 GiB                      | 9.56 GiB                | Small node (avoid HA/quorum workloads) |
| pve-03 | Intel Xeon E5520 @ 2.27GHz                  | 1       | 4            | 8                | 7.74 GiB            | 1.81 GiB       | 45.90 GiB                      | 6.57 GiB                | Very small node (utility/lab only) |
| pve-04 | Intel Xeon L5520 @ 2.27GHz                  | 2       | 4            | 16               | 98.31 GiB           | 10.32 GiB      | 77.66 GiB                      | 6.67 GiB                | Primary capacity node + multiple Ceph OSDs |
| pve-05 | Intel Xeon X5670 @ 2.93GHz                  | 2       | 6            | 24               | 47.12 GiB           | 8.92 GiB       | 93.93 GiB                      | 6.67 GiB                | Mid node + Ceph OSDs |

### Scheduling Guidance (Production Reliability)
- **HA / quorum-critical services** should live on: **pve-01 + pve-04 + pve-05**
- Treat **pve-02** and especially **pve-03** as **non-quorum utility nodes** (lightweight workloads, test, jump boxes, build runners, etc.)

---

## 1. Cluster Overview

- **Cluster Name:** SinLess-Games
- **Nodes:** pve-01, pve-02, pve-03, pve-04, pve-05
- **Proxmox Version (example shown):** pve-manager/9.1.5
- **Backend Storage:** Ceph (Proxmox-integrated)
- **CGroup Mode:** v2 (reported as `cgroup-mode: 2`)

### Network Plan (VLANs)
- **VLAN 10** — Management
- **VLAN 20** — Infra/Services
- **VLAN 30** — Kubernetes/Nodes
- **VLAN 40** — Storage (Ceph, replication, etc.)
- **VLAN 50** — DMZ

> Keep management plane minimal, infra plane private, and strictly control routing between VLANs.

---

## 2. Node Inventory Details

> This section tracks “real hardware” + storage composition. Keep it updated as hardware changes.

### 2.1 pve-01
- **CPU:** AMD Threadripper 1950X (16c/32t)
- **RAM:** 102 GiB
- **Boot Mode:** EFI (from UI screenshot)
- **Storage Notes (lsblk highlights):**
  - Multiple Ceph OSD block LVs (several ~931G, 465G, 2.7T, etc.)
  - Local NVMe (119G) currently hosting `Vault-vm--200` disk (100G)

### 2.2 pve-02
- **CPU:** Intel i7-860 (4c/8t)
- **RAM:** 15.6 GiB
- **Boot Mode:** EFI (from UI screenshot)
- **Storage Notes:**
  - Local OS disk (~233G)
  - Additional local VM VG (~931G)

### 2.3 pve-03
- **CPU:** Intel Xeon E5520 (4c/8t)
- **RAM:** 7.7 GiB
- **Boot Mode:** Legacy BIOS (from UI screenshot)
- **Storage Notes:**
  - Multiple ~148G disks, large LVM LV presentation (~445G shown)

### 2.4 pve-04
- **CPU:** 2× Intel Xeon L5520 (8c/16t total)
- **RAM:** 98 GiB
- **Boot Mode:** Legacy BIOS (from UI screenshot)
- **Storage Notes:**
  - Multiple Ceph OSD block LVs (1.8T, 931G, 931G, 698G)
  - Local disk (~297G) currently hosting `Vault-vm--201` disk (100G)

### 2.5 pve-05
- **CPU:** 2× Intel Xeon X5670 (12c/24t total)
- **RAM:** 47 GiB
- **Boot Mode:** Legacy BIOS (from UI screenshot)
- **Storage Notes:**
  - Ceph OSD block LVs (~931G, ~465G)
  - Local disk hosting `Vault-vm--202` disk (100G)

---

## 3. Ceph (Proxmox-integrated) Reference

This section documents the **Proxmox Ceph cluster only** (not Kubernetes/Rook-Ceph).

### 3.1 Design Intent
- Ceph provides resilient shared VM storage for critical infrastructure.
- OSDs are distributed primarily across **pve-01 / pve-04 / pve-05**.

### 3.2 What to document next (fill as you finalize)
- OSD inventory per node:
  - OSD ID, backing device, size, media type (SSD/HDD/NVMe)
  - DB/WAL placement (if used)
- MON/MGR placement
- Public vs cluster network design (VLAN 40 split if you separate them)
- Pool list + replication/EC policies + PG counts

> Add a generated section later from `ceph -s`, `ceph osd tree`, and `pveceph status`.

---

## 4. Core VM Placement Model

### 4.1 Tier-0 / Quorum-Critical (spread across pve-01, pve-04, pve-05)
- Vault (3 VMs)
- Postgres HA (if used for Authentik/Grafana)
- MinIO (if deployed on VMs) or Object storage nodes
- Any “control-plane” infra that must survive node loss

### 4.2 Utility / Non-critical
- Build runners, dev sandboxes
- Non-critical services
- Test/POC nodes

> Prefer placing these on **pve-02 / pve-03** to keep heavy nodes available for HA workloads.

---

## 5. Immediate Issues / Improvements (Operational)
- **Repository status warning:** “Non production-ready repository enabled” appears in UI screenshots.
  - Decide whether to keep it (lab flexibility) or standardize to production repos for stability.
- **BIOS mode mix:** Some nodes are EFI, some Legacy BIOS.
  - Not urgent, but standardizing boot mode simplifies lifecycle management.

---

## 6. Revision History

| Date       | Author     | Change |
|------------|------------|--------|
| 2026-02-12 | sinless777 | Rebuilt node inventory table from `pvesh` + node hardware outputs |
