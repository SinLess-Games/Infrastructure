# =====================================================================
# MinIO Cluster Terraform Module Variables
# =====================================================================

# ---------------------------------------------------------------------
# General Configuration
# ---------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the MinIO cluster (used for naming resources)"
  type        = string
  default     = "minio-ha"
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
  description = "List of Proxmox node names for distributing MinIO VMs"
  type        = list(string)
  validation {
    condition     = length(var.target_nodes) >= 2
    error_message = "At least 2 target nodes must be provided for HA distribution"
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
  description = "Number of MinIO nodes to create"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 2
    error_message = "Node count must be at least 2"
  }
}

variable "node_name_prefix" {
  description = "Prefix for VM names (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "minio"
}

variable "vm_id_start" {
  description = "Starting VM ID for MinIO nodes (e.g., 220)"
  type        = number
  default     = 220
}

variable "force_create" {
  description = "Whether to force recreation of VMs if the VMID already exists"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------
# Resource Allocation
# ---------------------------------------------------------------------

variable "cpu_cores" {
  description = "Number of CPU cores per MinIO node"
  type        = number
  default     = 4
}

variable "cpu_sockets" {
  description = "Number of CPU sockets per MinIO node"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory allocation per MinIO node (MB)"
  type        = number
  default     = 8192
}

variable "memory_balloon_mb" {
  description = "Minimum balloon memory per MinIO node (MB). Set to memory_mb for fixed allocation."
  type        = number
  default     = 4096
  validation {
    condition     = var.memory_balloon_mb > 0
    error_message = "memory_balloon_mb must be greater than 0"
  }
}

variable "disk_size" {
  description = "Disk size for each MinIO node (e.g., 1T)"
  type        = string
  default     = "1T"
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
  description = "VLAN tag for network interface (0 for no VLAN)"
  type        = number
  default     = 40
}

variable "ip_addresses" {
  description = "List of IP addresses for MinIO nodes"
  type        = list(string)
  validation {
    condition     = length(var.ip_addresses) >= 2
    error_message = "At least 2 IP addresses must be provided"
  }
}

variable "gateway" {
  description = "Default gateway for MinIO nodes"
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
  description = "Enable Proxmox HA for MinIO nodes"
  type        = bool
  default     = true
}

variable "ha_group" {
  description = "Proxmox HA group name"
  type        = string
  default     = "minio-ha"
}

variable "backup_enabled" {
  description = "Enable automatic backups for MinIO nodes"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "0 3 * * *"
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
  default     = 3
}

# ---------------------------------------------------------------------
# Tags and Metadata
# ---------------------------------------------------------------------

variable "tags" {
  description = "List of tags to apply to all MinIO VMs"
  type        = list(string)
  default     = ["minio", "s3", "storage"]
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "MinIO S3-compatible Object Storage Node"
}
