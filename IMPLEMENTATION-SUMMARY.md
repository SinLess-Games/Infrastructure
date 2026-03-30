## Summary: Hardware-Based Network Interface Parsing for Proxmox

I've successfully implemented an Ansible task system that automatically parses raw hardware inventory and assigns network ports to vmbr bridges intelligently. Here's what was created:

### Core Implementation

**New Task File:** [Ansible/roles/proxmox/tasks/networking/parse-hardware.yaml](../../Ansible/roles/proxmox/tasks/networking/parse-hardware.yaml)

**Updated File:** [Ansible/roles/proxmox/tasks/networking/main.yaml](../../Ansible/roles/proxmox/tasks/networking/main.yaml)
- Added include for the new parse-hardware task

### How It Works

1. **Reads raw hardware data** from `.outputs/proxmox-hardware/{nodename}/raw/network.txt`
2. **Parses interface information** including:
   - Interface names (enp0s25, eno1, etc.)
   - Link speeds (1Gbps, 10Gbps)
   - Drivers and link status
3. **Organizes interfaces** by speed (10Gb, 1Gb, other)
4. **Assigns ports intelligently** to vmbr bridges:
   - **vmbr0 (Management)**: Always 1GB, uses configured management interface
   - **prod: true bridges**: Prefer 10GB ports, fallback to 1GB
   - **prod: false bridges**: Prefer 1GB ports, fallback to 10GB
5. **Creates parsed JSON output** files for inspection and validation

### Output Files

Three JSON files are created in `.outputs/proxmox-hardware/{nodename}/parsed/`:

- **network.json** - Complete summary with all parsed data and assignments
- **interfaces.json** - Detailed interface inventory organized by speed
- **bridge-ports.json** - Direct mapping of vmbr→port assignments

### Configuration Example

```yaml
proxmox_node_bridges:
  pve-01:
    vmbr0:
      description: "VM Bridge - Management"
      vlan_id: 1
      ports: []  # Auto-assigned to 1GB port
    
    vmbr1:
      prod: false  # Non-prod: gets 1GB port
      ports: []
      
    vmbr40:
      prod: true   # Production: gets 10GB port
      ports: []
```

### Integration

The task is automatically included in the networking phase:
```bash
# Run hardware collection first
task ansible:proxmox-hardware

# Then run networking phase with automatic parsing
task ansible:proxmox-networking
# OR
ANSIBLE_CONFIG=Ansible/ansible.cfg Ansible/.venv/bin/ansible-playbook \
  -i Ansible/inventory \
  Ansible/playbooks/configure-proxmox.yaml \
  --tags networking
```

### Tags

- `hardware-parse` - Run only the parsing task
- `networking` - Run networking phase (includes parsing)

### Facts Generated

After execution, these facts are available to subsequent tasks:

- `hardware_parsed_interfaces` - Dict of interfaces by name with metadata
- `hardware_parsed_bridge_ports` - Dict of vmbr assignments

### Example Output

```json
{
  "node": "pve-01",
  "timestamp": "2026-03-27T12:30:45+00:00",
  "interfaces": {
    "by_name": {
      "enp10s0f0": {"speed": "10000", "driver": "ixgbe", "link": "yes"},
      "enp10s0f1": {"speed": "10000", "driver": "ixgbe", "link": "yes"},
      "enp9s0": {"speed": "1000", "driver": "e1000e", "link": "yes"}
    },
    "by_speed": {
      "10Gb": ["enp10s0f0", "enp10s0f1"],
      "1Gb": ["enp9s0"]
    }
  },
  "bridge_assignments": {
    "vmbr0": {"port": "enp9s0", "prod": false, "vlan_id": 1},
    "vmbr40": {"port": "enp10s0f0", "prod": true, "vlan_id": 40}
  }
}
```

### Documentation

Comprehensive user guide with examples: [Docs/Operations/HARDWARE-NETWORK-PARSING.md](../../Docs/Operations/HARDWARE-NETWORK-PARSING.md)

Covers:
- Workflow and installation
- Port assignment logic
- Configuration examples
- Troubleshooting
- Manual override options

### Key Features

✅ Automatic port selection based on prod flag and interface speed  
✅ Management interface gets dedicated 1GB link  
✅ Production bridges prioritize 10GB when available  
✅ Non-production bridges prioritize 1GB to preserve capacity  
✅ Creates structured JSON output for validation  
✅ Generates Ansible facts for downstream tasks  
✅ Handles missing/incomplete data gracefully  
✅ Runs on every node in the cluster if needed  

### Next Steps

1. Run hardware inventory collection on your nodes
2. Review raw output in `.outputs/proxmox-hardware/*/raw/`
3. Update `Ansible/group_vars/proxmox/networking.yaml` with bridge configs
4. Run the networking phase to auto-assign ports
5. Verify assignments in `.outputs/proxmox-hardware/*/parsed/bridge-ports.json`
