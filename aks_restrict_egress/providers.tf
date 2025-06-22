terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "=4.34.0"
    }
  }
}

provider "azurerm" {
  features {}
}
