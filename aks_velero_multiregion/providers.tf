terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 2.99.0"
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

