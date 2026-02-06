# =====================================================================
# Vault Cluster Terraform Module - Main Resources
# =====================================================================

# ---------------------------------------------------------------------
# Local Values
# ---------------------------------------------------------------------

locals {
  # Common VM tags
  common_tags = concat(
    var.tags,
    [
      "env-${var.environment}",
      "cluster-${var.cluster_name}"
    ]
  )

}

# ---------------------------------------------------------------------
# Vault Cluster VMs
# ---------------------------------------------------------------------

resource "proxmox_vm_qemu" "vault_node" {
  count = var.node_count

  # VM identification
  name        = "${var.node_name_prefix}-${format("%02d", count.index + 1)}"
  vmid        = var.vm_id_start + count.index
  target_node = var.target_nodes[count.index % length(var.target_nodes)]
  description = "${var.description} (Node ${count.index + 1}/${var.node_count}) on ${var.target_nodes[count.index % length(var.target_nodes)]}"

  # VM lifecycle
  onboot      = var.onboot
  protection  = var.protection
  startup     = "order=${var.startup_order}"

  # Clone from template
  clone      = var.clone_template
  full_clone = true

  # QEMU Guest Agent
  agent = var.agent_enabled ? 1 : 0

  # Resource allocation
  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb

  # Boot configuration
  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"

  # OS type
  os_type = "cloud-init"

  # Disk configuration
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

  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_id > 0 ? var.vlan_id : null
  }

  # Cloud-init configuration
  ipconfig0 = "ip=${var.ip_addresses[count.index]}${var.cidr_subnet},gw=${var.gateway}"
  
  nameserver = var.nameservers
  ciuser     = var.default_user
  cipassword = var.default_password
  
  # SSH configuration
  sshkeys = try(join("\n", var.ssh_keys), null)

  # Tags
  tags = join(";", local.common_tags)

  # VM lifecycle management
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      # Ignore cloud-init changes after initial provisioning
      # to avoid recreation on minor cloud-init adjustments
    ]
  }

}

# ---------------------------------------------------------------------
# Null Resource for Ansible Inventory Generation
# ---------------------------------------------------------------------

resource "null_resource" "generate_inventory" {
  # Generate Ansible inventory file for the Vault cluster
  triggers = {
    cluster_nodes = join(",", proxmox_vm_qemu.vault_node[*].name)
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/generate-inventory.sh"
    environment = {
      INVENTORY_PATH  = "${path.root}/inventory/vault-${var.environment}.yaml"
      ENVIRONMENT     = var.environment
      VAULT_VERSION   = var.vault_version
      VAULT_PORT      = var.vault_port
      VAULT_CLUSTER_PORT = var.vault_cluster_port
      VAULT_STORAGE_PATH = var.vault_storage_path
      VAULT_LOG_PATH  = var.vault_log_path
      VAULT_TLS_ENABLED = var.vault_tls_enabled
      CLUSTER_NAME    = var.cluster_name
      ANSIBLE_USER    = var.ansible_user
      NODES_JSON      = jsonencode([
        for idx, node in proxmox_vm_qemu.vault_node : {
          name         = node.name
          ip_address   = var.ip_addresses[idx]
          node_index   = idx + 1
          is_leader    = idx == 0
        }
      ])
    }
  }

  depends_on = [proxmox_vm_qemu.vault_node]
}

# ---------------------------------------------------------------------
# Data Sources for Vault Configuration
# ---------------------------------------------------------------------

# Export cluster member addresses for Raft retry_join configuration
locals {
  vault_cluster_members = [
    for idx, ip in var.ip_addresses : {
      node_name          = "${var.node_name_prefix}-${format("%02d", idx + 1)}"
      ip_address         = ip
      api_addr           = "https://${ip}:${var.vault_port}"
      cluster_addr       = "https://${ip}:${var.vault_cluster_port}"
      leader_api_addr    = "https://${ip}:${var.vault_port}"
    }
  ]

  # Generate retry_join configuration for Vault Raft
  vault_raft_retry_join = [
    for member in local.vault_cluster_members : {
      leader_api_addr = member.leader_api_addr
    }
  ]
}
