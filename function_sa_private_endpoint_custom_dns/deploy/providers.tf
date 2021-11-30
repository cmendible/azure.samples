terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 2.86.0"
    }
    random = {
      version = "= 3.1.0"
    }
    http = {
      version = "= 2.1.0"
    }
    null = {
      version = "= 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}
