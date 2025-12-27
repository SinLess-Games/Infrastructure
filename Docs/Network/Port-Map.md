# Rack & Network Cabling Plan (Remapped for New Nodes)

## VLANs & Colors (Reference Only)

| VLAN ID | Name            | Subnet         | Purpose                               | Color (Labels)  |
|--------|-----------------|----------------|---------------------------------------|-----------------|
| 10     | Mgmt            | 10.10.10.0/24  | Proxmox mgmt, iDRAC, switch mgmt      | Blue            |
| 20     | Infra / Services| 10.10.20.0/24  | Core services (Vault, GitLab, MinIO…) | Green           |
| 30     | Kubernetes      | 10.10.30.0/24  | K8s node-to-node, pod traffic         | Purple          |
| 40     | Storage / Ceph  | 10.10.40.0/24  | Ceph public/cluster, Rook backends    | Orange          |
| 50     | DMZ             | 10.10.50.0/24  | Edge / reverse proxies / bastion      | Red             |
| 60     | Dev / Desktop   | 10.10.60.0/24  | Workstation, APs, general clients     | Yellow          |

*(VLANs are shown for reference; physical mapping below does not enforce VLANs.)*

---

## Guide to Abbreviations

- **USG**: Ubiquiti Security Gateway (USG Pro 4).
- **AP**: Access Point.
- **iDRAC**: Integrated Dell Remote Access Controller.
- **Trunk**: Port carrying multiple VLANs (tagged).
- **Access Port**: Port assigned to a single untagged VLAN.
- **LAG**: Link Aggregation Group.

---

## Patch Panel 48 Port

> All server RJ45 ports (including iDRAC) are wired to the patch panel. Remaining ports are used for desks, APs, and future expansion.

| Port | Device / Endpoint                       | Switch & Port      |
|------|-----------------------------------------|--------------------|
| 1    | pve-01 NIC 1                            | USW-24-1 Port 2    |
| 2    | pve-01 NIC 2                            | USW-24-1 Port 3    |
| 3    | pve-02 NIC 1                            | USW-24-1 Port 4    |
| 4    | pve-03 NIC 1                            | USW-24-1 Port 5    |
| 5    | pve-03 NIC 2                            | USW-24-1 Port 6    |
| 6    | pve-04 NIC 1                            | USW-24-1 Port 7    |
| 7    | pve-04 NIC 2                            | USW-24-1 Port 8    |
| 8    | pve-04 NIC 3                            | USW-24-1 Port 9    |
| 9    | pve-04 NIC 4                            | USW-24-1 Port 10   |
| 10   | pve-04 NIC 5                            | USW-24-1 Port 11   |
| 11   | pve-04 NIC 6                            | USW-24-1 Port 12   |
| 12   | pve-04 NIC 7                            | USW-24-1 Port 13   |
| 13   | pve-04 NIC 8                            | USW-24-1 Port 14   |
| 14   | pve-04 iDRAC                            | USW-24-1 Port 15   |
| 15   | pve-05 NIC 1                            | USW-24-1 Port 16   |
| 16   | pve-05 NIC 2                            | USW-24-1 Port 17   |
| 17   | pve-05 NIC 3                            | USW-24-1 Port 18   |
| 18   | pve-05 NIC 4                            | USW-24-1 Port 19   |
| 19   | AP 1                                    | USW-24-2 Port 2    |
| 20   | Spare (Not Yet Patched)                 | USW-24-2 Port 3    |
| 21   | Spare (Not Yet Patched)                 | USW-24-2 Port 4    |
| 22   | Spare (Not Yet Patched)                 | USW-24-2 Port 5    |
| 23   | Spare (Not Yet Patched)                 | USW-24-2 Port 6    |
| 24   | Spare (Not Yet Patched)                 | USW-24-2 Port 7    |
| 25   | Spare (Not Yet Patched)                 | USW-24-2 Port 8    |
| 26   | Spare (Not Yet Patched)                 | USW-24-2 Port 9    |
| 27   | Spare (Not Yet Patched)                 | USW-24-2 Port 10   |
| 28   | Spare (Not Yet Patched)                 | USW-24-2 Port 11   |
| 29   | Spare (Not Yet Patched)                 | USW-24-2 Port 12   |
| 30   | Spare (Not Yet Patched)                 | USW-24-2 Port 13   |
| 31   | Spare (Not Yet Patched)                 | USW-24-2 Port 14   |
| 32   | Spare (Not Yet Patched)                 | USW-24-2 Port 15   |
| 33   | Spare (Not Yet Patched)                 | USW-24-2 Port 16   |
| 34   | Spare (Not Yet Patched)                 | USW-24-2 Port 17   |
| 35   | Spare (Not Yet Patched)                 | USW-24-2 Port 18   |
| 36   | Spare (Not Yet Patched)                 | USW-24-2 Port 19   |
| 37   | Spare (Not Yet Patched)                 | USW-24-2 Port 20   |
| 38   | Spare (Not Yet Patched)                 | USW-24-2 Port 21   |
| 39   | Spare (Not Yet Patched)                 | USW-24-2 Port 22   |
| 40   | Spare (Not Yet Patched)                 | USW-24-2 Port 23   |
| 41   | Spare (Not Yet Patched)                 | USW-24-2 Port 24   |
| 42   | Spare (Not Yet Patched)                 | Not connected      |
| 43   | Spare (Not Yet Patched)                 | Not connected      |
| 44   | Spare (Not Yet Patched)                 | Not connected      |
| 45   | Spare (Not Yet Patched)                 | Not connected      |
| 46   | Spare (Not Yet Patched)                 | Not connected      |
| 47   | Spare (Not Yet Patched)                 | Not connected      |
| 48   | Spare (Not Yet Patched)                 | Not connected      |

