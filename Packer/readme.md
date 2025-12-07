# Packer — VM Template Builder for SinLess Games Infrastructure

## 📋 Purpose & Overview

This directory contains all Packer configurations, scripts, and automation needed to build VM templates (Ubuntu and Flatcar) for use on Proxmox VE.  
Those templates form the “golden images” you clone from when provisioning new VMs — ensuring consistency, repeatability, and ease of management across your infrastructure.

The setup supports:

- Automated build of Ubuntu Server images (via autoinstall + cloud-init).  
- Automated build of Flatcar Container Linux images using Ignition.  
- Modular, reusable HCL-based Packer templates.  
- Post-install cleanup and templating (zero-out space, remove logs, reset machine-ID, etc.).  
- Static-IP / network config via cloud-init (if desired) or DHCP.  
- Flexible provisioning using shell scripts for additional setup (e.g. QEMU guest agent, package install, system hardening).  

---

## 📁 Directory Structure

```bash

Packer/
├── flatcar/
│   ├── flatcar.json            # Main Packer template for Flatcar on Proxmox
│   ├── variables.json          # Variables — image URL, checksum, etc.
│   ├── http/
│   │   └── ignition.yaml       # Ignition (Butane) config for Flatcar
│   └── scripts/
│       └── post-setup.sh       # Post-boot cleanup / optimization
│
├── proxmox-templates/
│   ├── ubuntu-template.pkr.hcl  # Generalized Ubuntu template, imports global vars
│   ├── flatcar-template.pkr.hcl # Generalized Flatcar template
│   ├── common.pkr.hcl           # Shared builder/provisioner defaults & var definitions
│   └── variables.pkr.hcl        # Global variables (Proxmox API creds, storage pools, sizing)
│
├── scripts/
│   ├── cloud-init/
│   │   ├── meta-data
│   │   ├── user-data
│   │   └── network-config
│   ├── system/
│   │   ├── cleanup.sh          # System cleanup routine (logs, cache, etc.)
│   │   ├── qemu-guest-agent.sh # Installs/enables QEMU Guest Agent
│   │   └── base-packages.sh    # Installs baseline packages
│   └── installers/
│       └── ubuntu-autoinstall.sh  # (Optional) helper for Ubuntu automated installs
│
└── ubuntu/
├── ubuntu.pkr.hcl          # Core Ubuntu Packer template (ISO-based)
├── http/
│   ├── autoinstall.yaml    # Autoinstall config for Ubuntu Server
│   └── grub.cfg            # Custom GRUB to trigger unattended install
├── variables.pkr.hcl       # Ubuntu-specific variables (ISO URL, disk size, etc.)
└── scripts/
└── post-install.sh     # Post-install script: hardening, cleanup, tool install

````

---

## ⚙️ Getting Started — Quick Build Workflow

Below is a typical workflow to build a new Ubuntu or Flatcar template.  

### 1. Prepare Variables

- Copy/edit `proxmox-templates/variables.pkr.hcl` to inject your Proxmox settings (API URL, token ID + secret, node name, storage pools, default VM sizing, network bridge, etc.).  
- Use a `.auto.pkrvars.hcl` (or custom var file) to fill in sensitive or environment-specific values so they stay out of committed templates.  

### 2. (For Ubuntu) Ensure ISO + Autoinstall Files Are Present

- Download the correct Ubuntu Server ISO (live server).  
- Ensure `ubuntu/http/autoinstall.yaml` contains a valid configuration (hostname, user, SSH key, timezone, packages, etc.).  
- Optionally customize static-IP, packages, timezone, shell (zsh), and provisioning scripts.  

### 3. Build the Template

```bash
# From Packer/ root
packer init .

# Build Ubuntu
packer build -var-file=proxmox-templates/variables.pkr.hcl ubuntu/ubuntu.pkr.hcl

# or Build Flatcar
packer build -var-file=proxmox-templates/variables.pkr.hcl flatcar/flatcar.json
````

> ⚠️ Ensure your Packer version supports HCL2 (modern versions do), and that the required Proxmox plugin is installed.

### 4. Verify the Template in Proxmox

Once Packer finishes, you should find a new VM template (Ubuntu or Flatcar) in your Proxmox storage pool, ready for cloning.

You can then clone — or provision via Terraform/automation — to spin up new VMs with consistent baseline configuration.

---

## ✅ Why This Layout & Best Practices

- **Modularity & Reuse:** By splitting templates, variables, and provisioning scripts, you avoid duplication and make it easy to extend or modify builds. This aligns with general best practices for Packer usage.
- **Idempotency:** Templates and provisioning are designed to create consistent, repeatable images regardless of how many times you rebuild — minimizing configuration drift.
- **Immutable / Clean Base Images:** Post-install cleanup (zero-out free space, reset machine-ID, clear logs) helps ensure VM clones start with “clean slate.”
- **Separation of Sensitive Data:** Variables such as API tokens and SSH keys are stored outside the template logic, making it safer to track configuration in version control.
- **Flexibility:** You can extend or swap parts — for example, change Ubuntu version, add additional provisioning scripts, or switch network / disk layout — without rewriting core templates.

---

## 🛠️ Extending & Customization — What You Can Do

- Add more provisioning scripts (e.g. install monitoring agents, container runtimes, company defaults).
- Customize `autoinstall.yaml` or Ignition config for additional setup (users, services, packages, networking).
- Create variant templates (e.g. for different VM roles: build-server, database, Kubernetes node) — by layering on top of base templates.
- Integrate with configuration management (Ansible, Terraform, Salt, etc.) — use these base templates as starting point for final VM config.
- Automate rebuilds (cron, CI/CD) — to keep templates up to date with OS and security patches.

---

## 📝 Notes & Gotchas

- Be sure not to commit sensitive credentials or SSH private keys to public repos. Use `.gitignore` or secret-management solutions.
- If using static IPs or specialized network configs: double-check the network bridge, IP/Subnet/Gateway in your cloud-init or Ignition configs to avoid network misconfiguration.
- Flatcar is immutable by design — avoid installing packages via package manager unless using recommended methods (containers, overlays, etc.).
- Ensure your Proxmox storage pools and bridges match what’s referenced in variables — mismatches will cause build failures.

---

## 📚 References & Inspiration

- Best practices for writing README & project documentation.
- Official documentation on Packer templates (HCL2, builders, provisioners, post-processors).
- Example Packer-Flatcar template repo implementing QEMU/Flatcar + Packer + Ignition.

---

## 🔧 Contact / Ownership

This structure and set of templates are maintained by **SinLess Games LLC (you)**.
Feel free to copy, modify, and extend — this setup is tailored to your infrastructure needs but designed to be adaptable.

---
