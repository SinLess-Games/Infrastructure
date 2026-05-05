# Generated Packer HCL for ubuntu-22.04
# Ansible/templates/packer/vm.pkr.hcl.j2
#
# This template is rendered by Ansible into:
#   Packer/<distro>/<distro>.pkr.hcl
#
# Supported installer flows:
#   - Debian: preseed
#   - Ubuntu live-server: autoinstall / NoCloud

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# -----------------------------------------------------------------------------
# Proxmox connection
# -----------------------------------------------------------------------------

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_insecure_skip_tls_verify" {
  type    = bool
  default = true
}

# -----------------------------------------------------------------------------
# Proxmox storage
# -----------------------------------------------------------------------------

variable "proxmox_iso_storage" {
  type    = string
  default = "local"
}

variable "proxmox_vm_storage" {
  type    = string
  default = "local-lvm"
}

# -----------------------------------------------------------------------------
# VM template identity
# -----------------------------------------------------------------------------

variable "vm_name" {
  type    = string
  default = "ubuntu-22.04-template-pve-01"
}

variable "vm_id" {
  type    = number
  default = 9006
}

variable "template_description" {
  type    = string
  default = "Ubuntu 22.04 template built by Packer for pve-01"
}

# -----------------------------------------------------------------------------
# VM hardware
# -----------------------------------------------------------------------------

variable "vm_memory" {
  type    = number
  default = 4096
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_sockets" {
  type    = number
  default = 1
}

variable "vm_disk_size" {
  type    = string
  default = "25G"
}

variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}

variable "disable_kvm" {
  type    = bool
  default = false
}

# -----------------------------------------------------------------------------
# ISO / distro metadata
# -----------------------------------------------------------------------------

variable "iso_filename" {
  type    = string
  default = "ubuntu-22.04.5-live-server-amd64.iso"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
}

variable "distro" {
  type    = string
  default = "ubuntu-22.04"
}

variable "distro_family" {
  type    = string
  default = "ubuntu"
}

variable "installer_type" {
  type    = string
  default = "autoinstall"
}

variable "debian_version" {
  type    = string
  default = ""
}

# -----------------------------------------------------------------------------
# SSH used by Packer after install
# -----------------------------------------------------------------------------

variable "ssh_username" {
  type = string
  default = "packer"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "packer"
}

variable "ssh_timeout" {
  type    = string
  default = "60m"
}

variable "ssh_handshake_attempts" {
  type    = number
  default = 300
}

# -----------------------------------------------------------------------------
# Proxmox ISO builder
# -----------------------------------------------------------------------------

source "proxmox-iso" "vm_template" {
  proxmox_url              = var.proxmox_endpoint
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  vm_id   = var.vm_id
  vm_name = var.vm_name

  memory  = var.vm_memory
  cores   = var.vm_cores
  sockets = var.vm_sockets

  scsi_controller = "virtio-scsi-pci"

  disks {
    type         = "virtio"
    disk_size    = var.vm_disk_size
    storage_pool = var.proxmox_vm_storage
    format       = "raw"
  }

  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_vm_storage

  network_adapters {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  vga {
    type   = "std"
    memory = 16
  }

  boot_iso {
    type     = "scsi"
    iso_file = "${var.proxmox_iso_storage}:iso/${var.iso_filename}"
    unmount  = true
  }

  bios      = "seabios"
  boot_wait = "15s"

  # Ubuntu live-server / Subiquity autoinstall.
  #
  # This enters the GRUB command line and boots the live-server kernel directly.
  # The escaped semicolon in ds=nocloud-net\;s= is required.
  #
  # HTTP server content expected:
  #   http/user-data
  #   http/meta-data
  #   http/vendor-data
  boot_command = [
    "<wait5>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ip=dhcp ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  http_directory = "${path.root}/http"
  http_port_min  = 8802
  http_port_max  = 8820

  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = var.ssh_timeout
  ssh_wait_timeout       = var.ssh_timeout
  ssh_handshake_attempts = var.ssh_handshake_attempts

  disable_kvm = var.disable_kvm

  template_name        = var.vm_name
  template_description = var.template_description
}

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

build {
  name    = "ubuntu-22.04-pve-01"
  sources = ["source.proxmox-iso.vm_template"]

  provisioner "shell" {
    inline = [
      "echo 'Waiting for system to stabilize before provisioning...'"
    ]
    pause_before = "30s"
  }

  provisioner "shell" {
    script = "${path.root}/scripts/update-system.sh"
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{ .Path }}'"
  }

  provisioner "shell" {
    script = "${path.root}/scripts/install-cloud-init.sh"
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{ .Path }}'"
  }

  provisioner "shell" {
    script = "${path.root}/scripts/cleanup.sh"
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{ .Path }}'"
  }

  provisioner "shell" {
    inline = [
      "echo '${var.ssh_password}' | sudo -S shutdown -P now"
    ]
    expect_disconnect = true
    timeout           = "5m"
    skip_clean        = true
  }
}
