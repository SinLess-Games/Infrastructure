# Rack & Network Cabling Plan

## VLANs & Colors

| VLAN ID | Name            | Subnet         | Purpose                               | Color (Labels)  |
|--------|-----------------|----------------|---------------------------------------|-----------------|
| 10     | Mgmt            | 10.10.10.0/24  | Proxmox mgmt, iDRAC, switch mgmt      | Blue            |
| 20     | Infra / Services| 10.10.20.0/24  | Core services (Vault, GitLab, MinIO…) | Green           |
| 30     | Kubernetes      | 10.10.30.0/24  | K8s node-to-node, pod traffic         | Purple          |
| 40     | Storage / Ceph  | 10.10.40.0/24  | Ceph public/cluster, Rook backends    | Orange          |
| 50     | DMZ             | 10.10.50.0/24  | Edge / reverse proxies / bastion      | Red             |
| 60     | Dev / Desktop   | 10.10.60.0/24  | Workstation, APs, general clients     | Yellow          |

Color scheme is for cable labels, patch panel labels, and documentation.

---

## Guide to Abbreviations

- **LAG**: Link Aggregation Group (combining multiple links for redundancy/bandwidth).
- **USG**: Ubiquiti Security Gateway (USG Pro 4).
- **AP**: Access Point.
- **iDRAC**: Integrated Dell Remote Access Controller.
- **Trunk**: Port carrying multiple VLANs (tagged).
- **Access Port**: Port assigned to a single untagged VLAN.
- **VLAN**: Virtual Local Area Network.

---

## Patch Panel 48 Port

> All server RJ45 ports are wired to the patch panel. “Spare” ports are wired or reserved for future devices (APs, desks, DMZ, etc.).

| Port | Device / Endpoint                  | Switch & Port          |
|------|------------------------------------|------------------------|
| 1    | pve-01 Onboard NIC 1 (Mgmt)       | USW-24-1 Port 2        |
| 2    | pve-01 Onboard NIC 2 (Infra)      | USW-24-1 Port 3        |
| 3    | pve-01 Onboard NIC 3 (DMZ)        | USW-24-1 Port 4        |
| 4    | pve-01 Onboard NIC 4 (Spare)      | USW-24-1 Port 5        |
| 5    | pve-01 Expansion NIC 1 (Infra)    | USW-24-1 Port 6        |
| 6    | pve-01 Expansion NIC 2 (DMZ)      | USW-24-1 Port 7        |
| 7    | pve-01 Expansion NIC 3 (Spare)    | USW-24-1 Port 8        |
| 8    | pve-01 Expansion NIC 4 (Spare)    | USW-24-1 Port 9        |
| 9    | pve-01 iDRAC                      | USW-24-1 Port 10       |
| 10   | pve-02 Onboard NIC 1 (Mgmt)       | USW-24-1 Port 11       |
| 11   | pve-02 Onboard NIC 2 (Infra)      | USW-24-1 Port 12       |
| 12   | pve-02 Onboard NIC 3 (DMZ)        | USW-24-1 Port 13       |
| 13   | pve-02 Onboard NIC 4 (Spare)      | USW-24-1 Port 14       |
| 14   | pve-03 Onboard NIC 1 (Mgmt)       | USW-24-1 Port 15       |
| 15   | pve-03 Onboard NIC 2 (Infra)      | USW-24-1 Port 16       |
| 16   | pve-03 Onboard NIC 3 (DMZ)        | USW-24-1 Port 17       |
| 17   | pve-03 Onboard NIC 4 (Spare)      | USW-24-1 Port 18       |
| 18   | pc-01 RJ45                        | USW-24-1 Port 19       |
| 19   | Desk Drop 1 (Dev)                 | USW-24-1 Port 20       |
| 20   | Desk Drop 2 (Dev)                 | USW-24-1 Port 21       |
| 21   | Future AP 1                       | USW-24-1 Port 22       |
| 22   | Future AP 2                       | USW-24-1 Port 23       |
| 23   | Future Infra Device               | USW-24-1 Port 24       |
| 24   | Spare / Future Rack Device        | USW-24-2 Port 2        |
| 25   | Spare / Future Dev Desk           | USW-24-2 Port 3        |
| 26   | Spare / Future Dev Desk           | USW-24-2 Port 4        |
| 27   | Spare / Future Dev Desk           | USW-24-2 Port 5        |
| 28   | Spare / Future Dev Desk           | USW-24-2 Port 6        |
| 29   | Spare / Future Dev Desk           | USW-24-2 Port 7        |
| 30   | Spare / Future Dev Desk           | USW-24-2 Port 8        |
| 31   | Spare / Future Infra Device       | USW-24-2 Port 9        |
| 32   | Spare / Future Infra Device       | USW-24-2 Port 10       |
| 33   | Spare / Future Infra Device       | USW-24-2 Port 11       |
| 34   | Spare / Future Infra Device       | USW-24-2 Port 12       |
| 35   | Spare / Future Infra Device       | USW-24-2 Port 13       |
| 36   | Spare / Future Infra Device       | USW-24-2 Port 14       |
| 37   | Spare / Future DMZ Device         | USW-24-2 Port 15       |
| 38   | Spare / Future DMZ Device         | USW-24-2 Port 16       |
| 39   | Spare / Future DMZ Device         | USW-24-2 Port 17       |
| 40   | Spare / Future DMZ Device         | USW-24-2 Port 18       |
| 41   | Spare / Future DMZ Device         | USW-24-2 Port 19       |
| 42   | Spare / Future DMZ Device         | USW-24-2 Port 20       |
| 43   | Spare / Future DMZ Device         | USW-24-2 Port 21       |
| 44   | Spare / Future DMZ Device         | USW-24-2 Port 22       |
| 45   | Spare / Future DMZ Device         | USW-24-2 Port 23       |
| 46   | Spare / Future DMZ Device         | USW-24-2 Port 24       |
| 47   | Spare (Not Yet Patched)           | Not connected          |
| 48   | Spare (Not Yet Patched)           | Not connected          |

