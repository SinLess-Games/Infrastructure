# =====================================================================
# Kubernetes Cluster Terraform Module - Main Resources
# =====================================================================

# ---------------------------------------------------------------------
# Control Plane Nodes
# ---------------------------------------------------------------------

resource "proxmox_vm_qemu" "control_plane" {
  count = var.control_plane_count

  name        = "${var.control_plane_name_prefix}-${format("%02d", count.index + 1)}"
  vmid        = var.control_plane_vm_id_start + count.index
  target_node = var.target_nodes[count.index % length(var.target_nodes)]
  description = "${var.description} - control plane (Node ${count.index + 1}/${var.control_plane_count}) on ${var.target_nodes[count.index % length(var.target_nodes)]}"

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  startup            = "order=${var.control_plane_startup_order}"

  clone      = var.clone_template
  full_clone = true

  agent = var.agent_enabled ? 1 : 0

  cores   = var.control_plane_cpu_cores
  sockets = var.control_plane_cpu_sockets
  memory  = var.control_plane_memory_mb

  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"

  os_type = "cloud-init"

  disk {
    slot     = "virtio0"
    type     = "disk"
    storage  = var.storage
    size     = var.control_plane_disk_size
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

  ipconfig0 = "ip=${var.control_plane_ip_addresses[count.index]}${var.cidr_subnet},gw=${var.gateway}"

  nameserver = var.nameservers
  ciuser     = var.default_user
  cipassword = var.default_password

  sshkeys = try(join("\n", var.ssh_keys), null)

  tags = join(";", concat(var.tags, ["env-${var.environment}", "role-controlplane", "cluster-${var.cluster_name}"]))

  lifecycle {
    create_before_destroy = false
  }
}

# ---------------------------------------------------------------------
# Worker Nodes
# ---------------------------------------------------------------------

resource "proxmox_vm_qemu" "worker" {
  count = var.worker_count

  name        = "${var.worker_name_prefix}-${format("%02d", count.index + 1)}"
  vmid        = var.worker_vm_id_start + count.index
  target_node = var.target_nodes[count.index % length(var.target_nodes)]
  description = "${var.description} - worker (Node ${count.index + 1}/${var.worker_count}) on ${var.target_nodes[count.index % length(var.target_nodes)]}"

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  startup            = "order=${var.worker_startup_order}"

  clone      = var.clone_template
  full_clone = true

  agent = var.agent_enabled ? 1 : 0

  cores   = var.worker_cpu_cores
  sockets = var.worker_cpu_sockets
  memory  = var.worker_memory_mb

  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"

  os_type = "cloud-init"

  disk {
    slot     = "virtio0"
    type     = "disk"
    storage  = var.storage
    size     = var.worker_disk_size
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

  ipconfig0 = "ip=${var.worker_ip_addresses[count.index]}${var.cidr_subnet},gw=${var.gateway}"

  nameserver = var.nameservers
  ciuser     = var.default_user
  cipassword = var.default_password

  sshkeys = try(join("\n", var.ssh_keys), null)

  tags = join(";", concat(var.tags, ["env-${var.environment}", "role-worker", "cluster-${var.cluster_name}"]))

  lifecycle {
    create_before_destroy = false
  }
}
