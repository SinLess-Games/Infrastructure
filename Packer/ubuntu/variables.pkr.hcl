// Packer/ubuntu/variables.pkr.hcl
// Common variable definitions for building Ubuntu VMs/templates on Proxmox with Packer

//////////////////////////////
// Proxmox API & connection  //
//////////////////////////////

variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL (including https:// and port 8006), e.g. https://pve.yourdomain:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID (e.g. 'packer@pve!tokenname')"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name on which to create the VM / template"
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Storage pool name for VM disks (e.g. local-lvm, local)"
}

variable "proxmox_template_pool" {
  type        = string
  description = "Storage pool where resulting VM template or disk should reside (may be same as storage_pool)"
}

variable "insecure_skip_tls_verify" {
  type        = bool
  default     = false
  description = "Whether to skip TLS certificate verification when connecting to Proxmox API"
}

//////////////////////
// VM resource sizing //
//////////////////////

variable "vm_memory" {
  type        = number
  default     = 2048
  description = "Default RAM (in MB) allocated to built VMs"
}

variable "vm_cores" {
  type        = number
  default     = 2
  description = "Default number of CPU cores for built VMs"
}

variable "vm_disk_size" {
  type        = string
  default     = "20G"
  description = "Default disk size for built VMs (e.g. \"20G\", \"40G\")"
}

variable "vm_network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Default Proxmox network bridge for VM NICs"
}

/////////////////////////////
// Ubuntu ISO / Installer specifics //
/////////////////////////////

variable "ubuntu_iso_url" {
  type        = string
  description = "URL (or local path) to the Ubuntu server ISO for installation"
}

variable "ubuntu_iso_checksum" {
  type        = string
  description = "Checksum of the Ubuntu ISO (e.g. sha256) for integrity verification"
}

variable "ubuntu_iso_storage_pool" {
  type        = string
  default     = ""
  description = "If the ISO should be uploaded to Proxmox storage pool, specify the pool name; otherwise leave empty"
}

/////////////////////////
// SSH / communicator  //
/////////////////////////

variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "SSH username for provisioning after install"
}

variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "Path to SSH private key file for Packer to connect"
}

variable "ssh_timeout" {
  type        = string
  default     = "30m"
  description = "Timeout duration for SSH provisioning"
}
