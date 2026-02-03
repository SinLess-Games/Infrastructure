# Proxmox Permissions Management Role

This role manages Proxmox permissions including:
- **Custom Roles**: TerraformProv, AnsibleProv, ReadOnly
- **Groups**: automation, operators, readonly
- **Users**: terraform-prov, ansible-prov, monitor
- **ACLs**: Access control lists mapping users/groups to roles
- **API Tokens**: Optional token generation for automation

## Features

- Idempotent user, group, and role creation
- Flexible role privilege assignment
- Group-based permission management
- Optional API token generation with secure output
- Comprehensive validation and reporting

## Configuration

### Variables

See `defaults/main.yaml` for default values. Override in:
- `Ansible/group_vars/proxmox/roles.yaml` - Custom roles
- `Ansible/group_vars/proxmox/groups.yaml` - Groups
- `Ansible/group_vars/proxmox/users.yaml` - Users and API token settings

### Role Definition (roles.yaml)

```yaml
proxmox_roles:
  RoleName:
    description: "Role description"
    privileges:
      - "Privilege1"
      - "Privilege2"
```

### Groups Definition (groups.yaml)

```yaml
proxmox_groups:
  groupname:
    comment: "Group description"
    users: []  # Populated from users config
```

### Users Definition (users.yaml)

```yaml
proxmox_users:
  username:
    description: "User description"
    realm: "pve"  # Authentication realm
    groups:
      - automation
    roles:
      - TerraformProv
    acl_path: "/"
    generate_api_token: true
    api_token_name: "token-name"
```

## API Token Output

Generated API tokens are saved to:
```
.outputs/api-tokens/<username>-api-token.txt
```

Each file contains:
- User and token information
- Full API token value
- Usage instructions for Terraform and other tools

## Tasks

This role includes the following tasks:

- `create-roles.yaml` - Create custom Proxmox roles
- `create-groups.yaml` - Create groups
- `create-users.yaml` - Create users and generate API tokens
- `configure-acls.yaml` - Assign roles to users/groups
- `validate.yaml` - Verify permissions configuration

## Usage

Add to a playbook:

```yaml
- hosts: proxmox
  roles:
    - proxmox-permissions
```

Or run with tags:

```bash
# Only create users
ansible-playbook playbooks/setup-proxmox-nodes.yaml --tags permissions,users

# Only generate API tokens
ansible-playbook playbooks/setup-proxmox-nodes.yaml --tags permissions,users --ask-vault-pass
```

## Requirements

- Ansible 2.9+
- SSH access to Proxmox node with root privileges
- `pveum` command available on Proxmox nodes
- `community.general.random_string` lookup plugin

## Tags

- `proxmox` - All Proxmox-related tasks
- `permissions` - All permission tasks
- `roles` - Role creation only
- `groups` - Group creation only
- `users` - User and API token creation
- `acls` - ACL configuration only
- `validate` - Validation tasks only
