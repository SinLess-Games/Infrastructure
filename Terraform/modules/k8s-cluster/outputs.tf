# =====================================================================
# Kubernetes Cluster Terraform Module - Outputs
# =====================================================================

output "control_plane_vm_ids" {
  description = "List of Proxmox VM IDs for control plane nodes"
  value       = proxmox_vm_qemu.control_plane[*].vmid
}

output "control_plane_vm_names" {
  description = "List of VM names for control plane nodes"
  value       = proxmox_vm_qemu.control_plane[*].name
}

output "control_plane_ip_addresses" {
  description = "List of IP addresses for control plane nodes"
  value       = var.control_plane_ip_addresses
}

output "worker_vm_ids" {
  description = "List of Proxmox VM IDs for worker nodes"
  value       = proxmox_vm_qemu.worker[*].vmid
}

output "worker_vm_names" {
  description = "List of VM names for worker nodes"
  value       = proxmox_vm_qemu.worker[*].name
}

output "worker_ip_addresses" {
  description = "List of IP addresses for worker nodes"
  value       = var.worker_ip_addresses
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name (dev, staging, prod)"
  value       = var.environment
}

output "all_node_ips" {
  description = "Combined list of all node IP addresses (control plane + workers)"
  value       = concat(var.control_plane_ip_addresses, var.worker_ip_addresses)
}
