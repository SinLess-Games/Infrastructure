// =====================================================================
// Vault Cluster Terraform Configuration (Managed by Ansible)
// =====================================================================
// Source: Ansible/roles/vault-deploy/templates/vault-cluster.tf.j2
// DO NOT EDIT MANUALLY
// =====================================================================

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  type        = bool
  description = "Allow insecure TLS for Proxmox API"
  default     = true
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

module "vault_cluster" {
  source = "./modules/vault-cluster"

  # Cluster configuration
  cluster_name     = "vault-cluster"
  environment      = "prod"
  node_count       = 3
  node_name_prefix = "vault"
  vm_id_start      = 200

  # Proxmox placement (HA distribution)
  target_nodes   = ["pve-01", "pve-04", "pve-05"]
  clone_template = "debian-13-template"

  # Network configuration
  ip_addresses   = ["10.10.10.2", "10.10.10.3", "10.10.10.4"]
  gateway        = "10.10.10.1"
  cidr_subnet    = "/24"
  vlan_id        = 0
  network_bridge = "vmbr0"
  nameservers    = "10.10.10.1 1.1.1.1"

  # Resource allocation
  cpu_cores   = 4
  cpu_sockets = 1
  memory_mb   = 8192
  disk_size   = "100G"
  storage     = "Vault"

  # Vault configuration
  vault_version      = "1.15.4"
  vault_port         = 8200
  vault_cluster_port = 8201
  vault_storage_path = "/opt/vault/data"
  vault_log_path     = "/opt/vault/logs"

  # TLS configuration
  vault_tls_enabled   = true
  vault_tls_cert_path = "/opt/vault/tls/vault.crt"
  vault_tls_key_path  = "/opt/vault/tls/vault.key"
  vault_tls_ca_path   = "/opt/vault/tls/ca.crt"

  # Access configuration
  default_user = "sinless777"
  ansible_user = "ansible"
  ssh_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA7g0acAC3ORT/DUzu3ftMtRW6MlVWuWZ7qqd4tNHLcY automation@sinlessgames", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDoqYKB+akwuGHSAJWn6EeXR70zIg9oZXuP60Al1mOS breakglass@sinlessgames", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEMakhAavnUU1qkhadP1tNtmwG7tsu49siUyMIEcKKn9 root@sinlessgames", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ0Ch6BKvYa5V+7su2oXhf8jRBgBdRKvoqd0UKVtt1mS sinless777@sinlessgames"]

  # HA and backup
  ha_enabled      = true
  ha_group        = "vault-ha"
  backup_enabled  = true
  backup_schedule = "0 2 * * *"

  # VM options
  onboot        = true
  agent_enabled = true
  protection    = true
  startup_order = 10

  # Tags and metadata
  tags        = ["vault", "tier-0", "ha"]
  description = "HashiCorp Vault cluster node (Terraform-managed)"
}
