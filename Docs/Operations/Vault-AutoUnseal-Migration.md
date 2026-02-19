# Vault Auto-Unseal Migration (Transit)

This repository now includes a migration playbook:

- `Ansible/playbooks/migrate-vault-autounseal-transit.yaml`

It migrates an existing Shamir-sealed Vault cluster to Transit auto-unseal in serial order (`serial: 1`), then validates auto-unseal by restarting each node.

## Important constraint

Do not point transit auto-unseal at the same Vault cluster being migrated (for example `vault.local.sinlessgames.com` / `10.10.10.180`).  
That can deadlock startup when all nodes reboot.

Use an external transit backend endpoint and key.

## Required variables

Set in your vault-encrypted vars or as `-e` at runtime:

- `vault_transit_address`
- `vault_transit_token`
- `vault_transit_key_name` (default in repo: `autounseal`)
- Optional: `vault_transit_mount_path` (default: `transit`)
- Optional: `vault_transit_skip_verify` (default: `true`)

## Run migration

```bash
ANSIBLE_CONFIG=Ansible/ansible.cfg \
ANSIBLE_ROLES_PATH=Ansible/roles \
Ansible/.venv/bin/ansible-playbook \
  Ansible/playbooks/migrate-vault-autounseal-transit.yaml \
  -i Ansible/inventory/vault.yaml
```

## Post-migration steady state

After successful migration, set:

- `vault_seal_type: "transit"`

in `Ansible/group_vars/vault/main.yaml` (or your environment-specific vault vars), then run your normal deploy/configure playbook.
