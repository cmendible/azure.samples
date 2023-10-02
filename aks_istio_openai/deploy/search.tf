resource "azurerm_search_service" "search" {
  name                = "cfm-search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "standard"

  local_authentication_enabled = false
}
