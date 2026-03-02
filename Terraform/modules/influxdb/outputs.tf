# =====================================================================
# InfluxDB Terraform Module - Outputs
# =====================================================================

output "vm_id" {
  description = "Proxmox VM ID for the InfluxDB VM"
  value       = proxmox_vm_qemu.influxdb.vmid
}

output "vm_name" {
  description = "VM name for the InfluxDB VM"
  value       = proxmox_vm_qemu.influxdb.name
}

output "vm_ip_address" {
  description = "IP address of the InfluxDB VM"
  value       = var.ip_address
}

output "cluster_name" {
  description = "InfluxDB deployment name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name (dev, staging, prod)"
  value       = var.environment
}

output "target_node" {
  description = "Proxmox node where the VM is deployed"
  value       = var.target_node
}

output "ansible_host" {
  description = "Ansible host configuration for the InfluxDB VM"
  value = {
    ansible_host  = var.ip_address
    influxdb_port = var.influxdb_port
  }
}
