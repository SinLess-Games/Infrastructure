output "vm_ids" {
  description = "Control-plane VM IDs"
  value       = proxmox_vm_qemu.control_plane[*].vmid
}

output "vm_names" {
  description = "Control-plane VM names"
  value       = proxmox_vm_qemu.control_plane[*].name
}

output "ansible_hosts" {
  description = "Control-plane host map for inventory generation"
  value = {
    for idx, vm in proxmox_vm_qemu.control_plane : vm.name => {
      ansible_host = var.nodes[idx].ip_address
      role         = "control-plane"
      environment  = var.environment
      hostname     = var.nodes[idx].hostname
      fqdn         = var.nodes[idx].fqdn
    }
  }
}
