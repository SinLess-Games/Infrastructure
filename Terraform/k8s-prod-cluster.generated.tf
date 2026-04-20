module "kubernetes_prod_control_plane" {
  source = "./modules/proxmox-vm-cluster"

  cluster_name = "rke2-prod"
  environment  = "prod"
  service_name = "kubernetes"
  node_role    = "control-plane"

  nodes = [
    {
      name        = "rke2-prod-cp-01"
      vmid        = 400
      target_node = "pve-01"
      storage     = "vm_disks_01"
      clone_template = "debian-13-template-pve-01"
      ip_address  = "10.10.40.11"
      hostname    = "rke2-prod-cp-01"
      fqdn        = "rke2-prod-cp-01.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-cp-02"
      vmid        = 401
      target_node = "pve-04"
      storage     = "vm_disks_04"
      clone_template = "debian-13-template-pve-04"
      ip_address  = "10.10.40.12"
      hostname    = "rke2-prod-cp-02"
      fqdn        = "rke2-prod-cp-02.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-cp-03"
      vmid        = 402
      target_node = "pve-05"
      storage     = "vm_disks_05"
      clone_template = "debian-13-template-pve-05"
      ip_address  = "10.10.40.13"
      hostname    = "rke2-prod-cp-03"
      fqdn        = "rke2-prod-cp-03.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-cp-04"
      vmid        = 403
      target_node = "pve-04"
      storage     = "vm_disks_04"
      clone_template = "debian-13-template-pve-04"
      ip_address  = "10.10.40.14"
      hostname    = "rke2-prod-cp-04"
      fqdn        = "rke2-prod-cp-04.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-cp-05"
      vmid        = 404
      target_node = "pve-05"
      storage     = "vm_disks_05"
      clone_template = "debian-13-template-pve-05"
      ip_address  = "10.10.40.15"
      hostname    = "rke2-prod-cp-05"
      fqdn        = "rke2-prod-cp-05.prod.k8s.sinlessgames.com"
    }
  ]

  clone_template                = "debian-13-template"
  storage                       = "VM_Disks"
  resource_pool                 = ""
  cpu_cores                     = 4
  cpu_sockets                   = 1
  memory_mb                     = 8192
  disk_size                     = "150G"
  network_bridge                = "vmbr40"
  vlan_id                       = 0
  gateway                       = "10.10.40.1"
  cidr_subnet                   = "/24"
  nameservers                   = "10.10.10.1 1.1.1.1"
  search_domain                 = "prod.k8s.sinlessgames.com"
  ssh_keys                      = var.kubernetes_ssh_keys
  default_user                  = "sinless777"
  cicustom_user_snippet_enabled = false
  tags                          = ["kubernetes", "rke2", "prod", "control-plane"]
  startup_order                 = 10
  force_create                  = true
}

module "kubernetes_prod_workers" {
  source = "./modules/proxmox-vm-cluster"

  cluster_name = "rke2-prod"
  environment  = "prod"
  service_name = "kubernetes"
  node_role    = "worker"

  nodes = [
    {
      name        = "rke2-prod-wk-01"
      vmid        = 410
      target_node = "pve-01"
      storage     = "vm_disks_01"
      clone_template = "debian-13-template-pve-01"
      ip_address  = "10.10.40.20"
      hostname    = "rke2-prod-wk-01"
      fqdn        = "rke2-prod-wk-01.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-wk-02"
      vmid        = 411
      target_node = "pve-04"
      storage     = "vm_disks_04"
      clone_template = "debian-13-template-pve-04"
      ip_address  = "10.10.40.21"
      hostname    = "rke2-prod-wk-02"
      fqdn        = "rke2-prod-wk-02.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-wk-03"
      vmid        = 412
      target_node = "pve-05"
      storage     = "vm_disks_05"
      clone_template = "debian-13-template-pve-05"
      ip_address  = "10.10.40.22"
      hostname    = "rke2-prod-wk-03"
      fqdn        = "rke2-prod-wk-03.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-wk-04"
      vmid        = 413
      target_node = "pve-04"
      storage     = "vm_disks_04"
      clone_template = "debian-13-template-pve-04"
      ip_address  = "10.10.40.23"
      hostname    = "rke2-prod-wk-04"
      fqdn        = "rke2-prod-wk-04.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-wk-05"
      vmid        = 414
      target_node = "pve-05"
      storage     = "vm_disks_05"
      clone_template = "debian-13-template-pve-05"
      ip_address  = "10.10.40.24"
      hostname    = "rke2-prod-wk-05"
      fqdn        = "rke2-prod-wk-05.prod.k8s.sinlessgames.com"
    },
    {
      name        = "rke2-prod-wk-06"
      vmid        = 415
      target_node = "pve-01"
      storage     = "vm_disks_01"
      clone_template = "debian-13-template-pve-01"
      ip_address  = "10.10.40.25"
      hostname    = "rke2-prod-wk-06"
      fqdn        = "rke2-prod-wk-06.prod.k8s.sinlessgames.com"
    }
  ]

  clone_template                = "debian-13-template"
  storage                       = "VM_Disks"
  resource_pool                 = ""
  cpu_cores                     = 6
  cpu_sockets                   = 1
  memory_mb                     = 16384
  disk_size                     = "150G"
  network_bridge                = "vmbr40"
  vlan_id                       = 0
  gateway                       = "10.10.40.1"
  cidr_subnet                   = "/24"
  nameservers                   = "10.10.10.1 1.1.1.1"
  search_domain                 = "prod.k8s.sinlessgames.com"
  ssh_keys                      = var.kubernetes_ssh_keys
  default_user                  = "sinless777"
  cicustom_user_snippet_enabled = false
  tags                          = ["kubernetes", "rke2", "prod", "worker"]
  startup_order                 = 20
  force_create                  = true
}
