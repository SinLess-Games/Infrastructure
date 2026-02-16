# =====================================================================
# Root Terraform Variables
# =====================================================================

variable "proxmox_api_url" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Whether to skip TLS verification for Proxmox API"
  type        = bool
  default     = false
}
