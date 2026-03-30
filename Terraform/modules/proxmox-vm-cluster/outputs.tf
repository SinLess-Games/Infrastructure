output "vm_ids" {
  description = "List of Proxmox VM IDs"
  value       = proxmox_vm_qemu.cluster_node[*].vmid
}

output "vm_names" {
  description = "List of VM names"
  value       = proxmox_vm_qemu.cluster_node[*].name
}

output "vm_ip_addresses" {
  description = "List of IP addresses"
  value       = [for node in var.nodes : node.ip_address]
}

output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "nodes" {
  description = "Detailed node information"
  value = [
    for idx, vm in proxmox_vm_qemu.cluster_node : {
      name        = vm.name
      vmid        = vm.vmid
      target_node = var.nodes[idx].target_node
      ip_address  = var.nodes[idx].ip_address
      hostname    = try(var.nodes[idx].hostname, vm.name)
      fqdn        = try(var.nodes[idx].fqdn, null)
      node_index  = idx + 1
      node_role   = var.node_role
    }
  ]
}

output "ansible_hosts" {
  description = "Generic Ansible host configuration map"
  value = {
    for idx, vm in proxmox_vm_qemu.cluster_node : vm.name => {
      ansible_host = var.nodes[idx].ip_address
      node_name    = vm.name
      node_index   = idx + 1
      node_role    = var.node_role
    }
  }
}
