terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 2.93.1"
    }
  }
}

provider "azurerm" {
  features {}
}
