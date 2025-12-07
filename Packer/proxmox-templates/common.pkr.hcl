// Packer/proxmox-templates/common.pkr.hcl

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

///////////////////////////
// Common Proxmox builder //
// (to be referenced in child templates) //
///////////////////////////

locals {
  common_disks = [
    {
      disk_size      = var.vm_disk_size
      type           = "virtio"
      storage_pool   = var.proxmox_storage_pool
      storage_type   = "lvm"
    }
  ]

  common_network_adapters = [
    {
      model  = "virtio"
      bridge = var.vm_network_bridge
    }
  ]
}

# This is a sample builder block — use as base for child templates
# Child templates should reference these settings and extend with OS-specific params.

source "proxmox-iso" "common" {
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = var.insecure_skip_tls_verify
  node                     = var.proxmox_node
  vm_name                  = ""        # must be overridden by child
  template_description     = ""        # must be overridden by child
  vm_id                    = ""        # optional override
  qemu_agent               = true

  memory   = var.vm_memory
  cores    = var.vm_cores

  disks = local.common_disks
  network_adapters = local.common_network_adapters

  ssh_username           = var.ssh_username
  ssh_private_key_file   = var.ssh_private_key_file
  ssh_timeout            = var.ssh_timeout

  # child templates must add iso_file/iso_url, boot_command, http_directory, etc.
}

