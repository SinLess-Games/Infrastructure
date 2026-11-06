# Credential rotation

These values were committed to git and then removed from the tree. Removing them from the current files does not remove them from history. This repository does not rewrite history.

Rotate every credential below before trusting the new references. Treat the old values as exposed.

## Cloud-init VM password

The Vault and Wazuh cloud-init password was a literal in:

- `Ansible/group_vars/vault/vault-vms.yaml`
- `Ansible/group_vars/wazuh/main.yaml`

Those VMs still have that password if they were built or updated from the old vars. Rotate it on the guests and in Proxmox cloud-init.

The playbooks now read:

- `VAULT_VM_CIPASSWORD`
- `WAZUH_VM_CIPASSWORD`

Set both from Vault or the operator environment. The play fails if either variable is empty. Do not commit a replacement value.

## Argo CD admin password

An admin bcrypt hash was committed in:

- `Kubernetes/apps/prod/gitops/argo-cd/values.yaml`
- `Kubernetes/apps/prod/gitops/applications/platform-helm-applicationset.yaml`

Rotate the Argo CD admin password. The Helm chart no longer creates `argocd-secret`. `externalsecret-argocd-admin.yaml` copies these Vault fields into that secret:

- `kubernetes/production/integrations` / `argocd_admin_password_bcrypt`
- `kubernetes/production/integrations` / `argocd_admin_password_mtime`

Store a new bcrypt hash, not the old one and not the plaintext password. Add the Vault fields before Argo CD syncs this change. If Helm previously owned `argocd-secret`, the next sync can drop that object until External Secrets recreates it. Copy `server.secretkey` out of the live secret first if existing sessions must survive.

## HAProxy stats

The Vault and Postgres stats listeners had no authentication. They now require `HAPROXY_STATS_USER` (default `stats`) and `HAPROXY_STATS_PASSWORD`. The password comes from Vault or the environment. The rendered HAProxy config and the Postgres keepalived health check contain it on the host. They must not be committed.

## What this page does not do

It does not expire GitHub history, tags, or forks. Anyone who cloned the old commits should treat the old password and the old Argo CD hash as compromised.
