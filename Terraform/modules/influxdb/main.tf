# =====================================================================
# InfluxDB Terraform Module - Main Resources
# =====================================================================

locals {
  common_tags = concat(
    var.tags,
    [
      "env-${var.environment}",
      "service-metrics"
    ]
  )
}

resource "proxmox_vm_qemu" "influxdb" {
  name        = var.node_name
  vmid        = var.vm_id
  target_node = var.target_node
  description = var.description

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  startup            = "order=${var.startup_order}"

  clone        = var.clone_template
  full_clone   = true
  force_create = var.force_create

  agent = var.agent_enabled ? 1 : 0

  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb

  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"

  os_type = "cloud-init"

  disk {
    slot     = "virtio0"
    type     = "disk"
    storage  = var.storage
    size     = var.disk_size
    format   = "raw"
    backup   = var.backup_enabled
    iothread = true
    discard  = true
  }

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

  ipconfig0 = "ip=${var.ip_address}${var.cidr_subnet},gw=${var.gateway}"

  nameserver = var.nameservers
  ciuser     = var.default_user
  cipassword = var.default_password

  sshkeys = try(join("\n", var.ssh_keys), null)

  tags = join(";", local.common_tags)

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      # Ignore cloud-init changes after initial provisioning
    ]
  }
}
