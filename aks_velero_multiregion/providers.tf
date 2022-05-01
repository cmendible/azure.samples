terraform {
  required_version = ">= 1.1.8"
  required_providers {
    azurerm = {
      version = "= 3.0.2"
    }
    azuread = {
      version = "= 2.19.1"
    }
    kubernetes = {
      version = "= 2.1.0"
    }
    helm = {
      version = "= 2.1.2"
    }
  }
}

provider "azurerm" {
  features {}
}

