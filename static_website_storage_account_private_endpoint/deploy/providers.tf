terraform {
  required_version = "> 0.12"
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "~> 2.26"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
