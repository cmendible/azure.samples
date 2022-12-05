resource "azurerm_virtual_network" "vnet" {
  name                = "apim-network"
  address_space       = ["10.5.0.0/16"]
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "apim" {
  name                 = "apim"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.0.0/29"]
}
