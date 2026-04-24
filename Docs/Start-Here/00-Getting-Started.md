# Getting started with this repository

This repository contains Ansible, teeraform, and packer code for managing my home lab infrastructure. The hypervisor being used is [Proxmox VE](https://www.proxmox.com/en/proxmox-ve), local DNS is handled by [Technitium DNS](https://technitium.com/dns/) While external DNS is handled by [Cloudflare](https://www.cloudflare.com/).

There is a PXE boot server for provisioning new servers, and a collection of scripts for managing the infrastructure. The code is organized into directories for Ansible, Terraform, Packer, PXE, Kubernetes, and miscellaneous scripts. The PXE server used is [NetbootXYZ](https://netboot.xyz/), which provides a wide range of bootable images for provisioning new servers.

## The Infrastructure

The Infrastructure is made up of the following Hardware components:

- 2x Dell R710 Servers (Proxmox VE Hypervisor)
- 1x Dell T620 Server (Proxmox VE Hypervisor)
- 1x Dell PC (Proxmox VE Hypervisor)
- 1x Gaming PC (Proxmox VE Hypervisor)
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
 ```

### Taskfiles

This repository Makes use of [go-task](https://taskfile.dev/) for task management. The main Taskfile is located at the root of the repository and is used to run various tasks related to the infrastructure. the `.taskfiles/` directory contains additional Taskfiles for specific components of the infrastructure, such as Ansible, vault,  and others.

### The Shell configuration

When you run the `task ansible:configure-localhost` task, it will set up several things the repo will need. The following things will be created for you.

- SSH Certificate Authority and a certificate for localhost
- SSH certificates for each proxmox host configured in `Ansible/group_vars/all/proxmox.yaml`
- SSH certificates for each user configured in `Ansible/group_vars/all/users.yaml`
- Install the required packages for running the tasks in the repository, such as Ansible, Terraform, Packer, docker, and others.
- It will setup the shell configuration for the user, The shell config will be consistent across all machines, and virtual Machines. The main packages setup are the following:- `zsh` as the default shell
  - `ohmyzsh` for managing zsh configuration
  - `zsh-autosuggestions` for command suggestions
  - `zsh-syntax-highlighting` for syntax highlighting
  - `fzf` for fuzzy finding files and commands
  - `kubectl` for managing Kubernetes clusters
  - `k9s` for managing Kubernetes clusters in the terminal
  - `git` for version control
  - and several others which can be found in the `Ansible/group_vars/all/packages.yaml` file under `apt-packages.shell`
- Create a `.env` file in the root of the repository with the following content:

```bash
# .env file
export TF_VAR_proxmox_api_token_id=""
export TF_VAR_proxmox_api_token_secret=""
```

### Ansible

Ansible is used for configuration management and automation of tasks across the infrastructure. The Ansible code is organized into roles and playbooks, which can be found in the `Ansible/` directory.

### Terraform

Terraform is used for managing cloud resources, if any. The Terraform code is organized into modules and configurations, which can be found in the `Terraform/` directory. Ansible is used to run Terraform commands, so you don't have to worry about setting up Terraform on your local machine.

### Packer

Packer is used for building custom images for the Proxmox VE hypervisor. The Packer code is organized into templates and configurations, which can be found in the `Packer/` directory. Ansible is used to run Packer commands, so you don't have to worry about setting up Packer on your local machine.

### PXE

The PXE boot server is used for provisioning new servers. The PXE configuration is organized into templates and configurations, which can be found in the `PXE/` directory. Ansible is used to manage the PXE server, so you don't have to worry about setting up the PXE server on your local machine.

### Kubernetes

Kubernetes manifests and configuration are used for managing Kubernetes clusters, if any. The Kubernetes code is organized into manifests and configurations, which can be found in the `Kubernetes/` directory. Ansible is used to manage the Kubernetes clusters, so you don't have to worry about setting up kubectl or other Kubernetes management tools on your local machine.

### Docs folder

The `Docs/` folder contains documentation for the infrastructure and code. The documentation is organized into markdown files, which can be found in the `Docs/` directory. The documentation includes information on how to set up and manage the infrastructure, as well as how to use the code in the repository. It has documentation regaurding why I chose certain technologies, The network topology, and other useful information about the infrastructure. It also contains useful resources and links for learning more about the technologies used in the infrastructure. It also includes a folder dedicated to general operations and management of the infrastructure, such as how to add new servers, how to manage the PXE server, and how to manage the Kubernetes clusters.
