terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = ">= 2.98.0"
    }
  }
}

provider "azurerm" {
  features {
      key_vault {
        recover_soft_deleted_key_vaults = true
      }
  }
}
