# proxmox-ha

Configures Proxmox HA (High Availability) for virtual machines across the cluster.

## Overview

This role sets up and manages Proxmox High Availability features including:

- **Watchdog configuration** - Hardware watchdog device setup for automatic failure detection
- **Fencing** - Automatic node fencing on failure
- **HA Resource Groups** - Logical grouping of nodes for resource placement
- **HA Resources** - VMs managed by the HA cluster
- **Recovery policies** - Automatic restart and relocation of failed VMs
- **Cluster-wide HA settings** - Shutdown policies and migration behavior

## Requirements

- Proxmox VE 6.0+
- Cluster must be initialized (`proxmox-cluster` role)
- All nodes must be cluster members
- Root SSH access to cluster nodes

## Role Variables

### Watchdog Configuration

```yaml
proxmox_ha_watchdog_enabled: true              # Enable watchdog
proxmox_ha_watchdog_type: "wdt_i6300esb"      # Watchdog module (intel 6300esb)
proxmox_ha_watchdog_action: "reset"            # Action on timeout: reset, shutdown, poweroff, pause
```

### HA Manager Settings

```yaml
proxmox_ha_migrate_on_error: true              # Migrate VMs on node error
proxmox_ha_shutdown_policy: "conditional"      # Policy: conditional, always, never
proxmox_ha_max_relocate: 3                     # Max relocate attempts
proxmox_ha_max_restart: 1                      # Max restarts per 24h period
proxmox_ha_restart_delay: 300                  # Delay between restarts (seconds)
```

### Fencing Configuration

```yaml
proxmox_ha_fence_enabled: true                 # Enable fencing
proxmox_ha_fence_mode: "watchdog"              # Fence mode: watchdog, hardware
```

### VM HA Defaults

```yaml
proxmox_ha_vm_enabled: true                    # Enable HA for new VMs
proxmox_ha_vm_group: "default"                 # Default HA resource group
proxmox_ha_vm_state: "started"                 # Default state: started, stopped, disabled
```

### HA Resource Groups

Define logical groups of nodes for resource placement:

```yaml
proxmox_ha_resource_groups:
  - name: "webservers"
    comment: "Web application servers"
    nodes: "pve-01,pve-02,pve-03"
    priority: 100
  - name: "databases"
    comment: "Database servers"
    nodes: "pve-02,pve-03,pve-04"
    priority: 50
```

**Options:**
- `name` - Group identifier (required)
- `comment` - Description (optional)
- `nodes` - Comma-separated list of nodes (required)
- `priority` - Priority value (optional, default: 50)

### HA Resources (VMs)

Specify which VMs are managed by HA:

```yaml
proxmox_ha_resources:
  - sid: "vm:100"                  # VM ID or container ID
    group: "webservers"            # Resource group name
    state: "started"               # started, stopped, disabled
    max_restart: 4                 # Max restarts per 24h
    max_relocate: 4                # Max relocate attempts
  - sid: "vm:101"
    group: "webservers"
    state: "started"
```

**Options:**
- `sid` - Service ID: `vm:<id>` or `ct:<id>` (required)
- `group` - HA resource group (required)
- `state` - Resource state (required)
- `max_restart` - Max restarts (optional)
- `max_relocate` - Max relocates (optional)
- `comment` - Description (optional)

### Cluster-wide HA Settings

```yaml
proxmox_ha_cluster_settings:
  max_worker: 4                    # Parallel worker processes
  shutdown_policy: "conditional"   # Shutdown behavior
  migration_delay: 5               # Graceful migration timeout (seconds)
  recovery_delay: 60               # Delay after failure (seconds)
```

### HA Affinity Rules

Affinity rules control VM placement relationships:

```yaml
proxmox_ha_affinity_rules: []
```

**Rule Types:**

- `group` - Keep VMs together on same node for performance/data locality
- `anti` - Keep VMs on different nodes for fault tolerance/distribution

**Example Rules:**

