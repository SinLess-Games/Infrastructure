# =====================================================================
# Kubernetes Master (Control-Plane) Terraform Module - Main Resources
# =====================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

# =====================================================================
# Local Values
# =====================================================================

locals {
  # Common VM tags for cluster identification and management
  common_tags = concat(
    var.tags,
    [
      "kubernetes",
      "rke2",
      "control-plane",
      "cluster-${var.cluster_name}",
      "env-${var.environment}",
      "role-${var.node_role}"
    ]
  )
}

# =====================================================================
# Kubernetes Control-Plane VMs
# =====================================================================

resource "proxmox_vm_qemu" "control_plane" {
  count = length(var.nodes)

  # VM identification
  name        = var.nodes[count.index].name
  vmid        = var.nodes[count.index].vmid
  target_node = var.nodes[count.index].target_node
  description = <<-EOT
    **RKE2 Control-Plane Node**
    
    **Cluster Information:**
    - Cluster Name: ${var.cluster_name}
    - Environment: ${var.environment}
    - FQDN: ${var.nodes[count.index].fqdn}
    - Target Proxmox Node: ${var.nodes[count.index].target_node}
    
    **Network Configuration:**
    - IP Address: ${var.nodes[count.index].ip_address}${var.cidr_subnet}
    - Gateway: ${var.gateway}
    - VLAN: ${var.vlan_id} (Services Network)
    
    **Hardware Resources:**
    - CPU Cores: ${var.cpu_cores}
    - Sockets: ${var.cpu_sockets}
    - Memory: ${var.memory_mb}MB (${var.memory_mb / 1024}GB)
    - Disk Size: ${var.disk_size}
    - Storage Pool: ${var.storage}
    
    **Boot Configuration:**
    - BIOS: SeaBIOS (traditional PC firmware)
    - Boot Order: Disk first, Network fallback
    - Boot Device: Virtio0 (primary storage disk)
    - Hotplug: Enabled for network, disk, and USB
    
    **Features:**
    - Clone Template: ${var.clone_template}
    - Cloud-init: Enabled via IDE2
    - QEMU Guest Agent: Enabled for console and monitoring
    - Full Clone: Yes (independent from template)
    - Node Protection: ${var.protection ? "Enabled" : "Disabled"}
    
    **Kubernetes Role:**
    - Role: Control-Plane (etcd, API Server, Controller Manager, Scheduler)
    - RKE2 Version: Latest from channel
    - Storage: Local + Ceph integration ready
  EOT

  pool = var.resource_pool != "" ? var.resource_pool : null

  # VM lifecycle
  start_at_node_boot = var.start_at_node_boot
  protection         = var.protection
  force_create       = var.force_create
  startup            = "order=${var.startup_order}"

  # Clone from template
  clone      = var.clone_template
  full_clone = true

  # QEMU Guest Agent for console and VM monitoring
  agent = 1

  # Resource allocation
  cores   = var.cpu_cores
  sockets = var.cpu_sockets
  memory  = var.memory_mb

  # Boot configuration - SeaBIOS with virtio0 primary boot
  boot    = "order=virtio0;net0"
  scsihw  = "virtio-scsi-pci"
  hotplug = "network,disk,usb"
  os_type = "cloud-init"

  # Storage configuration
  disk {
    slot     = "virtio0"
    type     = "disk"
    storage  = var.storage
    size     = var.disk_size
    format   = "raw"
    backup   = true
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
  ipconfig0  = "ip=${var.nodes[count.index].ip_address}${var.cidr_subnet},gw=${var.gateway}"
  nameserver = var.nameservers
  cicustom   = "user=local:snippets/${var.nodes[count.index].name}-cloud-init.yaml"
  
  # SSH configuration
  sshkeys = try(join("\n", var.ssh_keys), null)
  ciuser  = var.default_user

  # VM state
  vm_state = "stopped"

  # Tags for organization and automation
  tags = join(";", local.common_tags)

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}
