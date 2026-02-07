terraform {
  required_version = ">= 1.4"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.7.0"
    }
  }

  backend "local" {
    path = "../../terraform.tfstate.d/vault-secrets/terraform.tfstate"
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
