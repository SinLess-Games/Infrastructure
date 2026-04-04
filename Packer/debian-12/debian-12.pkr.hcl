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
  description = "Proxmox API endpoint URL (for example: https://pve-01:8006/api2/json)"
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
  description = "Proxmox cluster node name for VM build placement (for example: pve-01, not an IP address)"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._-]*$", var.proxmox_node)) && !can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}$", var.proxmox_node))
    error_message = "Proxmox node must be a Proxmox node name (for example pve-01), not an IP address."
  }
}

variable "proxmox_insecure_skip_tls_verify" {
  description = "Skip TLS verification when connecting to Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_iso_storage" {
  description = "Proxmox ISO storage pool"
  type        = string
  default     = "ISOs"
}

variable "proxmox_vm_storage" {
  description = "Proxmox VM disk storage pool"
  type        = string
  default     = "vm_disks_01"
}

variable "vm_name" {
  description = "VM template name"
  type        = string
  default     = "debian-12-template"
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
  default     = "12"
}

variable "debian_iso_url" {
  description = "Debian ISO URL"
  type        = string
  default     = "https://cloudfront.debian.net/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.13.0-amd64-netinst.iso"
}

variable "debian_iso_checksum" {
  description = "Debian ISO checksum"
  type        = string
  default     = "sha256:2b880ffabe36dbe04a662a3125e5ecae4db69d0acce257dd74615bbf165ad76e"
}

# Packer source
source "proxmox-iso" "debian12" {
  # Proxmox connection
  proxmox_url              = var.proxmox_endpoint
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  node                     = var.proxmox_node
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify

  # VM Configuration
  vm_id   = 9001
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
  boot_iso {
    type     = "scsi"
    iso_file = "${var.proxmox_iso_storage}:iso/debian-12.13.0-amd64-netinst.iso"
    unmount  = true
  }

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
    "hostname=debian12 ",
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

}

# Build configuration
build {
  name    = "debian-12"
  sources = ["source.proxmox-iso.debian12"]

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
