# Proxmox Permissions Setup Guide

## Overview

This document describes the Proxmox permissions infrastructure for SinLess Games. The system uses Ansible to manage:

- **Custom Roles**: Predefined permission sets for specific use cases
- **Groups**: Collections of users with shared permissions  
- **Users**: Individual accounts for automation and operations
- **ACLs**: Access control lists mapping users/groups to roles at specific paths
- **API Tokens**: Secure credentials for programmatic access

## Quick Start

### 1. Initialize the Repository
```bash
cd /home/sinless777/Projects/Infrastructure
task ansible:init
```

### 2. Configure Permissions Variables

Edit the following files to define your permissions model:

- [users.yaml](../../group_vars/proxmox/users.yaml) - User definitions
- [roles.yaml](../../group_vars/proxmox/roles.yaml) - Role privileges
- [groups.yaml](../../group_vars/proxmox/groups.yaml) - Group definitions

### 3. Run Permissions Setup
```bash
# Run the full permissions setup
task ansible:setup-proxmox-permissions

# Or run with a specific tag
task ansible:setup-proxmox-permissions --tags users
```

### 4. Retrieve API Tokens
Generated API tokens are stored in `.outputs/api-tokens/`:
```bash
ls -la .outputs/api-tokens/
cat .outputs/api-tokens/terraform-prov-api-token.txt
```

## Architecture

### Custom Roles

Three primary roles are defined:

#### ReadOnly
Read-only access for monitoring and auditing.
```
Datastore.Audit, VM.Audit, Nodes.Audit, Sys.Audit
```

#### TerraformProv
Full infrastructure automation privileges via Terraform provider.
```
Datastore.AllocateSpace, Datastore.Audit, Pool.Allocate, Sys.Audit, Sys.Console,
Sys.Modify, VM.Allocate, VM.Audit, VM.Clone, VM.Config.*, VM.Migrate, VM.Monitor,
VM.PowerMgmt, SDN.Use
```

#### AnsibleProv
Node configuration and management via Ansible.
```
Datastore.Audit, Nodes.Audit, Nodes.Modify, Nodes.Power, Sys.Audit, Sys.Console,
Sys.Modify, VM.Audit, VM.Console, VM.Monitor, VM.PowerMgmt
```

### Groups

- **automation**: Terraform and Ansible service accounts
- **operators**: Human infrastructure operators
- **readonly**: Monitoring and auditing accounts

### Users

| Username | Realm | Groups | Roles | API Token |
|----------|-------|--------|-------|-----------|
| terraform-prov | pve | automation | TerraformProv | ✓ |
| ansible-prov | pve | automation | AnsibleProv | ✓ |
| monitor | pve | readonly | ReadOnly | ✗ |

### ACLs

ACLs grant roles to users/groups at specific Proxmox paths:

```
Path: /
├── User: terraform-prov@pve → Role: TerraformProv
├── User: ansible-prov@pve → Role: AnsibleProv
├── User: monitor@pve → Role: ReadOnly
├── Group: automation → Role: (inherited from members)
├── Group: operators → Role: (inherited from members)
└── Group: readonly → Role: ReadOnly
```

## Configuration Files

### users.yaml Structure

```yaml
proxmox_users:
  username:
    description: "Account purpose"
    realm: "pve"  # Authentication realm
    groups:
      - automation
    roles:
      - TerraformProv
    acl_path: "/"  # ACL assignment path
    generate_api_token: true  # Generate token for automation
    api_token_name: "token-name"
```

**Fields:**
- `description`: Human-readable account purpose
- `realm`: Proxmox authentication realm (pve, pam, ldap, etc.)
- `groups`: Groups this user belongs to
- `roles`: Roles assigned via ACL
- `acl_path`: Root path for ACL assignment (/ for system-wide)
- `generate_api_token`: Whether to generate an API token
- `api_token_name`: Name of the token (part of token ID)

