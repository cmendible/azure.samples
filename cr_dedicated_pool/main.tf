resource "azurerm_resource_group" "rg" {
  name     = "secret-project"
  location = "West Europe"
}

resource "azurerm_container_registry" "cr" {
  name                = "crsecretproject"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
}

resource "azurerm_container_registry_agent_pool" "example" {
  name                    = "fastpool"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  container_registry_name = azurerm_container_registry.cr.name
  instance_count          = 1
  tier                    = "S3"
}
