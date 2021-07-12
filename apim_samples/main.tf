provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}



output "url" {
  value = "${azurerm_api_management.apim.gateway_url}/mock"
}
