terraform {
  required_version = ">= 1.3.9"
  required_providers {
    azurerm = {
      version = ">= 4.18.0"
    }
    dns = {
      version = ">= 3.2.4"
    }
  }
}

provider "azurerm" {
  features {}
}
