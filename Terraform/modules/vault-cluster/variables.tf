# =====================================================================
# Vault Cluster Terraform Module Variables
# =====================================================================

# ---------------------------------------------------------------------
# General Configuration
# ---------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the Vault cluster (used for naming resources)"
  type        = string
  default     = "vault-cluster"
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
  description = "List of Proxmox node names for distributing Vault VMs (e.g., ['pve-01', 'pve-04', 'pve-05'])"
  type        = list(string)
  validation {
    condition     = length(var.target_nodes) >= 3
    error_message = "At least 3 target nodes must be provided for HA distribution"
  }
}

variable "clone_template" {
  description = "Name of the VM template to clone (e.g., debian-12-template)"
  type        = string
}

# ---------------------------------------------------------------------
# VM Node Configuration
# ---------------------------------------------------------------------

variable "node_count" {
  description = "Number of Vault nodes to create (must be odd for Raft quorum)"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count % 2 == 1 && var.node_count >= 3
    error_message = "Node count must be an odd number (3, 5, 7, etc.) for Raft quorum"
  }
}

variable "node_name_prefix" {
  description = "Prefix for VM names (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "vault"
}

variable "vm_id_start" {
  description = "Starting VM ID for Vault nodes (e.g., 200)"
  type        = number
  default     = 200
}

# ---------------------------------------------------------------------
# Resource Allocation
# ---------------------------------------------------------------------

variable "cpu_cores" {
  description = "Number of CPU cores per Vault node"
  type        = number
  default     = 4
}

variable "cpu_sockets" {
  description = "Number of CPU sockets per Vault node"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory allocation per Vault node (MB)"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "Disk size for each Vault node (e.g., 40G)"
  type        = string
  default     = "100G"
}

variable "storage" {
  description = "Proxmox storage ID for VM disks (Ceph pool or local storage)"
  type        = string
  default     = "vm-fast"
}

# ---------------------------------------------------------------------
# Network Configuration
# ---------------------------------------------------------------------

variable "vlan_id" {
  description = "VLAN ID for Vault cluster (Services VLAN typically)"
  type        = number
  default     = 20
}

variable "network_bridge" {
  description = "Network bridge for VM network interfaces"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Network gateway for Vault nodes"
  type        = string
}

variable "nameservers" {
  description = "DNS nameservers (space-separated)"
  type        = string
  default     = "1.1.1.1 1.0.0.1"
}

variable "ip_addresses" {
  description = "List of IP addresses for Vault nodes (must match node_count)"
  type        = list(string)
  validation {
    condition     = length(var.ip_addresses) >= 3
    error_message = "At least 3 IP addresses must be provided for Vault HA"
  }
}

variable "cidr_subnet" {
  description = "CIDR subnet mask (e.g., /24)"
  type        = string
  default     = "/24"
}

# ---------------------------------------------------------------------
# Vault Configuration
# ---------------------------------------------------------------------

variable "vault_version" {
  description = "HashiCorp Vault version to install"
  type        = string
  default     = "1.15.4"
}

variable "vault_port" {
  description = "Vault API port"
  type        = number
  default     = 8200
}

variable "vault_cluster_port" {
  description = "Vault cluster communication port"
  type        = number
  default     = 8201
}

variable "vault_storage_path" {
  description = "Path for Vault Raft storage on each node"
  type        = string
  default     = "/opt/vault/data"
}

variable "vault_log_path" {
  description = "Path for Vault logs and audit logs"
  type        = string
  default     = "/opt/vault/logs"
}

# ---------------------------------------------------------------------
# TLS Configuration
# ---------------------------------------------------------------------

variable "vault_tls_enabled" {
  description = "Enable TLS for Vault listener"
  type        = bool
  default     = true
}

variable "vault_tls_cert_path" {
  description = "Path to TLS certificate file on VM"
  type        = string
  default     = "/opt/vault/tls/vault.crt"
}

variable "vault_tls_key_path" {
  description = "Path to TLS key file on VM"
  type        = string
  default     = "/opt/vault/tls/vault.key"
}

variable "vault_tls_ca_path" {
  description = "Path to CA certificate file on VM"
  type        = string
  default     = "/opt/vault/tls/ca.crt"
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
  description = "Enable Proxmox backup for Vault VMs"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule (cron format)"
  type        = string
  default     = "0 2 * * *" # Daily at 2 AM
}

variable "ha_enabled" {
  description = "Enable Proxmox HA for Vault VMs"
  type        = bool
  default     = true
}

variable "ha_group" {
  description = "Proxmox HA resource group for Vault VMs"
  type        = string
  default     = "vault-ha"
}

# ---------------------------------------------------------------------
# Tags and Metadata
# ---------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to Vault VMs"
  type        = list(string)
  default     = ["vault", "tier-0", "ha"]
}

variable "description" {
  description = "Description for Vault VMs"
  type        = string
  default     = "HashiCorp Vault cluster node with Raft integrated storage"
}

# ---------------------------------------------------------------------
# Advanced Options
# ---------------------------------------------------------------------

variable "onboot" {
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
  default     = 10
}
