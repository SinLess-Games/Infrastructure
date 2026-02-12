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

variable "aws_configs" {
  description = "AWS secrets engine configuration per mount path"
  type = map(object({
    access_key                = string
    secret_key                = string
    region                    = optional(string)
    sts_endpoint              = optional(string)
    iam_endpoint              = optional(string)
    default_lease_ttl_seconds = optional(number)
    max_lease_ttl_seconds     = optional(number)
  }))
  default = {}
  sensitive = true
}

variable "gcp_configs" {
  description = "GCP secrets engine configuration per mount path"
  type = map(object({
    credentials = string
    ttl         = optional(number)
    max_ttl     = optional(number)
  }))
  default = {}
  sensitive = true
}

variable "azure_configs" {
  description = "Azure secrets engine configuration per mount path"
  type = map(object({
    tenant_id       = string
    client_id       = string
    client_secret   = string
    subscription_id = string
  }))
  default = {}
  sensitive = true
}

variable "linode_configs" {
  description = "Linode secrets engine configuration per mount path"
  type = map(object({
    token = string
  }))
  default = {}
  sensitive = true
}

variable "kubernetes_configs" {
  description = "Kubernetes secrets engine configuration per mount path"
  type = map(object({
    kubernetes_host       = string
    kubernetes_ca_cert    = string
    token_reviewer_jwt    = string
    issuer                = optional(string)
    disable_iss_validation = optional(bool)
  }))
  default = {}
  sensitive = true
}

variable "ssh_configs" {
  description = "SSH secrets engine configuration per mount path"
  type = map(object({
    generate_signing_key = optional(bool)
    roles = optional(list(object({
      name          = string
      key_type      = string
      allowed_users = string
      default_user  = string
      allow_user_certificates = optional(bool)
      allow_host_certificates = optional(bool)
      ttl           = optional(string)
    })))
  }))
  default = {}
}

variable "pki_configs" {
  description = "PKI secrets engine configuration per mount path"
  type = map(object({
    generate_root             = optional(bool)
    common_name               = optional(string)
    ttl                       = optional(string)
    organization              = optional(string)
    ou                        = optional(string)
    issuing_certificates      = optional(list(string))
    crl_distribution_points   = optional(list(string))
  }))
  default = {}
}

variable "transit_configs" {
  description = "Transit secrets engine configuration per mount path"
  type = map(object({
    keys = optional(list(object({
      name       = string
      type       = optional(string)
      exportable = optional(bool)
    })))
  }))
  default = {}
}

variable "terraform_configs" {
  description = "Terraform secrets engine configuration per mount path"
  type = map(object({
    address              = string
    token                = string
    default_organization = optional(string)
  }))
  default = {}
  sensitive = true
}