---

## Ubiquiti Security Gateway Pro 4 (USG Pro 4) Port Mapping

| USG Port | Connected Device      | Port on Device | Notes                         |
|----------|-----------------------|----------------|-------------------------------|
| WAN 1    | ISP Modem / ONT       | Modem Port     | Primary WAN                   |
| WAN 2    | Spare / Future WAN    | –              | Reserved for dual-WAN        |
| LAN 1    | Core Switch (USW-24-1)| Port 1         | Primary LAN / VLAN trunk      |
| LAN 2    | Switch 2 (USW-24-2)   | Port 1         | Secondary / backup uplink     |

---

## Port Mapping for pve-01

- Node: **pve-01**, 2 × RJ45, 2 × SFP+

| pve-01 Port | Patch Panel Port | Connected Switch & Port | Notes         |
|-------------|------------------|-------------------------|---------------|
| RJ45 NIC 1  | 1                | USW-24-1 Port 2         | Copper link   |
| RJ45 NIC 2  | 2                | USW-24-1 Port 3         | Copper link   |
| SFP+ Port 1 | –                | Aggregation Port 2      | 10Gb link     |
| SFP+ Port 2 | –                | Aggregation Port 3      | 10Gb link     |

---

## Port Mapping for pve-02

- Node: **pve-02**, desktop with 1 × RJ45

| pve-02 Port | Patch Panel Port | Connected Switch & Port | Notes       |
|-------------|------------------|-------------------------|-------------|
| RJ45 NIC 1  | 3                | USW-24-1 Port 4         | Copper link |

---

## Port Mapping for pve-03 (Dell PowerEdge T610)

- Node: **pve-03**, 2 × RJ45  

*(If this T610 has iDRAC on a separate dedicated port, you can add an extra patch panel entry later.)*

| pve-03 Port | Patch Panel Port | Connected Switch & Port | Notes       |
|-------------|------------------|-------------------------|-------------|
| RJ45 NIC 1  | 4                | USW-24-1 Port 5         | Copper link |
| RJ45 NIC 2  | 5                | USW-24-1 Port 6         | Copper link |

---

## Port Mapping for pve-04 (Dell PowerEdge R710)

- Node: **pve-04**, 8 × RJ45, 1 × iDRAC, 2 × SFP+

