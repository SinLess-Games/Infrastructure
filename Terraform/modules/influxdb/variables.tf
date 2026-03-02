# =====================================================================
# InfluxDB Terraform Module Variables
# =====================================================================

# ---------------------------------------------------------------------
# General Configuration
# ---------------------------------------------------------------------

variable "cluster_name" {
  description = "Name identifier for the InfluxDB deployment (used for naming resources)"
  type        = string
  default     = "influxdb"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# ---------------------------------------------------------------------
# Proxmox Target Configuration
# ---------------------------------------------------------------------

variable "target_node" {
  description = "Proxmox node name where the InfluxDB VM will be deployed"
  type        = string
}

variable "clone_template" {
  description = "Name of the VM template to clone (e.g., debian-13-template)"
  type        = string
}

# ---------------------------------------------------------------------
# VM Identity
# ---------------------------------------------------------------------

variable "node_name" {
  description = "Name of the InfluxDB VM"
  type        = string
  default     = "influxdb-01"
}

variable "vm_id" {
  description = "Proxmox VM ID for the InfluxDB VM"
  type        = number
  default     = 212
}

variable "force_create" {
  description = "Whether to force recreation of the VM if the VMID already exists"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------
# Resource Allocation
# ---------------------------------------------------------------------

variable "cpu_cores" {
  description = "Number of CPU cores for the InfluxDB VM"
  type        = number
  default     = 4
}

variable "cpu_sockets" {
  description = "Number of CPU sockets for the InfluxDB VM"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory allocation for the InfluxDB VM (MB)"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "Disk size for the InfluxDB VM (e.g., 100G)"
  type        = string
  default     = "100G"
}

variable "storage" {
  description = "Proxmox storage ID for VM disks"
  type        = string
  default     = "VM_Disks"
}

# ---------------------------------------------------------------------
# Network Configuration
# ---------------------------------------------------------------------

variable "network_bridge" {
  description = "Proxmox network bridge (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN tag for network interface (Services VLAN 20)"
  type        = number
  default     = 20
}

variable "ip_address" {
  description = "IP address for the InfluxDB VM"
  type        = string
}

variable "gateway" {
  description = "Default gateway for the InfluxDB VM"
  type        = string
}

variable "cidr_subnet" {
  description = "CIDR subnet mask (e.g., /24)"
  type        = string
  default     = "/24"
}

variable "nameservers" {
  description = "Space-separated list of DNS nameservers"
  type        = string
  default     = "1.1.1.1 8.8.8.8"
}

# ---------------------------------------------------------------------
# Access Configuration
# ---------------------------------------------------------------------

variable "default_user" {
  description = "Default user for cloud-init provisioning"
  type        = string
  default     = "sinless777"
}

variable "default_password" {
  description = "Default password for cloud-init user (optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ansible_user" {
  description = "Ansible user for configuration management"
  type        = string
  default     = "sinless777"
}

variable "ssh_keys" {
  description = "List of SSH public keys for default user"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------
# HA and Backup Configuration
# ---------------------------------------------------------------------

variable "ha_enabled" {
  description = "Enable Proxmox HA for the InfluxDB VM"
  type        = bool
  default     = true
}

variable "ha_group" {
  description = "Proxmox HA group name"
  type        = string
  default     = "influxdb-ha"
}

variable "backup_enabled" {
  description = "Enable automatic backups for the InfluxDB VM"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "0 4 * * *"
}

# ---------------------------------------------------------------------
# VM Options
# ---------------------------------------------------------------------

variable "start_at_node_boot" {
  description = "Start VM automatically when Proxmox node boots"
  type        = bool
  default     = true
}

variable "agent_enabled" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "protection" {
  description = "Enable VM deletion protection"
  type        = bool
  default     = false
}

variable "startup_order" {
  description = "VM startup order (lower numbers start first)"
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------
# Tags and Metadata
# ---------------------------------------------------------------------

variable "tags" {
  description = "List of tags to apply to the InfluxDB VM"
  type        = list(string)
  default     = ["influxdb", "metrics", "monitoring"]
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "InfluxDB Time-Series Database VM"
}

# ---------------------------------------------------------------------
# InfluxDB Application Configuration
# ---------------------------------------------------------------------

variable "influxdb_version" {
  description = "InfluxDB version to deploy"
  type        = string
  default     = "2.7.10"
}

variable "influxdb_port" {
  description = "InfluxDB HTTP API port"
  type        = number
  default     = 8086
}
