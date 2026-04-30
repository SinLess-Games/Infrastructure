# Network

This section documents the physical and logical network design for the SinLess Games infrastructure environment.

The network documentation covers rack layout, cabling, switching, VLAN design, Layer 2 and Layer 3 topology, port mapping, rack planning, and hardware purchasing references.

---

## Network Documents

| Document | Purpose |
|---|---|
| [Layer 2 / Layer 3 Network Design](./Layer_2-3_diagram.md) | Logical network design, VLANs, subnets, routing, DHCP, DNS, Proxmox bridge integration, and Mermaid network diagrams. |
| [Port Map](./Port-Map.md) | Physical patch panel, switch port, server NIC, SFP+, and UniFi port mapping. |
| [Rack Diagram](./Rack-Diagram.md) | Current rack unit layout and front-facing rack documentation. |
| [Rack Diagram SVG](./Rack-Diagram.svg) | SVG diagram for the current rack layout. |
| [Rack Plan](./Rack-Plan.md) | Detailed professional rack plan, upgrade path, server hardware plan, power plan, and shopping list. |
| [Rack Plan Diagram](./Rack-Plan-Diagram.svg) | SVG diagram for the planned front and rear rack layout. |
| [Items and Prices](./Items-prices.md) | Budget-focused purchasing plan, item quantities, pricing, links, and estimated totals. |

---

## Active VLAN Model

VLAN 60 has been removed from the active network design.

| VLAN ID | Name | Subnet | Gateway | Purpose |
|---:|---|---|---|---|
| 1 | Infrastructure | `10.10.10.0/24` | `10.10.10.1` | Proxmox management, iDRAC, switches, gateway, core infrastructure |
| 20 | Development | `10.10.20.0/24` | `10.10.20.1` | Development workloads and dev VMs |
| 30 | Testing | `10.10.30.0/24` | `10.10.30.1` | Testing, QA, staging, and validation workloads |
| 40 | Production | `10.10.40.0/24` | `10.10.40.1` | Production workloads and production VMs |
| 50 | DMZ | `10.10.50.0/24` | `10.10.50.1` | Edge systems, reverse proxies, tunnels, bastions |

---

## Network Design Summary

The network uses a classic **router-on-a-stick** design.

The gateway handles Layer 3 routing between VLANs. UniFi switches handle Layer 2 switching, VLAN trunks, access ports, and uplinks. Proxmox nodes use VLAN-aware bridges so virtual machines and Kubernetes nodes can attach to the correct VLAN.