```yaml
proxmox_ha_affinity_rules:
  - id: "webservers-together"
    type: "group"                    # Keep webservers together
    vmgroup: "webservers"            # Apply to webservers group
    nodes: "pve-01,pve-02,pve-03"   # Preferred nodes
    enabled: true

  - id: "database-isolation"
    type: "anti"                     # Spread databases across nodes
    vmgroup: "databases"
    enabled: true

  - id: "cache-affinity"
    type: "group"                    # Redis with web tier
    vmgroup: "cache"
    nodes: "pve-01,pve-02"
    enabled: true
```

## Dependencies

- `proxmox-cluster` - Must be applied first to initialize cluster
- `proxmox-node` - Base node configuration

## Tags

- `proxmox` - All Proxmox configuration
- `ha` - All HA configuration
- `watchdog` - Watchdog setup only
- `fencing` - Fencing setup only
- `resources` - Resource and resource group configuration
- `affinity` - Affinity rules configuration only
- `cluster` - Cluster-wide settings
- `verify` - Verification and status checks

## Example Playbook

```yaml
---
- name: Configure Proxmox HA for VMs
  hosts: proxmox
  vars:
    proxmox_ha_resource_groups:
      - name: "web"
        comment: "Web tier servers"
        nodes: "pve-01,pve-02,pve-03"
        priority: 100
      - name: "db"
        comment: "Database tier servers"
        nodes: "pve-03,pve-04,pve-05"
        priority: 50

    proxmox_ha_resources:
      - sid: "vm:100"
        group: "web"
        state: "started"
        max_restart: 4
        max_relocate: 4
      - sid: "vm:101"
        group: "web"
        state: "started"
        max_restart: 4
        max_relocate: 4
      - sid: "vm:200"
        group: "db"
        state: "started"
        max_restart: 2
        max_relocate: 3

    proxmox_ha_affinity_rules:
      - id: "webservers-together"
        type: "group"
        vmgroup: "web"
        nodes: "pve-01,pve-02,pve-03"
        enabled: true
      - id: "db-isolation"
        type: "anti"
        vmgroup: "db"
        enabled: true

  roles:
    - proxmox-ha
```

## Task Flow

1. **Pre-flight checks**
   - Verify cluster is initialized
   - Check cluster.conf exists

2. **Watchdog setup**
   - Load watchdog kernel module
   - Enable systemd-watchdog service
   - Verify /dev/watchdog device

3. **Fencing configuration**
   - Configure fence devices
   - Set fencing mode

4. **Resource groups**
   - Create HA resource groups
   - Configure node priorities

5. **Resources**
   - Define VMs/containers for HA management
   - Set restart/relocation policies

6. **Affinity Rules**
   - Create VM placement relationships
   - Configure group (co-location) rules
   - Configure anti (isolation) rules
   - Set preferred node locations

7. **Cluster Settings**
   - Apply cluster-wide HA settings
   - Configure shutdown behavior
   - Set migration/recovery delays

8. **Verification**
   - Check HA service status
   - Verify watchdog device
   - Display current HA configuration
   - List all managed resources

5. **Resources**
   - Add/update HA resources (VMs)
   - Configure restart/relocate policies

6. **Cluster settings**
   - Apply shutdown policies
   - Set migration delays

7. **Verification**
   - Check HA services status
   - Display HA cluster configuration
   - Validate resource setup

## Troubleshooting

### Check HA status
```bash
pvesh get /cluster/ha/status
```

### List resource groups
```bash
pvesh get /cluster/ha/groups
```

### List HA resources
```bash
pvesh get /cluster/ha/resources
```

### Check HA services
```bash
systemctl status pve-ha-manager
systemctl status pve-ha-lrm
```

### View watchdog status
```bash
ls -la /dev/watchdog
cat /proc/modules | grep watchdog
```

### Check cluster status
```bash
pvecm status
```

## Notes

- HA configuration requires a functioning Proxmox cluster
- Watchdog is essential for automatic failure detection
- Resource restart/relocate limits prevent infinite restart loops
- Node priority in resource groups determines placement preference
- Changes to HA settings typically don't require node restart

## Author

SinLess Games Infrastructure Team
