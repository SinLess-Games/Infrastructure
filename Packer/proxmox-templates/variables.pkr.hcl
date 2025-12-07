// Packer/proxmox-templates/variables.pkr.hcl
// Common variable definitions for Proxmox-Packer builds

// Proxmox API & authentication
variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL, including protocol and port, e.g. https://pve.example.com:8006/api2/json"
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

// Proxmox target node & storage pools
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
  description = "Storage pool where the resulting VM template (or disk) will reside (may be same as storage_pool)"
}

// TLS / connectivity
variable "insecure_skip_tls_verify" {
  type        = bool
  default     = false
  description = "Whether to skip TLS certificate verification when connecting to Proxmox API"
}

// VM resource sizing
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
  default     = "8G"
  description = "Default disk size for built VMs (e.g. \"8G\", \"20G\")"
}

// Networking
variable "vm_network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Default Proxmox network bridge for VM NICs"
}

// SSH / Communicator settings for provisioning
variable "ssh_username" {
  type        = string
  description = "SSH username for Packer provisioning"
}

variable "ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "SSH private key file path for SSH communicator"
}

variable "ssh_timeout" {
  type        = string
  default     = "30m"
  description = "SSH timeout duration for Packer provisioning"
}
