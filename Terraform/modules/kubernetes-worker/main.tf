terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

locals {
  common_tags = concat(
    var.tags,
    [
      "kubernetes",
      "rke2",
      "cluster-${var.cluster_name}",
      "env-${var.environment}",
      "role-${var.node_role}"
    ]
  )

}

resource "proxmox_vm_qemu" "worker" {
  count = length(var.nodes)

  name        = var.nodes[count.index].name
  vmid        = var.nodes[count.index].vmid
  target_node = var.nodes[count.index].target_node
  description = "${var.description} (${var.nodes[count.index].fqdn})"
  pool        = var.resource_pool != "" ? var.resource_pool : null

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  force_create       = var.force_create
  startup            = "order=${var.startup_order}"

  clone      = var.clone_template
  full_clone = true

  # QEMU Guest Agent
  agent = 1

  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb

  # Boot configuration - boot from scsi0 (main disk)
  boot     = "order=scsi0;net0"
  bootdisk = "scsi0"
  scsihw   = "virtio-scsi-single"
  hotplug  = "network,disk,usb"

  disk {
    slot     = "scsi0"
    type     = "disk"
    storage  = var.storage
    size     = var.disk_size
    format   = "raw"
    backup   = true
    iothread = true
    discard  = true
  }

  # Cloud-init drive configuration
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_id > 0 ? var.vlan_id : null
  }

  ipconfig0  = "ip=${var.nodes[count.index].ip_address}${var.cidr_subnet},gw=${var.gateway}"
  nameserver = var.nameservers
  cicustom   = "user=local:snippets/${var.nodes[count.index].name}-cloud-init.yaml"

  # Start VMs immediately after creation
  vm_state = "running"

  tags = join(";", local.common_tags)

  # VM lifecycle is now fully managed by Terraform
  lifecycle {
    ignore_changes = [
      # Prevent Terraform from reverting Ansible-managed changes
      description,
    ]
  }
}
# Cloud-init is handled via Proxmox cloud-init drive
# No additional configuration needed for Debian
