# =====================================================================
# MinIO Cluster Terraform Module - Outputs
# =====================================================================

output "vm_ids" {
  description = "List of Proxmox VM IDs for MinIO cluster nodes"
  value       = proxmox_vm_qemu.minio_node[*].vmid
}

output "vm_names" {
  description = "List of VM names for MinIO cluster nodes"
  value       = proxmox_vm_qemu.minio_node[*].name
}

output "vm_ip_addresses" {
  description = "List of IP addresses for MinIO cluster nodes"
  value       = var.ip_addresses
}

output "cluster_name" {
  description = "MinIO cluster name"
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
  description = "Ansible inventory group name for this MinIO cluster"
  value       = "minio"
}

output "ansible_hosts" {
  description = "Map of Ansible host configurations"
  value = {
    for idx in range(var.node_count) : proxmox_vm_qemu.minio_node[idx].name => {
      ansible_host   = var.ip_addresses[idx]
      minio_node     = proxmox_vm_qemu.minio_node[idx].name
      minio_index    = idx + 1
    }
  }
}
