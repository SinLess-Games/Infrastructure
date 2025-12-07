// Packer/proxmox-templates/ubuntu-template.pkr.hcl

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

////////////////////////////
// Input variables (inherited from your variables.pkr.hcl) //
////////////////////////////

variable "proxmox_url" {}
variable "proxmox_api_token_id" {}
variable "proxmox_api_token_secret" { sensitive = true }
variable "proxmox_node" {}
variable "proxmox_storage_pool" {}
variable "proxmox_template_pool" {}
variable "insecure_skip_tls_verify" {
  type    = bool
  default = false
}

variable "vm_memory" {}
variable "vm_cores" {}
variable "vm_disk_size" {}
variable "vm_network_bridge" {}

variable "ubuntu_iso_url" {}
variable "ubuntu_iso_checksum" {}
variable "ubuntu_iso_storage_pool" {
  type    = string
  default = ""
}

variable "ssh_username" {}
variable "ssh_private_key_file" {}
variable "ssh_timeout" {}

variable "template_name" {
  type        = string
  description = "Name to assign to the resulting Proxmox VM template"
}

/////////////////////////
// Source / Builder definition //
/////////////////////////

source "proxmox-iso" "ubuntu" {
  proxmox_url              = var.proxmox_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.insecure_skip_tls_verify

  node          = var.proxmox_node
  storage_pool  = var.proxmox_storage_pool
  template_pool = var.proxmox_template_pool

  vm_name             = var.template_name
  template_description = "Ubuntu Server template (automated build via Packer)"

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

  boot_iso {
    iso_file     = (var.ubuntu_iso_storage_pool != "" ? "${var.ubuntu_iso_storage_pool}:iso/${basename(var.ubuntu_iso_url)}" : var.ubuntu_iso_url)
    iso_checksum = var.ubuntu_iso_checksum
    unmount      = true
  }

  http_directory         = "http"
  ssh_username           = var.ssh_username
  ssh_private_key_file   = var.ssh_private_key_file
  ssh_timeout            = var.ssh_timeout

  shutdown_command = "shutdown -P now"
}

/////////////////////
// Build / Provision //
/////////////////////

build {
  name    = "ubuntu-template"
  sources = ["source.proxmox-iso.ubuntu"]

  // Run post-install custom script inside VM
  provisioner "shell" {
    script = "scripts/post-install.sh"
  }

  // Clean up for template: machine-id, cloud-init, logs, etc.
  provisioner "shell" {
    inline = [
      "if command -v cloud-init >/dev/null 2>&1; then cloud-init clean --logs; fi",
      "truncate -s 0 /etc/machine-id || true",
      "echo '' > /var/lib/dbus/machine-id || true",
      "sync"
    ]
  }

  post-processor "proxmox-template" {
    convert_to_template = true
  }
}
