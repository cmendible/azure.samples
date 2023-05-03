resource "random_id" "random" {
  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

locals {
  name_sufix          = substr(lower(random_id.random.hex), 1, 4)
  api_management_name = var.api_management_name
}

output "url" {
  value = "${azurerm_api_management.apim.gateway_url}/mock"
}
