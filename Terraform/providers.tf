terraform {
  required_version = ">= 1.4"

  required_providers {
    # Provider by kevynb for individual DNS records
    teknitium = {
      source  = "kevynb/technitium"
      version = "~> 0.1.0"
    }

    # Alternative provider (supports zones + records)
    technitium_kenske = {
      source  = "kenske/technitium"
      version = "~> 0.0.6"
    }
  }
}