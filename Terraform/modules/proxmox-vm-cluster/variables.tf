variable "cluster_name" {
  description = "Logical cluster name"
  type        = string
}

variable "environment" {
  description = "Environment key"
  type        = string
}

variable "service_name" {
  description = "Service or workload name for tagging"
  type        = string
  default     = ""
}

variable "node_role" {
  description = "Node role label"
  type        = string
  default     = ""
}

variable "nodes" {
  description = "VM definitions"
  type = list(object({
    name        = string
    vmid        = number
    target_node = string
    ip_address  = string
    hostname    = optional(string)
    fqdn        = optional(string)
  }))
}

variable "clone_template" {
  description = "Proxmox template name"
  type        = string
}

variable "network_bridge" {
  description = "Proxmox bridge"
  type        = string
}

variable "vlan_id" {
  description = "VLAN tag"
  type        = number
  default     = 0
}

variable "gateway" {
  description = "Gateway IP"
  type        = string
}

variable "cidr_subnet" {
  description = "CIDR suffix"
  type        = string
  default     = "/24"
}

variable "nameservers" {
  description = "Nameservers string"
  type        = string
  default     = "1.1.1.1 1.0.0.1"
}

variable "search_domain" {
  description = "DNS search domain suffix for cloud-init guest configuration"
  type        = string
  default     = ""
}

variable "storage" {
  description = "Primary storage target"
  type        = string
}

variable "resource_pool" {
  description = "Proxmox resource pool"
  type        = string
  default     = ""
}

variable "disk_size" {
  description = "Boot disk size"
  type        = string
  default     = "64G"
}

variable "cpu_cores" {
  description = "vCPU cores"
  type        = number
  default     = 4
}

variable "cpu_sockets" {
  description = "CPU sockets"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "RAM in MB"
  type        = number
  default     = 8192
}

variable "memory_balloon_mb" {
  description = "Optional balloon memory minimum in MB"
  type        = number
  default     = null
  nullable    = true
}

variable "start_at_node_boot" {
  description = "Start VM at node boot"
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
  description = "Proxmox startup order"
  type        = number
  default     = 40
}

variable "force_create" {
  description = "Recycle VMID if already in use"
  type        = bool
  default     = false
}

variable "backup_enabled" {
  description = "Enable disk backup"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "VM description prefix"
  type        = string
  default     = "Terraform-managed Proxmox VM"
}

variable "ssh_keys" {
  description = "SSH public keys for VM authentication"
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
  default     = null
  nullable    = true
  sensitive   = true
}

variable "ciupgrade" {
  description = "Enable package upgrade during cloud-init"
  type        = bool
  default     = true
}

variable "cicustom_user_snippet_enabled" {
  description = "Whether to attach a per-node cloud-init user snippet from snippets storage"
  type        = bool
  default     = false
}

variable "cicustom_snippet_storage" {
  description = "Snippet storage reference prefix"
  type        = string
  default     = "local:snippets"
}

variable "vm_state" {
  description = "Desired initial VM state"
  type        = string
  default     = "started"
}
