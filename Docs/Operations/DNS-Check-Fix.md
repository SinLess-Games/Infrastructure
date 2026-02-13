# DNS Resolution Check and Fix

## Overview

The `dns-resolver` role automatically checks DNS resolution on VMs and fixes configuration issues. It intelligently detects the DNS resolver system in use and applies appropriate fixes.

## Quick Start

### Check DNS on all VMs
```bash
task ansible:check-fix-dns
```

### Check specific hosts
```bash
task ansible:check-fix-dns -- -l web-servers
```

### Force reconfiguration (even if DNS appears working)
```bash
task ansible:check-fix-dns -- -e dns_force_reconfigure=true
```

### Check only (no fixes)
```bash
task ansible:check-fix-dns -- --tags dns-check
```

## Features

- ✅ Automatic detection of DNS resolver type (systemd-resolved, NetworkManager, static)
- ✅ Tests DNS against multiple domains
- ✅ Backs up existing configuration before changes
- ✅ Applies appropriate fix based on detected system
- ✅ Verifies DNS works after fixing
- ✅ Idempotent - safe to run multiple times

## How It Works

1. **Test DNS**: Attempts to resolve configured test domains
2. **Detect System**: Identifies which DNS resolver is active
3. **Backup**: Creates timestamped backup of current configuration
4. **Fix**: Applies appropriate fix:
   - **systemd-resolved**: Updates `/etc/systemd/resolved.conf`
   - **NetworkManager**: Configures DNS via `nmcli`
   - **Static**: Creates protected `/etc/resolv.conf`
5. **Verify**: Re-tests DNS and confirms it's working

## DNS Servers

By default, the role uses your infrastructure DNS servers:

1. `10.10.10.12` (dns-pi)
2. `10.10.10.13` (dns-01)
3. `10.10.10.9` (dns-02)
4. `10.10.10.20` (dns-03)
5. `1.1.1.1` (Cloudflare fallback)
6. `1.0.0.1` (Cloudflare fallback)

## Configuration

### Custom DNS Servers

Create a group_vars file or pass as extra vars:

```yaml
dns_servers:
  - 192.168.1.1
  - 8.8.8.8
```

### Custom Test Domains

```yaml
dns_test_domains:
  - example.com
  - internal.local
  - google.com
```

### Search Domains

```yaml
dns_search_domains:
  - sinlessgames.com
  - internal.local
```

## Advanced Usage

### In Your Playbooks

```yaml
---
- name: Setup new VMs
  hosts: new_vms
  become: true
  roles:
    - common
    - dns-resolver  # Check and fix DNS
    - docker
```

### With Other Roles

```yaml
---
- name: Full VM configuration
  hosts: all
  become: true
  pre_tasks:
    - name: Ensure DNS is working before proceeding
      ansible.builtin.include_role:
        name: dns-resolver
      tags: always

  roles:
    - security
    - monitoring
    - application
```

### Tags

Use tags for fine-grained control:

```bash
# Check only
task ansible:check-fix-dns -- --tags dns-check

# Fix only (skip checks)
task ansible:check-fix-dns -- --tags dns-fix

# Verify only
task ansible:check-fix-dns -- --tags dns-verify
```

## Troubleshooting

### Check Backups

All configuration backups are stored in `/root/dns-backups/`:

```bash
ssh user@host "ls -la /root/dns-backups/"
```

### Manual DNS Test

```bash
# Test DNS resolution
ssh user@host "getent hosts google.com"

# Check current configuration
ssh user@host "cat /etc/resolv.conf"

# Check systemd-resolved status
ssh user@host "systemctl status systemd-resolved"
```

### Force Re-run

If DNS is still broken after the role runs:

```bash
# Re-run with more verbosity
task ansible:check-fix-dns -- -l problematic-host -vv

# Force reconfiguration
task ansible:check-fix-dns -- -l problematic-host -e dns_force_reconfigure=true
```

### Common Issues

**"DNS still broken after fix"**
- Check firewall rules (port 53 UDP/TCP)
- Verify DNS servers are reachable
- Check network connectivity

**"Role fails with verification error"**
- Manual firewall blocking DNS
- DNS servers down or unreachable
- Network routing issues

## Files

- **Role**: `Ansible/roles/dns-resolver/`
- **Playbook**: `Ansible/playbooks/check-fix-dns.yaml`
- **Task**: `task ansible:check-fix-dns`
- **Documentation**: `Ansible/roles/dns-resolver/README.md`

## Related Documentation

- [Technitium DNS Setup](../Start-Here/README-ACME-Setup.md)
- [Network Architecture](../Network/Layer_2-3_diagram.md)
- [DNS Inventory](../../Ansible/inventory/dns.yaml)