| pve-04 Port | Patch Panel Port | Connected Switch & Port | Notes            |
|-------------|------------------|-------------------------|------------------|
| RJ45 NIC 1  | 6                | USW-24-1 Port 7         | Copper link      |
| RJ45 NIC 2  | 7                | USW-24-1 Port 8         | Copper link      |
| RJ45 NIC 3  | 8                | USW-24-1 Port 9         | Copper link      |
| RJ45 NIC 4  | 9                | USW-24-1 Port 10        | Copper link      |
| RJ45 NIC 5  | 10               | USW-24-1 Port 11        | Copper link      |
| RJ45 NIC 6  | 11               | USW-24-1 Port 12        | Copper link      |
| RJ45 NIC 7  | 12               | USW-24-1 Port 13        | Copper link      |
| RJ45 NIC 8  | 13               | USW-24-1 Port 14        | Copper link      |
| iDRAC       | 14               | USW-24-1 Port 15        | Out-of-band mgmt |
| SFP+ Port 1 | –                | Aggregation Port 4      | 10Gb link        |
| SFP+ Port 2 | –                | Aggregation Port 5      | 10Gb link        |

---

## Port Mapping for pve-05

- Node: **pve-05**, 4 × RJ45, 2 × SFP+

| pve-05 Port | Patch Panel Port | Connected Switch & Port | Notes       |
|-------------|------------------|-------------------------|-------------|
| RJ45 NIC 1  | 15               | USW-24-1 Port 16        | Copper link |
| RJ45 NIC 2  | 16               | USW-24-1 Port 17        | Copper link |
| RJ45 NIC 3  | 17               | USW-24-1 Port 18        | Copper link |
| RJ45 NIC 4  | 18               | USW-24-1 Port 19        | Copper link |
| SFP+ Port 1 | –                | Aggregation Port 6      | 10Gb link   |
| SFP+ Port 2 | –                | Aggregation Port 7      | 10Gb link   |

---

## Ubiquiti 24 Port Switch 1 (USW-24-1) – Core Switch

| Port           | Connected Device         | Notes                          |
|----------------|--------------------------|--------------------------------|
| Port 1         | USG Pro 4 LAN 1          | Core uplink                    |
| Port 2         | Patch Panel Port 1       | pve-01 NIC 1                   |
| Port 3         | Patch Panel Port 2       | pve-01 NIC 2                   |
| Port 4         | Patch Panel Port 3       | pve-02 NIC 1                   |
| Port 5         | Patch Panel Port 4       | pve-03 NIC 1                   |
| Port 6         | Patch Panel Port 5       | pve-03 NIC 2                   |
| Port 7         | Patch Panel Port 6       | pve-04 NIC 1                   |
| Port 8         | Patch Panel Port 7       | pve-04 NIC 2                   |
| Port 9         | Patch Panel Port 8       | pve-04 NIC 3                   |
| Port 10        | Patch Panel Port 9       | pve-04 NIC 4                   |
| Port 11        | Patch Panel Port 10      | pve-04 NIC 5                   |
| Port 12        | Patch Panel Port 11      | pve-04 NIC 6                   |
| Port 13        | Patch Panel Port 12      | pve-04 NIC 7                   |
| Port 14        | Patch Panel Port 13      | pve-04 NIC 8                   |
| Port 15        | Patch Panel Port 14      | pve-04 iDRAC                   |
| Port 16        | Patch Panel Port 15      | pve-05 NIC 1                   |
| Port 17        | Patch Panel Port 16      | pve-05 NIC 2                   |
| Port 18        | Patch Panel Port 17      | pve-05 NIC 3                   |
| Port 19        | Patch Panel Port 18      | pve-05 NIC 4                   |
| Port 20        | (Free / future patch)    |                                |
| Port 21        | (Free / future patch)    |                                |
| Port 22        | (Free / future patch)    |                                |
| Port 23        | (Free / future patch)    |                                |
| Port 24        | (Free / future patch)    |                                |
| Port 25 (SFP+) | Aggregation Switch Port 1| 10Gb uplink to aggregation     |
| Port 26 (SFP+) | USW-24-2 Port 25         | 10Gb inter-switch link         |

