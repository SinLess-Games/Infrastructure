# PXE

PXE + iPXE + HTTP provisioning stack designed for **Debian 12 (bookworm)** installs that then bootstrap **Proxmox VE packages**.

This scaffold supports:
- Mixed **BIOS + UEFI** nodes
- DHCP served by this PXE host (docker, host networking)
- **iPXE via HTTP** (recommended) *and* a basic **TFTP-only fallback skeleton**
- Per-node **profiles** (LVM-thin / ZFS-data / etc.)
- “Cloud-init style” first-boot configuration via **NoCloud** seed served over HTTP

## What you need to fill in first (required)
1. `inventory/vlans.yaml` — the VLAN IDs, subnets, ranges, and gateways you want DHCP on.
2. `inventory/nodes.yaml` — node MAC → hostname mappings and which profile each node uses.
3. Generate a provisioning SSH keypair (shared, per your choice):
   - `task pxe:keygen` (or run `scripts/gen-shared-key.sh`)

## Quickstart
From the repo root (or inside `PXE/`):
1. Copy env file:
   - `cp .env.example .env`
2. Edit `.env` and set:
   - `PXE_HTTP_HOST` (DNS name or IP clients can reach)
   - `PXE_TFTP_HOST` (usually same as above)
3. Fill in `inventory/vlans.yaml` and `inventory/nodes.yaml`
4. Fetch bootloaders + Debian netboot:
   - `task pxe:fetch`
5. Render per-node artifacts:
   - `task pxe:render`
6. Start the PXE stack:
   - `task pxe:up`

## How boot works
- DHCP hands out:
  - BIOS: `undionly.kpxe`
  - UEFI: `ipxe.efi` (or `snponly.efi`)
- Once iPXE is running, DHCP detects `user-class = iPXE` and chains to:
  - `http://$PXE_HTTP_HOST/ipxe/bootstrap.ipxe`
- That menu lets you pick a node (or auto-select by MAC if you enable it) and boots Debian installer kernel/initrd with:
  - a per-node preseed URL
  - a per-node NoCloud seed URL (cloud-init is installed + seeded during `late_command`)

## Notes / gotchas
- Running DHCP across multiple VLANs generally requires either:
  - the PXE host has L3 presence in each VLAN (subinterfaces / bridges), **or**
  - the gateway does **DHCP relay** to the PXE host.
See `docs/network.md`.

- This repo disables dnsmasq DNS by default (`port=0`) to avoid conflicts with systemd-resolved.