```mermaid
flowchart TD
    WAN["ISP / WAN"]
    GW["Gateway<br/>USG Pro 4 / Future UniFi Gateway"]
    ACCESS["Access Switching<br/>UniFi 24/48-Port Switches"]
    AGG["10Gb SFP+ Aggregation<br/>UniFi Aggregation Switch"]
    PATCH["48-Port Patch Panel"]

    PVE["Proxmox Nodes"]
    PI["Raspberry Pi Shelf"]
    AP["Access Points / Desk Drops"]
    DMZ["DMZ / Edge Systems"]

    WAN --> GW
    GW --> ACCESS
    GW --> AGG

    ACCESS --> PATCH
    PATCH --> AP
    ACCESS --> PI
    ACCESS --> DMZ

    AGG --> PVE
````

---

## Rack Network Direction

The planned rack design uses a rear-facing **10Gb SFP+ backbone**.

Every server that can connect to 10Gb should connect directly to the aggregation layer.

Target server networking:

| Server   | Primary Network         | Management Network |
| -------- | ----------------------- | ------------------ |
| `pve-01` | Dual-port 10Gb SFP+ NIC | iDRAC on VLAN 1    |
| `pve-02` | Dual-port 10Gb SFP+ NIC | iDRAC on VLAN 1    |
| `pve-03` | Dual-port 10Gb SFP+ NIC | iDRAC on VLAN 1    |
| `pve-04` | Dual-port 10Gb SFP+ NIC | iDRAC on VLAN 1    |
| `pve-05` | Dual-port 10Gb SFP+ NIC | iDRAC on VLAN 1    |

---

## Physical Network Components

| Component                     | Role                                                            |
| ----------------------------- | --------------------------------------------------------------- |
| Gateway                       | WAN edge, firewall, inter-VLAN routing                          |
| UniFi access switch           | RJ45 access switching, PoE, APs, desk drops, management devices |
| UniFi SFP+ aggregation switch | 10Gb server backbone                                            |
| 48-port patch panel           | Structured copper cabling                                       |
| Proxmox servers               | Compute, Kubernetes, VMs, storage services                      |
| Disk shelf / HBA host         | Direct-attached storage expansion                               |
| UPS                           | Battery backup and graceful shutdown support                    |
| Rear PDUs                     | A/B rack power distribution                                     |
| Raspberry Pi shelf            | Lightweight infrastructure, lab, automation, or utility nodes   |

---

## Recommended Reading Order

Read the network documentation in this order:

1. [Layer 2 / Layer 3 Network Design](./Layer_2-3_diagram.md)
2. [Port Map](./Port-Map.md)
3. [Rack Diagram](./Rack-Diagram.md)
4. [Rack Plan](./Rack-Plan.md)
5. [Items and Prices](./Items-prices.md)

---

## Operational Standards

Network documentation should remain accurate enough to support:

* Rebuilding the rack
* Tracing cables
* Replacing switches
* Reconfiguring UniFi port profiles
* Validating VLAN trunks
* Troubleshooting Proxmox networking
* Planning power and UPS load
* Buying compatible replacement hardware
* Expanding the rack without guessing

---

## Port Profile Standards

### Infrastructure Access

| Setting | Value                                                     |
| ------- | --------------------------------------------------------- |
| VLAN    | `1`                                                       |
| Purpose | Proxmox management, iDRAC, switches, gateway, controllers |

### Development Access

| Setting | Value                               |
| ------- | ----------------------------------- |
| VLAN    | `20`                                |
| Purpose | Development endpoints and workloads |

### Testing Access

| Setting | Value                                          |
| ------- | ---------------------------------------------- |
| VLAN    | `30`                                           |
| Purpose | Testing, QA, staging, and validation workloads |

### Production Access

| Setting | Value                |
| ------- | -------------------- |
| VLAN    | `40`                 |
| Purpose | Production workloads |

### DMZ Access

| Setting | Value                                                |
| ------- | ---------------------------------------------------- |
| VLAN    | `50`                                                 |
| Purpose | Bastions, reverse proxies, tunnels, and edge systems |

### Proxmox Trunk

| Setting      | Value                                     |
| ------------ | ----------------------------------------- |
| Native VLAN  | `1`                                       |
| Tagged VLANs | `20,30,40,50`                             |
| Purpose      | Proxmox VM and Kubernetes node networking |

---

## Validation Checklist

### Layer 1 / Physical

* [ ] Rack diagram matches the installed equipment.
* [ ] Patch panel labels match the port map.
* [ ] Switch ports match the documented port map.
* [ ] SFP+ DACs or fiber links are labeled.
* [ ] Power cables are labeled on both ends.
* [ ] A-side and B-side power are clearly separated.
* [ ] Server rails and cable-management arms do not pinch cables.

### Layer 2 / VLAN

* [ ] VLAN 60 is not configured in the active rack design.
* [ ] Active VLANs are `1,20,30,40,50`.
* [ ] Proxmox trunks carry the correct VLANs.
* [ ] Access ports use the correct untagged VLAN.
* [ ] AP and desk ports are documented.
* [ ] iDRAC ports are on VLAN 1.

### Layer 3 / Routing

* [ ] Each VLAN gateway responds from allowed networks.
* [ ] Inter-VLAN routing is controlled by firewall policy.
* [ ] DMZ traffic is restricted.
* [ ] Development and testing do not have unrestricted production access.
* [ ] Infrastructure access is limited to trusted administrative systems.

### Proxmox

* [ ] Proxmox management IPs are reachable.
* [ ] `vmbr0` is VLAN-aware where needed.
* [ ] 10Gb SFP+ links are detected.
* [ ] Bonding mode is documented.
* [ ] VM VLAN tags use only active VLANs.
* [ ] iDRAC access works for every server that has iDRAC installed.

### Power

* [ ] UPS load is within safe operating limits.
* [ ] PDUs are not overloaded.
* [ ] Redundant server PSUs are split between power feeds where possible.
* [ ] Network equipment is on UPS-backed power.
* [ ] Graceful shutdown path is documented.

---

## Maintenance Requirements

Update this section whenever any of the following change:

* VLAN IDs
* Subnet assignments
* Gateway addresses
* DHCP ranges
* UniFi port profiles
* Patch panel assignments
* Switch port assignments
* SFP+ backbone layout
* Rack unit placement
* Disk shelf or HBA layout
* UPS or PDU model
* Server count
* NIC count
* iDRAC count
* Cable lengths
* Shopping list prices
* Network hardware upgrade plan

---

## Related Architecture Documents

* [`Docs/Architecture/index.md`](../Architecture/index.md)
* [`Docs/Architecture/ACME-Architecture.md`](../Architecture/ACME-Architecture.md)
* [`Docs/Architecture/DECISIONS.md`](../Architecture/DECISIONS.md)
* [`Docs/Architecture/ADRs/`](../Architecture/ADRs/)

---

**Last Updated**: April 25, 2026
**Maintained By**: Infrastructure repository documentation and network automation
