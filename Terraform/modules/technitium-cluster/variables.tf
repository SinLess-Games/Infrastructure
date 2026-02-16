# =====================================================================
# Technitium Cluster Terraform Module Variables
# =====================================================================

# ---------------------------------------------------------------------
# General Configuration
# ---------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the Technitium cluster (used for naming resources)"
  type        = string
  default     = "technitium-cluster"
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

variable "target_nodes" {
  description = "List of Proxmox node names for distributing Technitium VMs"
  type        = list(string)
  validation {
    condition     = length(var.target_nodes) >= 3
    error_message = "At least 3 target nodes must be provided for HA distribution"
  }
}

variable "clone_template" {
  description = "Name of the VM template to clone (e.g., debian-13-template)"
  type        = string
}

# ---------------------------------------------------------------------
# VM Node Configuration
# ---------------------------------------------------------------------

variable "node_count" {
  description = "Number of Technitium nodes to create"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 3
    error_message = "Node count must be at least 3"
  }
}

variable "node_name_prefix" {
  description = "Prefix for VM names (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "dns"
}

variable "vm_id_start" {
  description = "Starting VM ID for Technitium nodes (e.g., 203)"
  type        = number
  default     = 203
}

# ---------------------------------------------------------------------
# Resource Allocation
# ---------------------------------------------------------------------

variable "cpu_cores" {
  description = "Number of CPU cores per Technitium node"
  type        = number
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets per Technitium node"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory allocation per Technitium node (MB)"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size for each Technitium node (e.g., 40G)"
  type        = string
  default     = "40G"
}

variable "storage" {
  description = "Proxmox storage ID for VM disks"
  type        = string
  default     = "vm-fast"
}

# ---------------------------------------------------------------------
# Network Configuration
# ---------------------------------------------------------------------

variable "vlan_id" {
  description = "VLAN ID for Technitium cluster"
  type        = number
  default     = 0
}

variable "network_bridge" {
  description = "Network bridge for VM network interfaces"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Network gateway for Technitium nodes"
  type        = string
}

variable "nameservers" {
  description = "DNS nameservers (space-separated)"
  type        = string
  default     = "1.1.1.1 1.0.0.1"
}

variable "ip_addresses" {
  description = "List of IP addresses for Technitium nodes (must match node_count)"
  type        = list(string)
  validation {
    condition     = length(var.ip_addresses) >= 3
    error_message = "At least 3 IP addresses must be provided for Technitium HA"
  }
}

variable "cidr_subnet" {
  description = "CIDR subnet mask (e.g., /24)"
  type        = string
  default     = "/24"
}

# ---------------------------------------------------------------------
# Cloud-Init / Bootstrap Configuration
# ---------------------------------------------------------------------

variable "ssh_keys" {
  description = "List of SSH public keys for VM access"
  type        = list(string)
  default     = []
}

variable "default_user" {
  description = "Default user for cloud-init"
  type        = string
  default     = "sinless777"
}

variable "default_password" {
  description = "Default password for cloud-init user"
  type        = string
  default     = "Shellshocker93!"
}

variable "ansible_user" {
  description = "User for Ansible automation"
  type        = string
  default     = "ansible"
}

# ---------------------------------------------------------------------
# Backup and HA Configuration
# ---------------------------------------------------------------------

variable "backup_enabled" {
  description = "Enable Proxmox backup for Technitium VMs"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule (cron format)"
  type        = string
  default     = "0 3 * * *"
}

variable "ha_enabled" {
  description = "Enable Proxmox HA for Technitium VMs"
  type        = bool
  default     = true
}

variable "ha_group" {
  description = "Proxmox HA resource group for Technitium VMs"
  type        = string
  default     = "dns-ha"
}

# ---------------------------------------------------------------------
# Tags and Metadata
# ---------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to Technitium VMs"
  type        = list(string)
  default     = ["technitium", "dns", "ha"]
}

variable "description" {
  description = "Description for Technitium VMs"
  type        = string
  default     = "Technitium DNS cluster node"
}

# ---------------------------------------------------------------------
# Advanced Options
# ---------------------------------------------------------------------

variable "start_at_node_boot" {
  description = "Start VM on boot"
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
  default     = true
}

variable "startup_order" {
  description = "VM startup order (lower numbers start first)"
  type        = number
  default     = 20
}
