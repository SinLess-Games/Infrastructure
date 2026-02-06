terraform {
  required_version = ">= 1.4"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 3.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.7.0"
    }
  }
}
