# Copilot Instructions for SinLess Games Infrastructure

## Project Overview

This repository is the infrastructure monorepo for SinLess Games LLC. It manages Proxmox-backed virtual machines, Kubernetes clusters, DNS, storage services, and workstation/bootstrap automation with Ansible, Terraform, Packer, and Vault.

Treat the repository as the source of truth for the current architecture. Prefer describing what is implemented here today over aspirational or historical designs.

**Primary technologies**
- **Proxmox VE** for hypervisor and VM lifecycle
- **Ansible** for configuration management and orchestration
- **Terraform** for VM provisioning and secrets-related infrastructure logic
- **Packer** for image/template creation
- **Vault** for secrets and bootstrap material
- **Kubernetes / Talos** as the intended cluster platform direction

## Current Repository Shape

### Ansible

Custom domain roles live in [Ansible/roles](../Ansible/roles):
- `proxmox`
- `kubernetes`
- `vault`
- `postgres`
- `minio`
- `technitium`
- shared foundation roles such as `users`, `ssh`, `shell-config`, `packages`, and `dns-resolver`

Role-local templates have been consolidated into [Ansible/templates](../Ansible/templates). Do not reintroduce `templates/` directories inside roles unless there is a compelling reason.

Group variables are organized by domain in [Ansible/group_vars](../Ansible/group_vars):
- [all](../Ansible/group_vars/all)
- [kubernetes](../Ansible/group_vars/kubernetes)
- [minio](../Ansible/group_vars/minio)
- [postgres](../Ansible/group_vars/postgres)
- [proxmox](../Ansible/group_vars/proxmox)
- [technitium](../Ansible/group_vars/technitium)
- [vault](../Ansible/group_vars/vault)
- [zsh](../Ansible/group_vars/zsh)

### Terraform

VM provisioning has been consolidated into a shared module at [Terraform/modules/proxmox-vm-cluster](../Terraform/modules/proxmox-vm-cluster).

The only other active Terraform module today is [Terraform/modules/vault-secrets](../Terraform/modules/vault-secrets).

If you see older service-specific VM module references, treat them as stale and migrate them toward the shared Proxmox VM module instead of adding more duplication.

## Preferred Workflows

### Use Repository Wrappers First

Prefer the repository task wrappers under [.taskfiles](../.taskfiles) when they exist. They standardize the Python virtualenv, Ansible config, and common arguments.

Common Ansible entrypoints are defined in [.taskfiles/Ansible/Taskfile.yaml](../.taskfiles/Ansible/Taskfile.yaml), including:
- `configure-localhost`
- `setup-proxmox-nodes`
- `setup-technitium`
- `deploy-vault`
- `deploy-postgres`
- `deploy-minio`
- `k8s:dev`
- `k8s:dev:plan`
- `k8s:dev:destroy`

When direct tool invocation is necessary, use the repo-managed virtualenv at [Ansible/.venv](../Ansible/.venv) and the repo Ansible config at [Ansible/ansible.cfg](../Ansible/ansible.cfg).

### Active Playbooks

The primary maintained playbooks in [Ansible/playbooks](../Ansible/playbooks) are:
- [configure-localhost.yaml](../Ansible/playbooks/configure-localhost.yaml)
- [setup-proxmox-nodes.yaml](../Ansible/playbooks/setup-proxmox-nodes.yaml)
- [setup-technitium.yaml](../Ansible/playbooks/setup-technitium.yaml)
- [deploy-vault.yaml](../Ansible/playbooks/deploy-vault.yaml)
- [deploy-postgres.yaml](../Ansible/playbooks/deploy-postgres.yaml)
- [deploy-minio.yaml](../Ansible/playbooks/deploy-minio.yaml)
- [deploy-kubernetes-dev.yaml](../Ansible/playbooks/deploy-kubernetes-dev.yaml)
- [deploy-kubernetes-staging.yaml](../Ansible/playbooks/deploy-kubernetes-staging.yaml)
- [deploy-kubernetes-prod.yaml](../Ansible/playbooks/deploy-kubernetes-prod.yaml)

When adding new automation, prefer extending existing domain playbooks and roles before creating new one-off role splits.

## Architecture Guidance

### Domain-First Role Design

