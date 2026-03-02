# =====================================================================
# Kubernetes Cluster Terraform Module - Version Constraints
# =====================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 3.0.1-rc1"
    }
  }
}
