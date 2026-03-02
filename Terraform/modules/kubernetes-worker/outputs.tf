output "vm_ids" {
  description = "Worker VM IDs"
  value       = proxmox_vm_qemu.worker[*].vmid
}

output "vm_names" {
  description = "Worker VM names"
  value       = proxmox_vm_qemu.worker[*].name
}

output "ansible_hosts" {
  description = "Worker host map for inventory generation"
  value = {
    for idx, vm in proxmox_vm_qemu.worker : vm.name => {
      ansible_host = var.nodes[idx].ip_address
      role         = "worker"
      environment  = var.environment
      hostname     = var.nodes[idx].hostname
      fqdn         = var.nodes[idx].fqdn
    }
  }
}
