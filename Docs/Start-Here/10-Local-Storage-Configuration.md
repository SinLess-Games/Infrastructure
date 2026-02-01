# Proxmox Storage Role - Quick Start Guide

## Overview

The `proxmox-storage` role configures local storage on Proxmox nodes that are **NOT** part of the Ceph cluster.

**Key Features:**
- 🔍 Auto-discovers free disks
- 📦 Creates LVM thin pools for VM storage
- 💾 Supports ZFS pools for high-performance storage
- 📂 Creates directory-based storage
- 🔗 Auto-registers storage with Proxmox

## Quick Start

### 1. Enable the Role

Add to your playbook (if not already included):

```yaml
- name: Configure local storage
  hosts: proxmox
  tasks:
    - name: Include proxmox-storage role
      ansible.builtin.include_role:
        name: proxmox-storage
      tags: [proxmox, storage]
```

### 2. Configure Storage Pools

Edit `Ansible/group_vars/proxmox/storage.yaml`:

```yaml
proxmox_storage_pools:
  # LVM thin pool on /dev/sdb
  - name: "local-lvm"
    type: "lvmthin"
    device: "/dev/sdb"
    content: "images,rootdir"
```

### 3. Run the Role

```bash
# Run only storage configuration
task ansible:setup-proxmox-nodes -- --tags storage

# Or run with vault password
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml \
  --tags storage --ask-vault-pass
```

### 4. Verify Storage

```bash
# SSH to a node and check
ssh root@pve-02 "pvesm list"
```

## Configuration Examples

### Example 1: Simple LVM Setup

```yaml
proxmox_storage_pools:
  - name: "vm-storage"
    type: "lvmthin"
    device: "/dev/sdb"
    content: "images,rootdir"
```

### Example 2: Mixed Storage (LVM + ZFS)

```yaml
proxmox_storage_pools:
  # Fast SSD with ZFS
  - name: "vm-fast"
    type: "zfspool"
    device: "/dev/sdb"  # NVMe or SSD
    content: "images,rootdir"
  
  # Bulk HDD with LVM
  - name: "vm-capacity"
    type: "lvmthin"
    device: "/dev/sdc"  # HDD
    content: "images,rootdir"
```

### Example 3: Node-Specific Storage

```yaml
proxmox_storage_pools:
  # These pools apply to ALL non-Ceph nodes
  - name: "local-lvm"
    type: "lvmthin"
    device: "/dev/sdb"
    content: "images,rootdir"

# Or configure specific nodes only:
proxmox_storage_nodes:
  - pve-02
  - pve-03
```

### Example 4: ISO Storage via Directory

```yaml
proxmox_storage_pools:
  - name: "iso-storage"
    type: "dir"
    path: "/mnt/iso"
    content: "iso,backup"
```

## Storage Types Explained

### LVM Thin (`lvmthin`)

**Best for:** Flexible capacity, overprovisioning, VMs

- Creates thin-provisioned logical volumes
- Flexible to expand
- Supports snapshots (via Proxmox)
- Good for mixed workloads

**Configuration:**
```yaml
- name: "vm-lvm"
  type: "lvmthin"
  device: "/dev/sdb"
  content: "images,rootdir"
```

### ZFS (`zfspool`)

**Best for:** High performance, data integrity, compression

- Built-in compression (lz4)
- Copy-on-write filesystem
- Better for SSD/NVMe
- Native snapshots

**Configuration:**
```yaml
- name: "vm-zfs"
  type: "zfspool"
  device: "/dev/sdb"
  content: "images,rootdir"
```

### Directory (`dir`)

**Best for:** ISO images, backups, shared storage

- Simple filesystem storage
- No LVM/ZFS overhead
- Good for ISO/backup content
- Can be NFS-mounted

**Configuration:**
```yaml
- name: "iso-storage"
  type: "dir"
  path: "/mnt/iso"
  content: "iso,backup"
```

## Disk Discovery

The role automatically discovers free disks on target nodes:

1. Lists all disks
2. Filters out:
   - Loop devices
   - ROM drives
   - Mounted partitions
   - LVM physical volumes
   - ZFS disks
   - System disks
3. Creates a list of available disks

**To check discovered disks manually:**
```bash
ssh root@pve-02 "lsblk -d -o NAME,SIZE,TYPE"
```

## Advanced Configuration

### Custom Disk Discovery Options

Edit `storage.yaml` to customize discovery:

```yaml
proxmox_storage_disk_discovery:
  skip_patterns:
    - "^loop"
    - "^dm-"
    - "^nvme.*n1p"
  
  min_size: 1099511627776  # 1TB minimum
```

### ZFS Compression

```yaml
proxmox_storage_zfs:
  compression: "lz4"      # lz4, zstd, gzip-9, off
  recordsize: "128k"      # 512B to 1M
```

### LVM Configuration

```yaml
proxmox_storage_lvm:
  extent_size: "4m"
  metadata_size_percent: 5
```

## Troubleshooting

### Check if Storage Already Registered

```bash
ssh root@pve-02 "pvesm list"
```

### View LVM Pools

```bash
ssh root@pve-02 "lvs"
```

### View ZFS Pools

```bash
ssh root@pve-02 "zpool list"
ssh root@pve-02 "zfs list"
```

### Check Disk Status

```bash
ssh root@pve-02 "lsblk"
ssh root@pve-02 "pvs"    # Check if disk is PV
ssh root@pve-02 "zpool list"  # Check if used by ZFS
```

### Retry Configuration

Run the role with `--check` first:

```bash
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml \
  --tags storage --check
```

Then run normally:

```bash
cd Ansible && ../.venv/bin/ansible-playbook playbooks/setup-proxmox-nodes.yaml \
  --tags storage --ask-vault-pass
```

## Important Notes

1. **Idempotent**: Safe to run multiple times
2. **Non-Destructive**: Won't modify existing pools
3. **Ceph-Aware**: Skips Ceph cluster nodes by default
4. **Root Required**: All operations need root access

## Role Structure

```
Ansible/roles/proxmox-storage/
├── README.md                    # Role documentation
├── defaults/main.yaml           # Default variables
├── handlers/main.yaml           # Event handlers
└── tasks/
    ├── main.yaml                # Task orchestration
    ├── validate.yaml            # Configuration validation
    ├── discover-disks.yaml      # Disk auto-discovery
    ├── lvm.yaml                 # LVM pool creation
    ├── zfs.yaml                 # ZFS pool creation
    ├── register.yaml            # Proxmox registration
    └── summary.yaml             # Status summary
```

## Tags

Use these tags to run specific parts:

```bash
# Run only disk discovery
--tags storage:discover

# Run only LVM configuration
--tags storage:lvm

# Run only ZFS configuration
--tags storage:zfs

# Run only registration
--tags storage:register

# Full storage configuration
--tags storage
```

## Related Documentation

- [Proxmox Storage Documentation](https://pve.proxmox.com/wiki/Storage)
- [LVM Thin Provisioning](https://pve.proxmox.com/wiki/Storage#LVM_Thin_Pools)
- [ZFS on Proxmox](https://pve.proxmox.com/wiki/Storage#ZFS_pools)
