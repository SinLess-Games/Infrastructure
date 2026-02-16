terraform {
  required_version = ">= 1.4"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.7.0"
    }
  }
}

provider "vault" {
  address         = var.vault_addr
  token           = var.vault_token
  skip_tls_verify = var.vault_skip_tls_verify
  ca_cert_file    = var.vault_ca_cert_file
}

locals {
  kv_mounts     = var.kv_mounts
  engine_mounts = var.engine_mounts
  
  # Extract keys from sensitive config maps for for_each (Terraform requires non-sensitive keys)
  # Use nonsensitive() wrapper to allow these maps to be used in for_each
  aws_configs_map        = nonsensitive(var.aws_configs)
  gcp_configs_map        = nonsensitive(var.gcp_configs)
  azure_configs_map      = nonsensitive(var.azure_configs)
  linode_configs_map     = nonsensitive(var.linode_configs)
  kubernetes_configs_map = nonsensitive(var.kubernetes_configs)
  secrets_data_input = try(jsondecode(var.vault_secrets_data), {})
  secrets_data_map = {
    for path, secret in nonsensitive(local.secrets_data_input) : path => {
      data = try(secret.data, {})
    }
  }
}

resource "vault_mount" "kv" {
  for_each = local.kv_mounts

  path        = each.key
  type        = "kv"
  description = lookup(each.value, "description", null)

  options = merge(
    {
      version = "2"
    },
    lookup(each.value, "options", {})
  )

  default_lease_ttl_seconds = lookup(each.value, "default_lease_ttl_seconds", null)
  max_lease_ttl_seconds     = lookup(each.value, "max_lease_ttl_seconds", null)
}

resource "vault_mount" "engine" {
  for_each = local.engine_mounts

  path        = each.key
  type        = each.value.type
  description = lookup(each.value, "description", null)

  options                   = lookup(each.value, "options", null)
  default_lease_ttl_seconds = lookup(each.value, "default_lease_ttl_seconds", null)
  max_lease_ttl_seconds     = lookup(each.value, "max_lease_ttl_seconds", null)
}

resource "vault_aws_secret_backend" "aws" {
  for_each = local.aws_configs_map

  path                      = each.key
  access_key                = each.value.access_key
  secret_key                = each.value.secret_key
  region                    = lookup(each.value, "region", null)
  sts_endpoint              = lookup(each.value, "sts_endpoint", null)
  iam_endpoint              = lookup(each.value, "iam_endpoint", null)
  default_lease_ttl_seconds = lookup(each.value, "default_lease_ttl_seconds", null)
  max_lease_ttl_seconds     = lookup(each.value, "max_lease_ttl_seconds", null)

  depends_on = [vault_mount.engine]
}

resource "vault_gcp_secret_backend" "gcp" {
  for_each = local.gcp_configs_map

  path        = each.key
  credentials = each.value.credentials
  ttl         = lookup(each.value, "ttl", null)
  max_ttl     = lookup(each.value, "max_ttl", null)

  depends_on = [vault_mount.engine]
}

resource "vault_azure_secret_backend" "azure" {
  for_each = local.azure_configs_map

  path            = each.key
  tenant_id       = each.value.tenant_id
  client_id       = each.value.client_id
  client_secret   = each.value.client_secret
  subscription_id = each.value.subscription_id

  depends_on = [vault_mount.engine]
}

# Note: Linode secrets engine is not natively supported by Vault provider
# Linode mounts will be handled as generic engine mounts if needed

resource "vault_kubernetes_secret_backend" "kubernetes" {
  for_each = local.kubernetes_configs_map

  path                    = each.key
  kubernetes_host         = each.value.kubernetes_host
  kubernetes_ca_cert      = each.value.kubernetes_ca_cert

  depends_on = [vault_mount.engine]
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  for_each = var.ssh_configs

  backend              = each.key
  generate_signing_key = lookup(each.value, "generate_signing_key", true)

  depends_on = [vault_mount.engine]
}

locals {
  ssh_role_map = {
    for entry in flatten([
      for backend, cfg in var.ssh_configs : [
        for role in lookup(cfg, "roles", []) : {
          key     = "${backend}.${role.name}"
          backend = backend
          role    = role
        }
      ]
    ]) : entry.key => entry
  }
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  for_each = local.ssh_role_map

  backend      = each.value.backend
  name         = each.value.role.name
  key_type     = each.value.role.key_type
  allowed_users = each.value.role.allowed_users
  default_user = each.value.role.default_user
  allow_user_certificates = lookup(each.value.role, "allow_user_certificates", false)
  allow_host_certificates = lookup(each.value.role, "allow_host_certificates", false)
  ttl          = lookup(each.value.role, "ttl", null)

  depends_on = [vault_ssh_secret_backend_ca.ssh_ca]
}

resource "vault_pki_secret_backend_root_cert" "pki_root" {
  for_each = {
    for k, v in var.pki_configs : k => v
    if lookup(v, "generate_root", false)
  }

  backend     = each.key
  type        = "internal"
  common_name = lookup(each.value, "common_name", null)
  ttl         = lookup(each.value, "ttl", null)
  organization = lookup(each.value, "organization", null)
  ou          = lookup(each.value, "ou", null)

  depends_on = [vault_mount.engine]
}

resource "vault_pki_secret_backend_config_urls" "pki_urls" {
  for_each = var.pki_configs

  backend                   = each.key
  issuing_certificates      = lookup(each.value, "issuing_certificates", null)
  crl_distribution_points   = lookup(each.value, "crl_distribution_points", null)

  depends_on = [vault_mount.engine]
}

locals {
  transit_key_map = {
    for entry in flatten([
      for backend, cfg in var.transit_configs : [
        for key in lookup(cfg, "keys", []) : {
          key      = "${backend}.${key.name}"
          backend  = backend
          key_def  = key
        }
      ]
    ]) : entry.key => entry
  }
}

resource "vault_transit_secret_backend_key" "transit_key" {
  for_each = local.transit_key_map

  backend    = each.value.backend
  name       = each.value.key_def.name
  type       = lookup(each.value.key_def, "type", "aes256-gcm96")
  exportable = lookup(each.value.key_def, "exportable", false)

  depends_on = [vault_mount.engine]
}

# Create KV v2 secrets in the 'secrets' mount
resource "vault_generic_secret" "secrets" {
  for_each = local.secrets_data_map

  path            = "secrets/data/${each.key}"
  data_json       = jsonencode(merge({ "_placeholder" = "true" }, each.value.data))
  delete_all_versions = false

  depends_on = [vault_mount.kv]
}
