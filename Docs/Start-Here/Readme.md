# Getting started with this repository.

This repository contains Ansible, teeraform, and packer code for managing my home lab infrastructure. The hypervisor being used is [Proxmox VE](https://www.proxmox.com/en/proxmox-ve), local DNS is handled by [Technitium DNS](https://technitium.com/dns/) While external DNS is handled by [Cloudflare](https://www.cloudflare.com/).

## The Infrastucture

The Infrastructure is made up of the following Hardware components:

- 2x Dell R710 Servers (Proxmox VE Hypervisor)\
- 1x Dell T620 Server (Proxmox VE Hypervisor)\
- 1x Dell PC (Proxmox VE Hypervisor)\
- 1x Gaming PC (Proxmox VE Hypervisor)\
- 1x raspberry Pi 3 (Technitium DNS Server)
- 1x Unifi USG Pro 4 (Router)
- 2x Unifi 24 port Switches (Switches)
- 1x Unifi Agragation Switch (Switch) [10GB sfp+]
- 1x Unifi AC LR Pro (Wireless Access Point)

## The Code

The code in this repository is organized into the following directories:

```bash
. Infrastructure/
    ├── Ansible/ # Ansible code for managing the infrastructure
    ├── Packer/ # Packer code for building custom images
    ├── PXE/ # PXE boot configuration for provisioning new servers
    ├── Docs/ # Documentation for the infrastructure and code
    ├── Terraform/ # Terraform code for managing cloud resources (if any)
    ├── scripts/ # Miscellaneous scripts for managing the infrastructure
    ├── Kubernetes/ # Kubernetes manifests and configuration (if any)
    ├── Policies/ # Security and compliance policies for the infrastructure
```

## Taskfiles

This repository Makes use of [go-task](https://taskfile.dev/) for task management. The main Taskfile is located at the root of the repository and is used to run various tasks related to the infrastructure. the `.taskfiles/` directory contains additional Taskfiles for specific components of the infrastructure, such as Ansible, vault,  and others.

### Ansible

### Terraform

### Packer

### PXE

### Kubernetes

### Policies

### Scripts

## Start Here

The start here folder contains step by step guides for getting started, Building, and managing the infrastructure. It is recommended to start with the `00-Getting-Started.md` file, which provides an overview of the infrastructure and the code, as well as instructions for setting up the necessary tools and dependencies. From there, you can follow the other guides in the folder to learn how to build and manage the infrastructure.

The file names start with the step number, followed by a brief description of the task. For example, `00-Getting-Started.md` is the first step, which provides an introduction to the repository and instructions for getting started. `01-Initialization-and-Setup.md` is the second step, which covers the initial setup and configuration of the infrastructure. `02-Building-the-Infrastructure.md` is the third step, which provides instructions for building the infrastructure using Ansible and Terraform. `03-Managing-the-Infrastructure.md` is the fourth step, which covers ongoing management and maintenance of the infrastructure.
