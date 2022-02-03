terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = ">= 2.94.0"
    }
  }
}

provider "azurerm" {
  features {}
}