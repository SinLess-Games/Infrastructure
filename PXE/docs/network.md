# Network requirements (multi-VLAN DHCP)

Because you selected:
- DHCP runs on the PXE server
- PXE scope is multiple VLANs

One of these must be true:

## Option A — PXE host is L3-present on each VLAN
- The switch port to the PXE host is a **VLAN trunk**
- The PXE host has subinterfaces / bridges with an IP in each VLAN
- dnsmasq can listen on those interfaces and serve each scope directly

## Option B — Gateway performs DHCP relay (recommended if host cannot trunk)
- The gateway forwards DHCP broadcast requests to the PXE server as unicast
- Many gateways call this **DHCP relay / IP helper**
- In that case dnsmasq still serves multiple scopes, but does not need a local IP in each VLAN

If neither is true, DHCP will only work on the VLAN the PXE host is directly connected to.

## Docker notes
This stack uses `network_mode: host` for dnsmasq because DHCP/TFTP need to bind low-level sockets.
