```text
Document: 01-Repository-Layout.md
Owner: SinLess Games LLC (Timothy “Andy” Andrew Pierce / sinless777)
Status: DRAFT (Active Development)
Last Updated: 2025-12-27
Scope: Repository structure, conventions, and where to put new work.
```

# Repository Layout

This repo is the single source of truth for:

* bare-metal onboarding (PXE/netboot)
* Proxmox automation (cluster, Ceph, firewall, RBAC)
* image lifecycle (Packer templates)
* provisioning (Terraform)
* Kubernetes platform/apps (FluxCD GitOps)
* security/compliance controls (policy-as-code)
* documentation and runbooks

The layout is designed so you can answer, unambiguously:

* “Where do I change this?”
* “How does it promote dev → staging → prod?”
* “What is enforced by CI vs in-cluster?”

## Top-level directories (proposed standard)

> If a directory does not exist yet, create it using the names below. Avoid inventing parallel structures.

### `Docs/`

Human-readable documentation and architectural artifacts.

* `Docs/Architecture/`

  * `ARCHITECTURE.md` — the cohesive system blueprint
  * `DECISIONS.md` — ADR index
  * `ADRs/` — decision records

* `Docs/Start-Here/`

  * step-by-step bootstrapping guides

* `Docs/Operations/`

  * operational procedures (bootstrapping flow, upgrades)

* `Docs/Runbooks/`

  * incident response playbooks referenced by alerts

### `Taskfile.yaml` and `Tasks/`

Task orchestration is standardized on go-task.

* `Taskfile.yaml` (root)

  * only high-level entry points
  * delegates work to domain taskfiles

* `Tasks/`

  * `Tasks/Ansible/Taskfile.yaml`
  * `Tasks/Terraform/Taskfile.yaml`
  * `Tasks/Packer/Taskfile.yaml`
  * `Tasks/Kubernetes/Taskfile.yaml`
  * `Tasks/PXE/Taskfile.yaml`
  * `Tasks/Policy/Taskfile.yaml`
  * `Tasks/Docs/Taskfile.yaml`

Naming conventions:

* `task lint`, `task fmt`, `task validate` exist per domain.
* `task env:<dev|staging|prod>:plan` and `task env:<dev|staging|prod>:apply` are the primary orchestration tasks.

### `Environments/`

Environment overlays and configuration variables.

* `Environments/Development/`
* `Environments/Staging/`
* `Environments/Production/`

Each environment contains:

* Terraform variables and module composition for that environment
* Ansible inventory/group_vars for that environment
* Kubernetes Kustomize overlays for that environment
* policy overlays and enforcement mode

This keeps “what differs by environment” in one obvious place.

### `PXE/`

Bare-metal provisioning system stored and managed as code.

* `PXE/Infrastructure/`

  * container or VM definitions for the PXE services (dhcp/tftp/http)

* `PXE/iPXE/`

  * iPXE scripts
  * menu definitions

* `PXE/Debian12/`

  * Debian 12 autoinstall/preseed assets
  * cloud-init/first-boot bootstrap scripts

* `PXE/Docs/`

  * node onboarding instructions

### `Ansible/`

Host configuration and Proxmox automation.

Recommended structure:

* `Ansible/Inventory/`

  * `Ansible/Inventory/development/hosts.yaml`
  * `Ansible/Inventory/staging/hosts.yaml`
  * `Ansible/Inventory/production/hosts.yaml`

* `Ansible/GroupVars/` and `Ansible/HostVars/`

  * environment-wide and per-host configuration

* `Ansible/Playbooks/`

  * `bootstrap.yaml` — baseline OS prep and repo bootstrap
  * `proxmox.yaml` — Proxmox install + cluster join
  * `ceph.yaml` — Ceph bootstrap and pool/OSD groups
  * `services.yaml` — platform VMs/services prerequisites (DNS, Vault, MinIO, GitLab)

* `Ansible/Roles/`

  * minimal custom roles
  * prefer Galaxy/collections for Proxmox where feasible

### `Packer/`

VM image lifecycle.

* `Packer/Templates/`

  * `debian12-base/`
  * `rke2-node/`
  * `utility/`

* `Packer/Builds/`

  * build logs, manifests (generated artifacts stored outside Git or in CI artifacts)

### `Terraform/`

Infrastructure provisioning.

* `Terraform/Modules/`

  * `proxmox/` — VM provisioning modules
  * `cloudflare/` — DNS and tunnel route modules
  * `burst/` — cloud expansion modules (ADR-0015)

* `Terraform/Environments/`

  * `development/`
  * `staging/`
  * `production/`

Each environment composes modules and defines its own state.

### `Kubernetes/`

FluxCD-managed platform and application state.

Recommended structure:

* `Kubernetes/Clusters/`

  * `development/`
  * `staging/`
  * `production/`

Each cluster directory includes:

* Flux bootstrap manifests

* a kustomization that points to `Kubernetes/Platform/` and `Kubernetes/Apps/`

* `Kubernetes/Platform/`

  * `base/` — common platform components
  * `overlays/<environment>/` — env-specific overrides

Platform includes:

* cert-manager

* istio

* flagger

* policy engines

* observability stack components

* `Kubernetes/Apps/`

  * app-of-apps structure or per-team structure (but consistent)

### `Policy/`

Policy-as-code controls, organized by domain.

* `Policy/Kubernetes/`

  * `baseline/`
  * `development/`
  * `staging/`
  * `production/`

* `Policy/Terraform/`

  * `tflint/`
  * `checkov/`
  * `tfsec/`
  * `opa/` (optional)

* `Policy/CI/`

  * reusable workflow fragments and rules

### `.github/`

CI workflows, templates, and governance.

* `.github/workflows/`

  * `lint.yaml`
  * `validate.yaml`
  * `security.yaml`
  * `plan.yaml`
  * `apply.yaml`
  * `evidence.yaml`

* `.github/CODEOWNERS`

  * enforce reviews by domain (infra/security/platform)

## Conventions

### Naming

* Directories use `PascalCase` where already established (`Docs/`, `Environments/`, `Kubernetes/`).
* YAML keys and resource names follow Kubernetes conventions.
* Environment names are exactly:

  * `Development`
  * `Staging`
  * `Production`

### Secrets

* No secrets in Git.
* Vault is the system of record (ADR-0012).

### Promotion

* Promotion is PR-based:

  * dev → staging → prod

* Kubernetes promotion uses Flux overlays.

* Terraform promotion uses environment modules and plan/apply gates.

### Evidence

* CI must emit artifacts:

  * Terraform plan output
  * policy scan reports
  * validation logs

## “Where do I put X?” quick map

* new VLAN/bridges/firewall baseline → `Ansible/Playbooks/proxmox.yaml` (+ `GroupVars`)
* Ceph pool/OSD group policy → `Ansible/Playbooks/ceph.yaml`
* VM template change → `Packer/Templates/...`
* Create/scale Kubernetes VMs → `Terraform/Modules/proxmox` + `Terraform/Environments/<env>`
* Install a cluster platform component → `Kubernetes/Platform/base` + overlays
* Expose a service externally → `Terraform/Modules/cloudflare` + `Kubernetes` ingress/gateway
* Add admission policies → `Policy/Kubernetes/...`
* Change CI gates → `.github/workflows/...`

## Next documents

Continue in order:

1. [`Docs/Start-Here/02-Bootstrap-Secrets-Vault.md`](02-Bootstrap-Secrets-Vault.md)
2. [`Docs/Start-Here/03-Bring-Up-Dev.md`](03-Bring-Up-Dev.md)