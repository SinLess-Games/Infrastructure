# Packer configuration
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Packer variables
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
  default     = "vmdisks"
}

variable "vm_name" {
  description = "VM template name"
  type        = string
  default     = "debian-13-template"
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

variable "debian_version" {
  description = "Debian version"
  type        = string
  default     = "13"
}

variable "debian_iso_url" {
  description = "Debian ISO URL"
  type        = string
  default     = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso"
}

variable "debian_iso_checksum" {
  description = "Debian ISO checksum"
  type        = string
  default     = "sha256:c9f09d24b7e834e6834f2ffa565b33d6f1f540d04bd25c79ad9953bc79a8ac02"
}

# Packer source
source "proxmox-iso" "debian13" {
  # Proxmox connection
  proxmox_url              = var.proxmox_endpoint
  insecure_skip_tls_verify = true
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node

  # VM Configuration
  vm_id   = 9000
  vm_name = var.vm_name
  memory  = var.vm_memory
  cores   = var.vm_cores
  sockets = var.vm_sockets

  # Storage configuration
  scsi_controller = "virtio-scsi-pci"
  disks {
    type              = "virtio"
    disk_size         = "20G"
    storage_pool      = var.proxmox_vm_storage
    format            = "raw"
  }

  # Cloud-init drive
  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_vm_storage

  # Network configuration
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # VNC Console
  vga {
    type   = "std"
    memory = 16
  }

  # ISO configuration  
  iso_file = "${var.proxmox_iso_storage}:iso/debian-13.3.0-amd64-netinst.iso"

  # Boot and firmware
  bios = "seabios"
  
  boot_command = [
    "<esc><wait>",
    "auto ",
    "priority=critical ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer/locale=en_US.UTF-8 ",
    "keyboard-configuration/xkb-keymap=us ",
    "netcfg/choose_interface=auto ",
    "hostname=debian13 ",
    "domain=local ",
    "fb=false ",
    "debconf/frontend=noninteractive ",
    "--- <enter>"
  ]

  http_directory = "http"
  http_port_min  = 8802
  http_port_max  = 8820

  # Boot wait
  boot_wait = "15s"

  # SSH configuration
  ssh_username           = "root"
  ssh_password           = "packer"
  ssh_timeout            = "30m"
  ssh_wait_timeout       = "20m"
  ssh_handshake_attempts = 150

  # Shutdown settings
  disable_kvm = false

  # Template configuration
  template_name        = var.vm_name
  template_description = "Debian ${var.debian_version} template built by Packer"

  # Enable template mode
  unmount_iso = true
}

# Build configuration
build {
  name    = "debian-13"
  sources = ["source.proxmox-iso.debian13"]

  # Wait for boot
  provisioner "shell" {
    inline       = ["echo 'Waiting for system to stabilize...'"]
    pause_before = "30s"
  }

  # Update system
  provisioner "shell" {
    script = "${path.root}/scripts/update-system.sh"
  }

  # Install cloud-init (optional but recommended for cloud environments)
  provisioner "shell" {
    script = "${path.root}/scripts/install-cloud-init.sh"
  }

  # Clean up
  provisioner "shell" {
    script = "${path.root}/scripts/cleanup.sh"
  }

  # Shutdown VM to convert to template
  provisioner "shell" {
    inline            = ["shutdown -P now"]
    expect_disconnect = true
    timeout           = "5m"
    skip_clean        = true
  }

}
