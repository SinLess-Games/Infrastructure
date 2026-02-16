# =====================================================================
# Postgres Cluster Terraform Module - Outputs
# =====================================================================

output "vm_ids" {
  description = "List of Proxmox VM IDs for Postgres cluster nodes"
  value       = proxmox_vm_qemu.postgres_node[*].vmid
}

output "vm_names" {
  description = "List of VM names for Postgres cluster nodes"
  value       = proxmox_vm_qemu.postgres_node[*].name
}

output "vm_ip_addresses" {
  description = "List of IP addresses for Postgres cluster nodes"
  value       = var.ip_addresses
}

output "cluster_name" {
  description = "Postgres cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name (dev, staging, prod)"
  value       = var.environment
}

output "target_nodes" {
  description = "List of Proxmox nodes where VMs are deployed"
  value       = var.target_nodes
}

output "ansible_group" {
  description = "Ansible inventory group name for this Postgres cluster"
  value       = "postgres"
}

output "ansible_hosts" {
  description = "Map of Ansible host configurations"
  value = {
    for idx in range(var.node_count) : proxmox_vm_qemu.postgres_node[idx].name => {
      ansible_host     = var.ip_addresses[idx]
      postgres_node    = proxmox_vm_qemu.postgres_node[idx].name
      postgres_index   = idx + 1
    }
  }
}
