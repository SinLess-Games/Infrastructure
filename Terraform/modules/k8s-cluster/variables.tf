# =====================================================================
# Kubernetes Cluster Terraform Module Variables
# =====================================================================

# ---------------------------------------------------------------------
# General Configuration
# ---------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the Kubernetes cluster (used for naming resources)"
  type        = string
  default     = "k8s-cluster"
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
  description = "List of Proxmox node names for distributing Kubernetes VMs"
  type        = list(string)
  validation {
    condition     = length(var.target_nodes) >= 1
    error_message = "At least 1 target node must be provided"
  }
}

variable "clone_template" {
  description = "Name of the VM template to clone (e.g., debian-13-template)"
  type        = string
}

# ---------------------------------------------------------------------
# Control Plane Configuration
# ---------------------------------------------------------------------

variable "control_plane_count" {
  description = "Number of control plane nodes to create"
  type        = number
  default     = 1
  validation {
    condition     = var.control_plane_count >= 1
    error_message = "control_plane_count must be at least 1"
  }
}

variable "control_plane_name_prefix" {
  description = "Prefix for control plane VM names (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "k8s-cp"
}

variable "control_plane_vm_id_start" {
  description = "Starting VM ID for control plane nodes (e.g., 300)"
  type        = number
  default     = 300
}

variable "control_plane_ip_addresses" {
  description = "List of IP addresses for control plane nodes"
  type        = list(string)
  validation {
    condition     = length(var.control_plane_ip_addresses) >= 1
    error_message = "At least 1 control plane IP address must be provided"
  }
}

variable "control_plane_cpu_cores" {
  description = "Number of CPU cores per control plane node"
  type        = number
  default     = 4
}

variable "control_plane_cpu_sockets" {
  description = "Number of CPU sockets per control plane node"
  type        = number
  default     = 1
}

variable "control_plane_memory_mb" {
  description = "Memory allocation per control plane node (MB)"
  type        = number
  default     = 8192
}

variable "control_plane_disk_size" {
  description = "Disk size for each control plane node (e.g., 80G)"
  type        = string
  default     = "80G"
}

# ---------------------------------------------------------------------
# Worker Node Configuration
# ---------------------------------------------------------------------

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 2
  validation {
    condition     = var.worker_count >= 1
    error_message = "worker_count must be at least 1"
  }
}

variable "worker_name_prefix" {
  description = "Prefix for worker VM names (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "k8s-worker"
}

variable "worker_vm_id_start" {
  description = "Starting VM ID for worker nodes (e.g., 350; offset from control_plane_vm_id_start)"
  type        = number
  default     = 350
}

variable "worker_ip_addresses" {
  description = "List of IP addresses for worker nodes"
  type        = list(string)
  validation {
    condition     = length(var.worker_ip_addresses) >= 1
    error_message = "At least 1 worker IP address must be provided"
  }
}

variable "worker_cpu_cores" {
  description = "Number of CPU cores per worker node"
  type        = number
  default     = 8
}

variable "worker_cpu_sockets" {
  description = "Number of CPU sockets per worker node"
  type        = number
  default     = 1
}

variable "worker_memory_mb" {
  description = "Memory allocation per worker node (MB)"
  type        = number
  default     = 16384
}

variable "worker_disk_size" {
  description = "Disk size for each worker node (e.g., 120G)"
  type        = string
  default     = "120G"
}

# ---------------------------------------------------------------------
# Shared Storage & Network Configuration
# ---------------------------------------------------------------------

variable "storage" {
  description = "Proxmox storage ID for VM disks"
  type        = string
  default     = "VM_Disks"
}

variable "vlan_id" {
  description = "VLAN tag for network interface (0 for no VLAN); default is VLAN 30 (Kubernetes)"
  type        = number
  default     = 30
}

variable "network_bridge" {
  description = "Proxmox network bridge (e.g., vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Default gateway for Kubernetes nodes"
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
  default     = "10.10.10.1 1.1.1.1"
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
  description = "Enable Proxmox HA for Kubernetes nodes"
  type        = bool
  default     = true
}

variable "ha_group" {
  description = "Proxmox HA group name"
  type        = string
  default     = "k8s-ha"
}

variable "backup_enabled" {
  description = "Enable automatic backups for Kubernetes nodes"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "0 1 * * *"
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

variable "control_plane_startup_order" {
  description = "Startup order for control plane nodes (lower numbers start first)"
  type        = number
  default     = 40
}

variable "worker_startup_order" {
  description = "Startup order for worker nodes (starts after control plane)"
  type        = number
  default     = 50
}

# ---------------------------------------------------------------------
# Tags and Metadata
# ---------------------------------------------------------------------

variable "tags" {
  description = "List of base tags to apply to all Kubernetes VMs"
  type        = list(string)
  default     = ["kubernetes", "rke2"]
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "RKE2 Kubernetes cluster node"
}