---

## Ubiquiti 24 Port Switch 2 (USW-24-2) – Access / Edge

| Port           | Connected Device      | Notes                         |
|----------------|-----------------------|-------------------------------|
| Port 1         | USG Pro 4 LAN 2       | Secondary / backup uplink     |
| Port 2         | Patch Panel Port 19   | Desk Drop 1                   |
| Port 3         | Patch Panel Port 20   | Desk Drop 2                   |
| Port 4         | Patch Panel Port 21   | AP 1                          |
| Port 5         | Patch Panel Port 22   | AP 2                          |
| Port 6         | Patch Panel Port 23   | Future Infra Device 1         |
| Port 7         | Patch Panel Port 24   | Future Infra Device 2         |
| Port 8         | Patch Panel Port 25   | Future Dev/Desk 1             |
| Port 9         | Patch Panel Port 26   | Future Dev/Desk 2             |
| Port 10        | Patch Panel Port 27   | Future Dev/Desk 3             |
| Port 11        | Patch Panel Port 28   | Future Dev/Desk 4             |
| Port 12        | Patch Panel Port 29   | Future Dev/Desk 5             |
| Port 13        | Patch Panel Port 30   | Future Dev/Desk 6             |
| Port 14        | Patch Panel Port 31   | Future / Spare                |
| Port 15        | Patch Panel Port 32   | Future / Spare                |
| Port 16        | Patch Panel Port 33   | Future / Spare                |
| Port 17        | Patch Panel Port 34   | Future / Spare                |
| Port 18        | Patch Panel Port 35   | Future / Spare                |
| Port 19        | Patch Panel Port 36   | Future / Spare                |
| Port 20        | Patch Panel Port 37   | Future / Spare                |
| Port 21        | Patch Panel Port 38   | Future / Spare                |
| Port 22        | Patch Panel Port 39   | Future / Spare                |
| Port 23        | Patch Panel Port 40   | Future / Spare                |
| Port 24        | Patch Panel Port 41   | Future / Spare                |
| Port 25 (SFP+) | USW-24-1 Port 26      | 10Gb inter-switch link        |
| Port 26 (SFP+) | Aggregation Port 8    | Optional uplink / LAG to agg  |

---

## Ubiquiti 8 Port Aggregation (USW Aggregation)

| Port   | Connected Device       | Port on Device        | Notes                    |
|--------|------------------------|-----------------------|--------------------------|
| Port 1 | USW-24-1 SFP+          | USW-24-1 Port 25      | 10Gb uplink to core      |
| Port 2 | pve-01 SFP+ Port 1     | pve-01 SFP+ 1         | 10Gb server uplink       |
| Port 3 | pve-01 SFP+ Port 2     | pve-01 SFP+ 2         | 10Gb server uplink       |
| Port 4 | pve-04 SFP+ Port 1     | pve-04 SFP+ 1         | 10Gb server uplink       |
| Port 5 | pve-04 SFP+ Port 2     | pve-04 SFP+ 2         | 10Gb server uplink       |
| Port 6 | pve-05 SFP+ Port 1     | pve-05 SFP+ 1         | 10Gb server uplink       |
| Port 7 | pve-05 SFP+ Port 2     | pve-05 SFP+ 2         | 10Gb server uplink       |
| Port 8 | USW-24-2 SFP+          | USW-24-2 Port 26      | Optional 10Gb path / LAG |

---

This mapping:

- Uses **every RJ45 port** on all Proxmox nodes (including iDRAC).
- Connects all SFP+ ports to the **aggregation switch** with a clear, symmetric pattern.
- Keeps the **core switch (USW-24-1)** as the main server/infra fan-out.
- Uses **USW-24-2** mainly for desks, APs, and future endpoints.

You can now keep `docs/network/Port-Map.md` in sync with this layout and layer VLANs on top via Unifi port profiles later.
