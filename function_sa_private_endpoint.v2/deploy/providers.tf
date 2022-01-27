terraform {
  required_version = "> 0.12"
 required_providers {
    azurerm = {
      version = "= 2.93.1"
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