---

## Ubiquiti Security Gateway Pro 4 (USG Pro 4) Port Mapping

| USG Port | Connected Device    | Port on Device      | VLAN Assignment                                |
|----------|---------------------|---------------------|-----------------------------------------------|
| WAN 1    | ISP Modem / ONT     | Modem Port          | Untagged WAN                                  |
| WAN 2    | Spare / Future WAN  | –                   | Unused (configured for future dual-WAN)      |
| LAN 1    | Core Switch (USW-24-1)| Port 1           | Trunk: VLANs 10/20/30/40/50/60 (core uplink) |
| LAN 2    | Switch 2 (USW-24-2) | Port 1              | Trunk: VLANs 10/20/30/40/50/60 (backup link) |

---

## Port Mapping for Dell R710 Node 1 (pve-01)

- Device: **Dell R710** with:
  - 4 × onboard RJ45
  - 4 × expansion RJ45
  - 1 × iDRAC RJ45
  - 2 × SFP+ (10Gb)

| R710 Port              | Patch Panel Port | Connected Switch & Port | VLAN Assignment                                      |
|------------------------|------------------|-------------------------|-----------------------------------------------------|
| Onboard NIC 1          | 1                | USW-24-1 Port 2         | Access VLAN 10 (Mgmt – Blue)                        |
| Onboard NIC 2          | 2                | USW-24-1 Port 3         | Access VLAN 20 (Infra – Green)                      |
| Onboard NIC 3          | 3                | USW-24-1 Port 4         | Access VLAN 50 (DMZ – Red)                          |
| Onboard NIC 4          | 4                | USW-24-1 Port 5         | Access VLAN 20 (Infra – Green / spare)              |
| Expansion NIC Port 1   | 5                | USW-24-1 Port 6         | Access VLAN 20 (Infra – Green)                      |
| Expansion NIC Port 2   | 6                | USW-24-1 Port 7         | Access VLAN 50 (DMZ – Red)                          |
| Expansion NIC Port 3   | 7                | USW-24-1 Port 8         | Access VLAN 20 (Infra – Green / spare)              |
| Expansion NIC Port 4   | 8                | USW-24-1 Port 9         | Access VLAN 50 (DMZ – Red / spare)                  |
| iDRAC                  | 9                | USW-24-1 Port 10        | Access VLAN 10 (Mgmt – Blue)                        |
| 10Gb SFP+ NIC Port 1   | –                | Agg Switch Port 2       | Trunk: VLANs 20/30/40/50 (K8s, Ceph, DMZ)           |
| 10Gb SFP+ NIC Port 2   | –                | Agg Switch Port 3       | Trunk: VLANs 20/30/40/50 (Ceph-priority / LAG pair) |

Notes:

- pve-01 will typically use:
  - Mgmt via NIC1 (VLAN10).
  - Data + infra via SFP+ (primary).
  - RJ45 extra NICs reserved for future dedicated networks or migration scenarios.

---

## Port Mapping for Dell R710 Node 2 (pve-02)

- Device: **Dell R710**, no iDRAC
  - 4 × onboard RJ45
  - 2 × SFP+ 10Gb

