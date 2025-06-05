data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "http" "current_public_ip" {
  url = "https://ipinfo.io/ip"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
