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

  ignition_json_escaped = [
    for node in var.nodes : replace(replace(replace(replace(node.ignition_json, "\\", "\\\\"), "\"", "\\\""), ",", "\\,"), "\n", "")
  ]
}

resource "proxmox_vm_qemu" "control_plane" {
  count = length(var.nodes)

  name        = var.nodes[count.index].name
  vmid        = var.nodes[count.index].vmid
  target_node = var.nodes[count.index].target_node
  description = "${var.description} (${var.nodes[count.index].fqdn})"

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  force_create       = var.force_create
  startup            = "order=${var.startup_order}"

  clone      = var.clone_template
  full_clone = true

  agent = var.agent_enabled ? 1 : 0

  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb

  boot    = "order=scsi0;net0"
  scsihw  = "virtio-scsi-single"
  hotplug = "network,disk,usb"

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

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_id > 0 ? var.vlan_id : null
  }

  ipconfig0  = "ip=${var.nodes[count.index].ip_address}${var.cidr_subnet},gw=${var.gateway}"
  nameserver = var.nameservers

  # args cannot be set via API token (requires root@pam)
  # Will be set via SSH post-creation using local-exec provisioner

  tags = join(";", local.common_tags)
}

# Set QEMU args via SSH since API token lacks root@pam privileges
resource "null_resource" "set_ignition_args" {
  count = var.ignition_server_url != "" ? length(var.nodes) : 0

  depends_on = [proxmox_vm_qemu.control_plane]

  triggers = {
    vmid         = var.nodes[count.index].vmid
    target_node  = var.nodes[count.index].target_node
    ssh_host     = lookup(var.proxmox_node_ssh_hosts, var.nodes[count.index].target_node, var.nodes[count.index].target_node)
    ignition_file = "/var/lib/vz/snippets/${var.nodes[count.index].name}.ign"
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no root@${self.triggers.ssh_host} \
        "qm set ${self.triggers.vmid} -args '-fw_cfg name=opt/com.coreos/config,file=${self.triggers.ignition_file}'"
    EOT
  }
}
