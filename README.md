# Infrastructure

This repository contains the **Infrastructure as Code (IaC)** for the SinLess Games platform.  
It is the authoritative source for provisioning, configuring, and maintaining:

- Local development environments
- Proxmox infrastructure
- Kubernetes clusters
- Core platform services
- Automation tooling

The repository is designed to be **reproducible**, **auditable**, and **automation-first**.

---

## Repository Structure

```text
.
├── Ansible/        # Configuration management and system provisioning
├── Kubernetes/     # Cluster definitions, apps, and GitOps manifests
├── Terraform/      # Infrastructure provisioning (Proxmox, cloud, etc.)
└── scripts/        # Bootstrap and helper scripts
````

---

## Requirements

The following tools are required to work with this repository:

* **go-task** — task runner used as the primary command interface
  [https://taskfile.dev/docs/installation](https://taskfile.dev/docs/installation)

Additional tools (Ansible, Terraform, etc.) will be installed automatically during initialization where possible.

---

## Getting Started

### 1. Initialize the Repository

This step bootstraps the repository and ensures required tooling is available.

#### If `go-task` is already installed:

```bash
task init
```

#### If `go-task` is NOT installed:

```bash
./scripts/initialize-repo.sh
```

The initialization process will:

* Verify system prerequisites
* Install `go-task` if missing
* Prepare local tooling and configuration
* Validate repository structure

---

### 2. Configure the Localhost

Once the repository is initialized, configure your local machine so it can run Ansible, Terraform, and Kubernetes workflows.

```bash
task ansible:configure-localhost
```

This will:

* Install required packages and dependencies
* Configure shells, paths, and tooling
* Prepare Ansible for local and remote execution
* Ensure the system is ready to manage infrastructure

> This step is **required** before running any Ansible playbooks or Terraform workflows.

---

## Workflow Philosophy

* **Taskfile is the interface** — use `task` commands instead of running tools directly
* **Declarative first** — infrastructure and configuration are defined in code
* **Idempotent operations** — safe to re-run tasks and playbooks
* **Separation of concerns** — Terraform provisions, Ansible configures, Kubernetes runs workloads

---

## Common Commands

List all available tasks:

```bash
task --list
```

Run a specific task:

```bash
task <task-name>
```

---

## Notes

* This repository assumes a Linux-based environment (Ubuntu preferred).
* Changes should be committed through Git with clear messages.
* Secrets are **never** stored directly in this repository.

---

## Status

This repository is actively developed and evolving alongside the platform architecture.