| R710 Port            | Patch Panel Port | Connected Switch & Port | VLAN Assignment                                      |
|----------------------|------------------|-------------------------|-----------------------------------------------------|
| Onboard NIC 1        | 10               | USW-24-1 Port 11        | Access VLAN 10 (Mgmt – Blue)                        |
| Onboard NIC 2        | 11               | USW-24-1 Port 12        | Access VLAN 20 (Infra – Green)                      |
| Onboard NIC 3        | 12               | USW-24-1 Port 13        | Access VLAN 50 (DMZ – Red)                          |
| Onboard NIC 4        | 13               | USW-24-1 Port 14        | Access VLAN 20 (Infra – Green / spare)              |
| 10Gb SFP+ NIC Port 1 | –                | Agg Switch Port 4       | Trunk: VLANs 20/30/40/50 (K8s, Ceph, DMZ)           |
| 10Gb SFP+ NIC Port 2 | –                | Agg Switch Port 5       | Trunk: VLANs 20/30/40/50 (Ceph-priority / LAG pair) |

---

## Port Mapping for Tower Server (pve-03)

- Device: **Tower Server (pve-03)**
  - 4 × onboard RJ45
  - 2 × SFP+ 10Gb

| Tower Port           | Patch Panel Port | Connected Switch & Port | VLAN Assignment                                      |
|----------------------|------------------|-------------------------|-----------------------------------------------------|
| Onboard NIC 1        | 14               | USW-24-1 Port 15        | Access VLAN 10 (Mgmt – Blue)                        |
| Onboard NIC 2        | 15               | USW-24-1 Port 16        | Access VLAN 20 (Infra – Green)                      |
| Onboard NIC 3        | 16               | USW-24-1 Port 17        | Access VLAN 50 (DMZ – Red)                          |
| Onboard NIC 4        | 17               | USW-24-1 Port 18        | Access VLAN 20 (Infra – Green / spare)              |
| 10Gb SFP+ NIC Port 1 | –                | Agg Switch Port 6       | Trunk: VLANs 20/30/40/50 (K8s, Ceph, DMZ)           |
| 10Gb SFP+ NIC Port 2 | –                | Agg Switch Port 7       | Trunk: VLANs 20/30/40/50 (Ceph-priority / LAG pair) |

---

## Port Mapping for Extra PC (pc-01)

- Device: **pc-01** (can be Proxmox node or bare-metal infra host)

| PC Port      | Patch Panel Port | Connected Switch & Port | VLAN Assignment                    |
|--------------|------------------|-------------------------|-----------------------------------|
| RJ45 NIC     | 18               | USW-24-1 Port 19        | Access VLAN 20 (Infra – Green)    |

---

## Ubiquiti 24 Port Switch 1 (USW-24-1) – Core Switch

| Port           | Connected Device           | Port on Device         | VLAN Assignment                                        |
|----------------|----------------------------|------------------------|-------------------------------------------------------|
| Port 1         | USG Pro 4 (LAN 1)          | LAN 1                  | Trunk: 10/20/30/40/50/60 (core uplink)                |
| Port 2         | Patch Panel Port 1         | pve-01 Onboard NIC 1   | Access VLAN 10 (Mgmt – Blue)                          |
| Port 3         | Patch Panel Port 2         | pve-01 Onboard NIC 2   | Access VLAN 20 (Infra – Green)                        |
| Port 4         | Patch Panel Port 3         | pve-01 Onboard NIC 3   | Access VLAN 50 (DMZ – Red)                            |
| Port 5         | Patch Panel Port 4         | pve-01 Onboard NIC 4   | Access VLAN 20 (Infra – Green / spare)                |
| Port 6         | Patch Panel Port 5         | pve-01 Exp NIC 1       | Access VLAN 20 (Infra – Green)                        |
| Port 7         | Patch Panel Port 6         | pve-01 Exp NIC 2       | Access VLAN 50 (DMZ – Red)                            |
| Port 8         | Patch Panel Port 7         | pve-01 Exp NIC 3       | Access VLAN 20 (Infra – Green / spare)                |
| Port 9         | Patch Panel Port 8         | pve-01 Exp NIC 4       | Access VLAN 50 (DMZ – Red / spare)                    |
| Port 10        | Patch Panel Port 9         | pve-01 iDRAC           | Access VLAN 10 (Mgmt – Blue)                          |
| Port 11        | Patch Panel Port 10        | pve-02 Onboard NIC 1   | Access VLAN 10 (Mgmt – Blue)                          |
| Port 12        | Patch Panel Port 11        | pve-02 Onboard NIC 2   | Access VLAN 20 (Infra – Green)                        |
| Port 13        | Patch Panel Port 12        | pve-02 Onboard NIC 3   | Access VLAN 50 (DMZ – Red)                            |
| Port 14        | Patch Panel Port 13        | pve-02 Onboard NIC 4   | Access VLAN 20 (Infra – Green / spare)                |
| Port 15        | Patch Panel Port 14        | pve-03 Onboard NIC 1   | Access VLAN 10 (Mgmt – Blue)                          |
| Port 16        | Patch Panel Port 15        | pve-03 Onboard NIC 2   | Access VLAN 20 (Infra – Green)                        |
| Port 17        | Patch Panel Port 16        | pve-03 Onboard NIC 3   | Access VLAN 50 (DMZ – Red)                            |
| Port 18        | Patch Panel Port 17        | pve-03 Onboard NIC 4   | Access VLAN 20 (Infra – Green / spare)                |
| Port 19        | Patch Panel Port 18        | pc-01 RJ45             | Access VLAN 20 (Infra – Green)                        |
| Port 20        | Patch Panel Port 19        | Desk Drop 1            | Access VLAN 60 (Dev – Yellow)                         |
| Port 21        | Patch Panel Port 20        | Desk Drop 2            | Access VLAN 60 (Dev – Yellow)                         |
| Port 22        | Patch Panel Port 21        | Future AP 1            | Access VLAN 60 (Dev/Client – Yellow)                  |
| Port 23        | Patch Panel Port 22        | Future AP 2            | Access VLAN 60 (Dev/Client – Yellow)                  |
| Port 24        | Patch Panel Port 23        | Future Infra Device    | Access VLAN 20 (Infra – Green)                        |
| Port 25 (SFP+) | Aggregation Switch         | Agg Port 1             | Trunk: 20/30/40/50 (K8s, Ceph, DMZ)                   |
| Port 26 (SFP+) | Ubiquiti 24 Switch 2 SFP+  | USW-24-2 Port 25       | Trunk: 10/20/30/40/50/60 (inter-switch link)          |

