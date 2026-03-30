locals {
  node_details = [
    for idx, node in var.nodes : {
      index       = idx + 1
      name        = node.name
      vmid        = node.vmid
      target_node = node.target_node
      ip_address  = node.ip_address
      hostname    = try(node.hostname, node.name)
      fqdn        = try(node.fqdn, null)
    }
  ]

  auto_tags = distinct(compact(concat(
    var.tags,
    [
      var.service_name != "" ? var.service_name : null,
      "env-${var.environment}",
      "cluster-${var.cluster_name}",
      var.node_role != "" ? "role-${var.node_role}" : null
    ]
  )))
}

resource "proxmox_vm_qemu" "cluster_node" {
  count = length(local.node_details)

  name        = local.node_details[count.index].name
  vmid        = local.node_details[count.index].vmid
  target_node = local.node_details[count.index].target_node

  description = trimspace(<<-EOT
    ${var.description}

    Cluster: ${var.cluster_name}

    Environment: ${var.environment}

    Service: ${var.service_name != "" ? var.service_name : "generic"}

    Role: ${var.node_role != "" ? var.node_role : "node"}

    Name: ${local.node_details[count.index].name}

    FQDN: ${coalesce(local.node_details[count.index].fqdn, "n/a")}

    VMID: ${local.node_details[count.index].vmid}

    Proxmox Node: ${local.node_details[count.index].target_node}

    IP Address: ${local.node_details[count.index].ip_address}${var.cidr_subnet}

    Tags: ${join(", ", local.auto_tags)}

    Managed By: Terraform
    
    Module: proxmox-vm-cluster
EOT
  )

  pool = var.resource_pool != "" ? var.resource_pool : null

  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  force_create       = var.force_create
  startup            = "order=${var.startup_order}"

  clone      = var.clone_template
  full_clone = true

  agent   = var.agent_enabled ? 1 : 0
  os_type = "cloud-init"

  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb
  balloon = var.memory_balloon_mb

  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"

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

  ipconfig0    = "ip=${local.node_details[count.index].ip_address}${var.cidr_subnet},gw=${var.gateway}"
  nameserver   = var.nameservers
  searchdomain = var.search_domain
  ciupgrade    = var.ciupgrade
  cicustom     = var.cicustom_user_snippet_enabled ? "user=${var.cicustom_snippet_storage}/${local.node_details[count.index].name}-cloud-init.yaml" : null

  ciuser     = var.default_user
  cipassword = var.default_password
  sshkeys    = length(var.ssh_keys) > 0 ? join("\n", var.ssh_keys) : null

  vm_state = var.vm_state
  tags     = join(";", local.auto_tags)

  lifecycle {
    precondition {
      condition     = var.memory_balloon_mb == null || var.memory_balloon_mb <= var.memory_mb
      error_message = "memory_balloon_mb must be null or less than or equal to memory_mb"
    }

    ignore_changes = [
      description,
    ]
  }
}
