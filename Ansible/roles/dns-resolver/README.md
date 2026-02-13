# DNS Resolver Role

## Overview

This role checks DNS resolution on VMs and automatically fixes configuration issues. It intelligently detects which DNS resolver system is in use (systemd-resolved, NetworkManager, or static /etc/resolv.conf) and applies the appropriate fix.

## Features

- ✅ **Automatic Detection**: Identifies systemd-resolved, NetworkManager, or static configurations
- ✅ **Smart Testing**: Tests multiple domains to verify DNS is working
- ✅ **Safe Fixes**: Backs up existing configuration before making changes
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Verification**: Confirms DNS works after applying fixes
- ✅ **Multi-resolver Support**: Handles different Linux DNS configurations

## Requirements

- Ansible 2.9+
- Linux target systems (tested on Debian/Ubuntu, should work on RHEL/CentOS)
- Root or sudo access on target systems

## Role Variables

### DNS Configuration

```yaml
# DNS servers to use (in order of preference)
dns_servers:
  - 10.10.10.12  # dns-pi
  - 10.10.10.13  # dns-01
  - 10.10.10.9   # dns-02
  - 10.10.10.20  # dns-03
  - 1.1.1.1      # Cloudflare (fallback)

# Search domains
dns_search_domains:
  - sinlessgames.com
  - local

# DNS test targets
dns_test_domains:
  - google.com
  - cloudflare.com
  - sinlessgames.com
```

### Behavior Control

```yaml
# Force reconfiguration even if DNS appears working
dns_force_reconfigure: false

# Backup existing configuration before changes
dns_backup_config: true

# Restart network services after fixing DNS
dns_restart_services: true

# Configure systemd-resolved (if detected)
dns_configure_systemd_resolved: true
```

### Testing Parameters

```yaml
# Number of retries for DNS tests
dns_test_retries: 3

# Timeout for DNS resolution tests (seconds)
dns_test_timeout: 5
```

## Usage

### Basic Usage

Include in a playbook:

```yaml
---
- name: Check and fix DNS on all VMs
  hosts: all
  become: true
  roles:
    - dns-resolver
```

### With Custom DNS Servers

```yaml
---
- name: Fix DNS with custom servers
  hosts: all
  become: true
  roles:
    - role: dns-resolver
      vars:
        dns_servers:
          - 192.168.1.1
          - 8.8.8.8
        dns_search_domains:
          - example.com
```

### Force Reconfiguration

```yaml
---
- name: Force DNS reconfiguration
  hosts: broken_vms
  become: true
  roles:
    - role: dns-resolver
      vars:
        dns_force_reconfigure: true
```

### Check Only (No Fixes)

```yaml
---
- name: Check DNS without fixing
  hosts: all
  become: true
  roles:
    - dns-resolver
  tags:
    - dns-check
```

## Tags

- `dns`: All DNS tasks
- `dns-check`: DNS testing and detection only
- `dns-fix`: DNS fixing tasks
- `dns-verify`: Verification tasks

## Examples

### Check DNS on specific hosts

```bash
ansible-playbook playbooks/check-dns.yaml -l web-servers --tags dns-check
```

### Fix DNS on all VMs

```bash
ansible-playbook playbooks/fix-dns.yaml --ask-become-pass
```

### Fix with specific DNS servers

```bash
ansible-playbook playbooks/fix-dns.yaml -e "dns_servers=['10.0.0.1','10.0.0.2']"
```

## How It Works

1. **Validation**: Checks that required variables are set
2. **Testing**: Tests DNS resolution against multiple domains
3. **Detection**: Identifies which DNS resolver system is in use:
   - systemd-resolved
   - NetworkManager
   - Static /etc/resolv.conf
4. **Backup**: Creates timestamped backups of existing configuration
5. **Fix**: Applies appropriate fix based on detected resolver:
   - **systemd-resolved**: Updates `/etc/systemd/resolved.conf` and ensures proper symlinks
   - **NetworkManager**: Configures DNS via `nmcli` for all active connections
   - **Static**: Creates protected `/etc/resolv.conf`
6. **Verification**: Re-tests DNS and confirms it's working

## Supported Systems

### Tested On
- ✅ Debian 11/12
- ✅ Ubuntu 20.04/22.04/24.04
- ✅ Proxmox VE 8.x

### Should Work On
- RHEL/CentOS 7/8/9
- Rocky Linux 8/9
- AlmaLinux 8/9

## Troubleshooting

### DNS still broken after running role

Check the verification output:
```bash
ansible-playbook playbooks/fix-dns.yaml -l problematic-host -vv
```

Manually verify:
```bash
ssh user@host "getent hosts google.com"
ssh user@host "cat /etc/resolv.conf"
```

### Role fails with "not dns__verification_passed"

The role detected and attempted to fix DNS, but verification still failed. Check:
1. Firewall rules blocking DNS (port 53 UDP/TCP)
2. Network connectivity to DNS servers
3. DNS servers actually running and responsive

### Backups location

All backups are stored in `/root/dns-backups/` with ISO 8601 timestamps:
```
/root/dns-backups/
├── resolv.conf.20260212T153045
├── resolved.conf.20260212T153045
└── NetworkManager.conf.20260212T153045
```

## Dependencies

None

## License

Proprietary - SinLess Games LLC

## Author

Created for SinLess Games Infrastructure
