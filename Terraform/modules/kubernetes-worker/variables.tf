variable "cluster_name" {
  description = "Logical cluster name"
  type        = string
}

variable "environment" {
  description = "Environment key (dev/testing/prod)"
  type        = string
}

variable "node_role" {
  description = "Node role label"
  type        = string
  default     = "worker"
}

variable "nodes" {
  description = "Worker VM definitions"
  type = list(object({
    name          = string
    vmid          = number
    target_node   = string
    ip_address    = string
    hostname      = string
    fqdn          = string
    ignition_json = string
  }))
}

variable "clone_template" {
  description = "Proxmox Flatcar template name"
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

variable "storage" {
  description = "Primary storage target"
  type        = string
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
  default     = 50
}

variable "force_create" {
  description = "Recycle VMID if already in use"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "VM description prefix"
  type        = string
  default     = "RKE2 worker node"
}

variable "enable_ignition_fw_cfg" {
  description = "Whether to inject Ignition via QEMU fw_cfg args"
  type        = bool
  default     = true
}

variable "ignition_server_url" {
  description = "HTTP server URL for Ignition configs (e.g., http://10.10.10.10:8080/ignition)"
  type        = string
  default     = ""
}

variable "proxmox_node_ssh_hosts" {
  description = "Map of Proxmox node name to SSH host/IP reachable from Terraform runner"
  type        = map(string)
  default     = {}
}
