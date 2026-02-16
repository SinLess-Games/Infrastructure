terraform {
  required_version = ">= 1.4"

 

  # Commented local backend for fallback/testing
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    # Provider by kevynb for individual DNS records
    teknitium = {
      source  = "kevynb/technitium"
      version = "~> 0.1.0"
    }

    # Alternative provider (supports zones + records)
    technitium-kenske = {
      source  = "kenske/technitium"
      version = "~> 0.0.6"
    }

    # Vault provider for secrets management
    vault = {
      source = "hashicorp/vault"
      version = "5.7.0"
    }

    # Proxmox provider for managing Proxmox resources
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }

    # Cloudflare provider for DNS management
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.16.0"
    }

    # Google Cloud provider for managing GCP resources
    google = {
      source = "hashicorp/google"
      version = "7.18.0"
    }

    # AWS provider for managing AWS resources
    aws = {
      source = "hashicorp/aws"
      version = "6.31.0"
    }

    # Azure provider for managing Azure resources
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.58.0"
    }

    # Linode provider for managing Linode resources
    linode = {
      source = "linode/linode"
      version = "3.8.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}