---

## Ubiquiti 24 Port Switch 2 (USW-24-2)

| Port           | Connected Device         | Port on Device      | VLAN Assignment                                    |
|----------------|--------------------------|---------------------|---------------------------------------------------|
| Port 1         | USG Pro 4 (LAN 2)        | LAN 2               | Trunk: 10/20/30/40/50/60 (backup core uplink)     |
| Port 2         | Patch Panel Port 24      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 3         | Patch Panel Port 25      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 4         | Patch Panel Port 26      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 5         | Patch Panel Port 27      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 6         | Patch Panel Port 28      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 7         | Patch Panel Port 29      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 8         | Patch Panel Port 30      | Spare / Future Dev  | Access VLAN 60 (Dev – Yellow)                     |
| Port 9         | Patch Panel Port 31      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 10        | Patch Panel Port 32      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 11        | Patch Panel Port 33      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 12        | Patch Panel Port 34      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 13        | Patch Panel Port 35      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 14        | Patch Panel Port 36      | Spare / Future Infra| Access VLAN 20 (Infra – Green)                    |
| Port 15        | Patch Panel Port 37      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 16        | Patch Panel Port 38      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 17        | Patch Panel Port 39      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 18        | Patch Panel Port 40      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 19        | Patch Panel Port 41      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 20        | Patch Panel Port 42      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 21        | Patch Panel Port 43      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 22        | Patch Panel Port 44      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 23        | Patch Panel Port 45      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 24        | Patch Panel Port 46      | Spare / Future DMZ  | Access VLAN 50 (DMZ – Red)                        |
| Port 25 (SFP+) | USW-24-1 SFP+            | USW-24-1 Port 26    | Trunk: 10/20/30/40/50/60 (inter-switch link)      |
| Port 26 (SFP+) | Spare / Future           | Agg Switch Port 8?  | Reserved for future LAG or aggregation uplink     |

---

## Ubiquiti 8 Port Aggregation (USW Aggregation)

| Port   | Connected Device       | Port on Device         | VLAN Assignment                                   |
|--------|------------------------|------------------------|--------------------------------------------------|
| Port 1 | USW-24-1 SFP+          | USW-24-1 Port 25       | Trunk: 20/30/40/50 (uplink to core)              |
| Port 2 | pve-01 10Gb NIC 1      | pve-01 SFP+ 1          | Trunk: 20/30/40/50 (K8s/Infra/Ceph)              |
| Port 3 | pve-01 10Gb NIC 2      | pve-01 SFP+ 2          | Trunk: 20/30/40/50 (Ceph-priority / LAG)         |
| Port 4 | pve-02 10Gb NIC 1      | pve-02 SFP+ 1          | Trunk: 20/30/40/50 (K8s/Infra/Ceph)              |
| Port 5 | pve-02 10Gb NIC 2      | pve-02 SFP+ 2          | Trunk: 20/30/40/50 (Ceph-priority / LAG)         |
| Port 6 | pve-03 10Gb NIC 1      | pve-03 SFP+ 1          | Trunk: 20/30/40/50 (K8s/Infra/Ceph)              |
| Port 7 | pve-03 10Gb NIC 2      | pve-03 SFP+ 2          | Trunk: 20/30/40/50 (Ceph-priority / LAG)         |
| Port 8 | Spare / Future         | USW-24-2 SFP+ 26 (opt) | Reserved for second uplink / LAG to Switch 2     |
