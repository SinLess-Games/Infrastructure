variable "vault_addr" {
  type        = string
  description = "Vault API address"
}

variable "vault_token" {
  type        = string
  description = "Vault token with permissions to enable secrets engines"
  sensitive   = true
}

variable "vault_skip_tls_verify" {
  type        = bool
  description = "Skip TLS verification when connecting to Vault"
  default     = true
}

variable "vault_ca_cert_file" {
  type        = string
  description = "Path to a CA certificate file for Vault TLS verification"
  default     = null
  nullable    = true
}

variable "kv_mounts" {
  type = map(object({
    description               = optional(string)
    options                   = optional(map(string))
    default_lease_ttl_seconds = optional(number)
    max_lease_ttl_seconds     = optional(number)
  }))

  description = "KV v2 mounts to enable"

  default = {
    helix = {
      description = "Helix secrets (KV v2)"
    }
    sinlessgames = {
      description = "SinLess Games secrets (KV v2)"
    }
    "kubernetes-dev" = {
      description = "Kubernetes dev secrets (KV v2)"
    }
    "kubernetes-test" = {
      description = "Kubernetes test secrets (KV v2)"
    }
    "kubernetes-prod" = {
      description = "Kubernetes prod secrets (KV v2)"
    }
  }
}

variable "engine_mounts" {
  type = map(object({
    type                      = string
    description               = optional(string)
    options                   = optional(map(string))
    default_lease_ttl_seconds = optional(number)
    max_lease_ttl_seconds     = optional(number)
  }))

  description = "Non-KV secrets engines to enable"

  default = {
    aws = {
      type        = "aws"
      description = "AWS secrets engine"
    }
    terraform = {
      type        = "terraform"
      description = "Terraform Cloud secrets engine"
    }
    ansible = {
      type        = "kv"
      description = "Ansible secrets engine (KV v1)"
      options = {
        version = "1"
      }
    }
    ssh = {
      type        = "ssh"
      description = "SSH secrets engine"
    }
  }
}
