terraform {
  required_version = ">= 1.0.4"
  required_providers {
    azurerm = {
      version = ">= 3.51.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}
