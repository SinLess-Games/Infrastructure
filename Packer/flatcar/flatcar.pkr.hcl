# Packer configuration for Flatcar Container Linux
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variables
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (user@realm!token-name)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node for building VMs"
  type        = string
}

variable "proxmox_iso_storage" {
  description = "Proxmox ISO storage pool"
  type        = string
  default     = "ISOs"
}

variable "proxmox_vm_storage" {
  description = "Proxmox VM disk storage pool"
  type        = string
  default     = "VM_Disks"
}

variable "vm_name" {
  description = "VM template name"
  type        = string
  default     = "flatcar-template"
}

variable "vm_id" {
  description = "VM template ID"
  type        = number
  default     = 9002
}

variable "vm_memory" {
  description = "VM memory in MB"
  type        = number
  default     = 2048
}

variable "vm_cores" {
  description = "VM CPU cores"
  type        = number
  default     = 2
}

variable "vm_sockets" {
  description = "VM CPU sockets"
  type        = number
  default     = 1
}

variable "flatcar_version" {
  description = "Flatcar version (e.g., current, 4111.2.1)"
  type        = string
  default     = "current"
}

variable "flatcar_channel" {
  description = "Flatcar release channel (stable, beta, alpha)"
  type        = string
  default     = "stable"
}

# Flatcar uses a different approach - we import a pre-built image
# This is a null build that will use a local script to import the image
source "null" "flatcar-import" {
  communicator = "none"
}

build {
  sources = ["source.null.flatcar-import"]

  # Download Flatcar QEMU image
  provisioner "shell-local" {
    inline = [
      "echo 'Downloading Flatcar Container Linux ${var.flatcar_channel} ${var.flatcar_version}...'",
      "mkdir -p /tmp/flatcar-download",
      "cd /tmp/flatcar-download",
      "curl -L -O https://${var.flatcar_channel}.release.flatcar-linux.net/amd64-usr/${var.flatcar_version}/flatcar_production_qemu_image.img.bz2",
      "curl -L -O https://${var.flatcar_channel}.release.flatcar-linux.net/amd64-usr/${var.flatcar_version}/flatcar_production_qemu_image.img.bz2.sig",
      "echo 'Decompressing image...'",
      "bunzip2 -f flatcar_production_qemu_image.img.bz2",
      "echo 'Image ready for import: /tmp/flatcar-download/flatcar_production_qemu_image.img'"
    ]
  }

  # Import to Proxmox via SSH
  provisioner "shell-local" {
    environment_vars = [
      "PROXMOX_NODE=${var.proxmox_node}",
      "VM_ID=${var.vm_id}",
      "VM_NAME=${var.vm_name}",
      "VM_STORAGE=${var.proxmox_vm_storage}",
      "VM_MEMORY=${var.vm_memory}",
      "VM_CORES=${var.vm_cores}",
      "VM_SOCKETS=${var.vm_sockets}"
    ]
    script = "${path.root}/import-to-proxmox.sh"
  }

  # Cleanup local download
  provisioner "shell-local" {
    inline = [
      "rm -rf /tmp/flatcar-download",
      "echo 'Local cleanup completed'"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
