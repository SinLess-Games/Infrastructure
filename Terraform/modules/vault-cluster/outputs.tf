# =====================================================================
# Vault Cluster Terraform Module - Outputs
# =====================================================================

# ---------------------------------------------------------------------
# VM Resource Outputs
# ---------------------------------------------------------------------

output "vm_ids" {
  description = "List of Proxmox VM IDs for Vault cluster nodes"
  value       = proxmox_vm_qemu.vault_node[*].vmid
}

output "vm_names" {
  description = "List of VM names for Vault cluster nodes"
  value       = proxmox_vm_qemu.vault_node[*].name
}

output "vm_ip_addresses" {
  description = "List of IP addresses for Vault cluster nodes"
  value       = var.ip_addresses
}

# ---------------------------------------------------------------------
# Vault Cluster Configuration Outputs
# ---------------------------------------------------------------------

output "cluster_name" {
  description = "Vault cluster name"
  value       = var.cluster_name
}

output "cluster_members" {
  description = "Detailed information about all Vault cluster members"
  value = [
    for idx in range(var.node_count) : {
      name         = proxmox_vm_qemu.vault_node[idx].name
      vmid         = proxmox_vm_qemu.vault_node[idx].vmid
      ip_address   = var.ip_addresses[idx]
      api_addr     = "https://${var.ip_addresses[idx]}:${var.vault_port}"
      cluster_addr = "https://${var.ip_addresses[idx]}:${var.vault_cluster_port}"
      is_leader    = idx == 0
    }
  ]
}

output "vault_api_endpoints" {
  description = "List of Vault API endpoints (HTTPS URLs)"
  value = [
    for ip in var.ip_addresses : "https://${ip}:${var.vault_port}"
  ]
}

output "vault_cluster_endpoints" {
  description = "List of Vault cluster communication endpoints"
  value = [
    for ip in var.ip_addresses : "https://${ip}:${var.vault_cluster_port}"
  ]
}

output "vault_leader_endpoint" {
  description = "Vault leader node API endpoint (first node)"
  value       = "https://${var.ip_addresses[0]}:${var.vault_port}"
}

# ---------------------------------------------------------------------
# Raft Configuration Outputs
# ---------------------------------------------------------------------

output "vault_raft_retry_join" {
  description = "Raft retry_join configuration for Vault HCL config"
  value       = local.vault_raft_retry_join
  sensitive   = false
}

output "vault_raft_config_hcl" {
  description = "Generated Raft retry_join configuration in HCL format"
  value = join("\n", [
    for member in local.vault_raft_retry_join :
    "  retry_join {\n    leader_api_addr = \"${member.leader_api_addr}\"\n  }"
  ])
}

# ---------------------------------------------------------------------
# Network Configuration Outputs
# ---------------------------------------------------------------------

output "network_vlan" {
  description = "VLAN ID used for Vault cluster"
  value       = var.vlan_id
}

output "network_gateway" {
  description = "Network gateway for Vault cluster"
  value       = var.gateway
}

output "network_bridge" {
  description = "Proxmox network bridge used for Vault cluster"
  value       = var.network_bridge
}

# ---------------------------------------------------------------------
# Environment and Metadata Outputs
# ---------------------------------------------------------------------

output "environment" {
  description = "Environment name (dev, staging, prod)"
  value       = var.environment
}

output "target_nodes" {
  description = "List of Proxmox nodes where VMs are deployed"
  value       = var.target_nodes
}

output "vm_placement" {
  description = "Map of VM names to their Proxmox host nodes"
  value = {
    for idx in range(var.node_count) : proxmox_vm_qemu.vault_node[idx].name => var.target_nodes[idx % length(var.target_nodes)]
  }
}

output "storage" {
  description = "Proxmox storage pool used for VM disks"
  value       = var.storage
}

# ---------------------------------------------------------------------
# Ansible Integration Outputs
# ---------------------------------------------------------------------

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory file"
  value       = "${path.root}/inventory/vault-${var.environment}.yaml"
}

output "ansible_group" {
  description = "Ansible inventory group name for this Vault cluster"
  value       = "vault_${var.environment}"
}

output "ansible_hosts" {
  description = "Map of Ansible host configurations"
  value = {
    for idx in range(var.node_count) : proxmox_vm_qemu.vault_node[idx].name => {
      ansible_host         = var.ip_addresses[idx]
      vault_node_id        = proxmox_vm_qemu.vault_node[idx].name
      vault_node_index     = idx + 1
      vault_api_addr       = "https://${var.ip_addresses[idx]}:${var.vault_port}"
      vault_cluster_addr   = "https://${var.ip_addresses[idx]}:${var.vault_cluster_port}"
      vault_raft_leader    = idx == 0
    }
  }
}

# ---------------------------------------------------------------------
# Connection Information for External Systems
# ---------------------------------------------------------------------

output "vault_addr" {
  description = "VAULT_ADDR environment variable (points to leader)"
  value       = "https://${var.ip_addresses[0]}:${var.vault_port}"
}

output "vault_connection_string" {
  description = "Connection string for Vault CLI and SDKs"
  value       = "export VAULT_ADDR=https://${var.ip_addresses[0]}:${var.vault_port}"
}

output "vault_load_balancer_backends" {
  description = "Backend server list for load balancer configuration"
  value = [
    for ip in var.ip_addresses : {
      address = ip
      port    = var.vault_port
    }
  ]
}

# ---------------------------------------------------------------------
# Monitoring and Observability Outputs
# ---------------------------------------------------------------------

output "prometheus_targets" {
  description = "List of Prometheus scrape targets for Vault metrics"
  value = [
    for ip in var.ip_addresses : "${ip}:${var.vault_port}/v1/sys/metrics?format=prometheus"
  ]
}

output "monitoring_endpoints" {
  description = "Monitoring and health check endpoints"
  value = {
    health = [
      for ip in var.ip_addresses : "https://${ip}:${var.vault_port}/v1/sys/health"
    ]
    metrics = [
      for ip in var.ip_addresses : "https://${ip}:${var.vault_port}/v1/sys/metrics"
    ]
    leader = "https://${var.ip_addresses[0]}:${var.vault_port}/v1/sys/leader"
  }
}

# ---------------------------------------------------------------------
# Backup and HA Configuration Outputs
# ---------------------------------------------------------------------

output "backup_enabled" {
  description = "Whether Proxmox backup is enabled for Vault VMs"
  value       = var.backup_enabled
}

output "ha_enabled" {
  description = "Whether Proxmox HA is enabled for Vault VMs"
  value       = var.ha_enabled
}

output "ha_group" {
  description = "Proxmox HA resource group for Vault VMs"
  value       = var.ha_enabled ? var.ha_group : null
}

# ---------------------------------------------------------------------
# Deployment Summary
# ---------------------------------------------------------------------

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = {
    cluster_name  = var.cluster_name
    environment   = var.environment
    node_count    = var.node_count
    vault_version = var.vault_version
    storage_type  = "Raft Integrated Storage"
    tls_enabled   = var.vault_tls_enabled
    ha_enabled    = var.ha_enabled
    backup_enabled = var.backup_enabled
    nodes = [
      for idx in range(var.node_count) : {
        name = proxmox_vm_qemu.vault_node[idx].name
        ip   = var.ip_addresses[idx]
        role = idx == 0 ? "leader" : "follower"
      }
    ]
  }
}