### roles.yaml Structure

```yaml
proxmox_roles:
  RoleName:
    description: "Role purpose"
    privileges:
      - "Privilege.One"
      - "Privilege.Two"
```

Valid privileges: See [Proxmox Privilege List](#proxmox-privilege-list)

### groups.yaml Structure

```yaml
proxmox_groups:
  groupname:
    comment: "Group purpose"
    users: []  # Populated from users.yaml
```

## API Token Management

### Generating Tokens

Tokens are generated automatically if `generate_api_token: true` in [users.yaml](../../group_vars/proxmox/users.yaml).

Output location:
```
.outputs/api-tokens/<username>-api-token.txt
```

Each file contains:
- User and token information
- Complete API token value
- Usage examples

### Using Tokens

#### Terraform
```bash
export PROXMOX_VE_ENDPOINT="https://pve-01.sinlessgames.com:8006"
export PROXMOX_VE_API_TOKEN="terraform-prov@pve!terraform-automation=<token_id>:<secret>"
```

#### Ansible
```bash
export PROXMOX_API_URL="https://pve-01.sinlessgames.com:8006"
export PROXMOX_API_TOKEN="ansible-prov@pve!ansible-automation=<token_id>:<secret>"
```

#### Direct API Calls
```bash
curl -X GET https://pve-01.sinlessgames.com:8006/api2/json/nodes \
  -H "Authorization: PVEAPIToken=terraform-prov@pve!terraform-automation=<token_id>:<secret>"
```

## Tasks and Tags

The `proxmox-permissions` role includes several subtasks:

| Task | Tags | Purpose |
|------|------|---------|
| create-roles.yaml | proxmox, permissions, roles | Create custom roles |
| create-groups.yaml | proxmox, permissions, groups | Create groups |
| create-users.yaml | proxmox, permissions, users | Create users and API tokens |
| configure-acls.yaml | proxmox, permissions, acls | Assign roles via ACLs |
| validate.yaml | proxmox, permissions, validate | Validate setup |

### Running Specific Tasks

```bash
# Only create users
task ansible:setup-proxmox-permissions --tags users

# Only generate API tokens
task ansible:setup-proxmox-permissions --tags users

# Only validate (no changes)
task ansible:setup-proxmox-permissions --tags validate
```

## Security Best Practices

1. **Never commit secrets**: Encrypt sensitive variables with Ansible Vault
   ```bash
   ansible-vault encrypt Ansible/group_vars/proxmox/vault-users.yaml
   ```

2. **Secure token output**: 
   - `.outputs/api-tokens/` is in `.gitignore`
   - Tokens are readable only by owner (mode 0600)
   - Rotate tokens regularly

3. **Use API tokens for automation**: Never store passwords for service accounts

4. **Principle of least privilege**: Assign only necessary roles
   - Terraform: TerraformProv (infrastructure only)
   - Ansible: AnsibleProv (configuration only)
   - Monitoring: ReadOnly (audit access)

5. **Audit access**: Use monitor account for logging/monitoring
   ```bash
   pveum user token list monitor@pve
   ```

## Troubleshooting

### Check Role Creation
```bash
ssh root@pve-01
pveum role list
pveum role info TerraformProv
```

### Check User Creation
```bash
ssh root@pve-01
pveum user list
pveum user show terraform-prov@pve
```

### Check ACL Assignment
```bash
ssh root@pve-01
pveum acl list
```

### Verify API Token
```bash
ssh root@pve-01
pveum user token list terraform-prov@pve
```

### Test Token Usage
```bash
curl -X GET https://pve-01:8006/api2/json/version \
  -H "Authorization: PVEAPIToken=terraform-prov@pve!terraform-automation=<token_id>:<secret>"
```

## Manual Proxmox Commands Reference

### Create a Role
```bash
pveum role add TerraformProv \
  -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit ..."
```

### Create a User
```bash
pveum user add terraform-prov@pve -comment "Terraform provider" -password secret
```

### Create a Group
```bash
pveum group add automation -comment "Automation tools"
```

### Add User to Group
```bash
pveum group adduser automation terraform-prov@pve
```

### Assign Role via ACL
```bash
pveum acl modify / -user terraform-prov@pve -role TerraformProv
```

### Generate API Token
```bash
pveum user token add terraform-prov@pve terraform-automation --privsep=1
```

### List Entities
```bash
pveum role list
pveum group list
pveum user list
pveum user token list <user>@pve
pveum acl list
```

## Proxmox Privilege List

Common privileges by category:

### Datastore
- `Datastore.AllocateSpace` - Allocate storage space
- `Datastore.Audit` - View datastore information

### VM
- `VM.Allocate` - Create virtual machines
- `VM.Audit` - View VM information
- `VM.Clone` - Clone virtual machines
- `VM.Config.CPU` - Configure CPU settings
- `VM.Config.Memory` - Configure memory
- `VM.Config.Network` - Configure network devices
- `VM.Config.Disk` - Configure disks/drives
- `VM.Config.Options` - Configure general options
- `VM.Migrate` - Migrate virtual machines
- `VM.Monitor` - Monitor virtual machines
- `VM.PowerMgmt` - Power on/off/reset VMs

### Nodes
- `Nodes.Audit` - View node information
- `Nodes.Modify` - Modify node configuration
- `Nodes.Power` - Manage node power states

### System
- `Sys.Audit` - View system information
- `Sys.Console` - Access console
- `Sys.Modify` - Modify system configuration

### Pool
- `Pool.Allocate` - Create/manage resource pools

### SDN
- `SDN.Use` - Use SDN resources

For complete privilege reference, see [Proxmox ACL Privilege List](https://pve.proxmox.com/pve-docs/chapter-pveum.html#_pveum_privileges).

## Examples

### Adding a New Automation User

1. Edit [users.yaml](../../group_vars/proxmox/users.yaml):
```yaml
proxmox_users:
  new-automation:
    description: "New automation tool"
    realm: "pve"
    groups:
      - automation
    roles:
      - AnsibleProv  # or TerraformProv
    acl_path: "/"
    generate_api_token: true
    api_token_name: "new-automation-token"
```

2. Run permissions setup:
```bash
task ansible:setup-proxmox-permissions --tags users
```

3. Retrieve token:
```bash
cat .outputs/api-tokens/new-automation-api-token.txt
```

### Adding a New Custom Role

1. Edit [roles.yaml](../../group_vars/proxmox/roles.yaml):
```yaml
proxmox_roles:
  MyCustomRole:
    description: "Custom role for specific use case"
    privileges:
      - "VM.Audit"
      - "Datastore.Audit"
```

2. Run permissions setup:
```bash
task ansible:setup-proxmox-permissions --tags roles
```

3. Assign to user by adding role to [users.yaml](../../group_vars/proxmox/users.yaml):
```yaml
proxmox_users:
  myuser:
    roles:
      - MyCustomRole
```

4. Update ACLs:
```bash
task ansible:setup-proxmox-permissions --tags acls
```

## Integration with Playbooks

The `proxmox-permissions` role is included in [setup-proxmox-nodes.yaml](../../playbooks/setup-proxmox-nodes.yaml).

To run only permissions setup:
```bash
task ansible:setup-proxmox-permissions
```

Or include in custom playbooks:
```yaml
- hosts: proxmox
  roles:
    - proxmox-permissions
  tags:
    - permissions
```

## Related Documentation

- [Proxmox Permissions (proxmox-permissions role)](../../../Ansible/roles/proxmox-permissions/README.md)
- [Proxmox ACL Documentation](https://pve.proxmox.com/pve-docs/chapter-pveum.html)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Infrastructure Architecture](../../Architecture/ARCHITECTURE.md)
