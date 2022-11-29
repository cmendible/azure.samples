terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 3.30.0"
    }
    azuread = {
      version = "= 2.30.0"
    }
    random = {
      version = ">= 3.1.0"
    }
    http = {
      version = ">= 3.0.1"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = false
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