The repo has moved away from split roles like `*-deploy`, `*-configure`, and service-specific Terraform VM modules. Keep that direction:
- prefer one domain role per service
- keep orchestration phases inside the domain role
- move reusable logic into shared roles or shared templates
- avoid duplicating nearly identical Terraform or template code per service

### Proxmox

There is one active Proxmox domain role: [Ansible/roles/proxmox](../Ansible/roles/proxmox).

The Proxmox path no longer includes separate HA UI or dedicated Proxmox HA VM orchestration. Do not add new Proxmox HA VM logic back into that role unless the architecture is intentionally changing.

The Proxmox role is responsible for the cluster/node lifecycle areas that still exist in this repo, such as node configuration, certificates, networking, storage, permissions, and related bootstrap steps.

### Shared Routing Templates

HAProxy, Keepalived, and health-check templates were consolidated under [Ansible/templates/haproxy](../Ansible/templates/haproxy) for use by dedicated routing VMs. Those templates are shared infrastructure assets and should not be re-duplicated per service.

### Kubernetes

Kubernetes configuration is environment-oriented under [Ansible/group_vars/kubernetes](../Ansible/group_vars/kubernetes) with `development`, `staging`, and `production` overlays.

Favor putting shared defaults in the common Kubernetes vars and reserving environment folders for topology or environment-specific overrides.

Talos should be treated as the target Kubernetes node OS and control-plane approach. Prefer Talos-oriented guidance, naming, and automation decisions over older RKE2 assumptions when updating Kubernetes docs, templates, or playbooks.

## Secrets and Sensitive Data

Do not commit secrets to Git.

Current secret-handling expectations:
- keep runtime credentials out of tracked Terraform tfvars files
- prefer Vault, token files, environment variables, or other runtime-only inputs
- the repo root `.env` is intentionally gitignored and may be generated locally by Ansible
- [.envrc](../.envrc) is expected to load `.env` when present

Examples of acceptable patterns:
- `TF_VAR_*` environment variables for Terraform credentials
- Vault-managed secrets referenced by Ansible variables
- gitignored local files such as `.env`

Examples of unacceptable patterns:
- embedding API tokens in [Terraform/main.auto.tfvars](../Terraform/main.auto.tfvars)
- checking in local `.env` files
- duplicating secrets across multiple var files

## Editing Conventions

- Prefer updating existing domain roles instead of creating new overlapping roles.
- Prefer shared templates in [Ansible/templates](../Ansible/templates) over role-local duplicates.
- Prefer consolidating repeated variables into [Ansible/group_vars/all](../Ansible/group_vars/all) when they are truly global.
- Keep production defaults minimal and security-minded.
- Keep shell and developer conveniences separated from production runtime packages.
- When changing Zsh or prompt behavior, update the native Zsh templates in [Ansible/templates/zsh](../Ansible/templates/zsh) rather than reintroducing Starship.

## Validation Expectations

After changing Ansible code, prefer validating with:

```bash
ANSIBLE_CONFIG=Ansible/ansible.cfg Ansible/.venv/bin/ansible-playbook -i Ansible/inventory Ansible/playbooks/<playbook>.yaml --syntax-check
```

After changing Terraform modules, prefer validating formatting and module references, for example:

```bash
terraform fmt -check -recursive Terraform/modules
```

If you update shared module or template paths, verify that playbooks, group vars, and templates no longer reference removed locations.

## Common Pitfalls

1. Do not describe deleted split roles as active architecture.
2. Do not introduce new duplicated Terraform VM modules for each service.
3. Do not place secrets in tracked tfvars, inventory, or group vars files.
4. Do not reintroduce role-local template sprawl when a shared template path already exists.
5. Do not assume historical infrastructure details are still authoritative; verify against the repo first.

## File Landmarks

- [Ansible/roles](../Ansible/roles)
- [Ansible/playbooks](../Ansible/playbooks)
- [Ansible/group_vars](../Ansible/group_vars)
- [Ansible/templates](../Ansible/templates)
- [Ansible/inventory](../Ansible/inventory)
- [Terraform/modules/proxmox-vm-cluster](../Terraform/modules/proxmox-vm-cluster)
- [Terraform/modules/vault-secrets](../Terraform/modules/vault-secrets)
- [Packer](../Packer)
- [Docs](../Docs)
