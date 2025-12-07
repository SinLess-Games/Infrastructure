// Packer/proxmox-templates/flatcar-template.pkr.hcl

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

//////////////////////////
// Input variables reuse //
//////////////////////////

variable "flatcar_img_url" {
  type        = string
  description = "URL (or local Proxmox storage path) to Flatcar Container Linux image/ISO"
}

variable "flatcar_img_checksum" {
  type        = string
  description = "Checksum for the Flatcar image/ISO (e.g. sha256 or sha512)"
}

variable "flatcar_template_name" {
  type        = string
  description = "Name of the resulting Proxmox template"
}

//////////////////////////
// Source / Builder config //
//////////////////////////

source "proxmox-iso" "flatcar" {
  proxmox_url              = var.proxmox_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  node         = var.proxmox_node
  storage_pool = var.proxmox_storage_pool
  template_pool = var.proxmox_template_pool

  vm_name        = var.template_name
  template_description = "Flatcar Container Linux base template"

  memory = var.vm_memory
  cores  = var.vm_cores

  disks = [
    {
      disk_size    = var.vm_disk_size
      type         = "virtio"
      storage_pool = var.proxmox_storage_pool
      storage_type = "lvm"
    }
  ]

  network_adapters = [
    {
      model  = "virtio"
      bridge = var.vm_network_bridge
    }
  ]

  # Flatcar image source — can be an img or ISO depending on your setup  
  iso_url      = var.flatcar_img_url
  iso_checksum = var.flatcar_img_checksum
  iso_storage_pool = var.proxmox_storage_pool
  unmount_iso  = true

  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = var.ssh_timeout

  shutdown_command = "shutdown -P now"
}

////////////////////////
// Provisioning steps //
////////////////////////

build {
  name    = "flatcar-template"
  sources = ["source.proxmox-iso.flatcar"]

  provisioner "file" {
    source      = "flatcar/http/"
    destination = "/tmp/flatcar-config"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /boot/flatcar-ignition",
      "cp /tmp/flatcar-config/*.ign /boot/flatcar-ignition/",
      "sync"
    ]
  }

  provisioner "shell" {
    script = "../../flatcar/scripts/post-setup.sh"
  }
}

///////////////////////////
// Post-processing (template conversion) //
///////////////////////////

post-processor "proxmox-template" {
  convert_to_template = true
}
