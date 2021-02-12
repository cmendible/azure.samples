terraform {
  required_version = ">= 0.13.5"
}

provider "azurerm" {
  version = "= 2.46.1"
  features {}
}

provider "azuread" {
  version = "= 1.3.0"
}

provider "http" {
  version = "= 2.0.0"
}
