resource "azurerm_virtual_network" "vnet_clients" {
  name                = "aks-vnet-clients"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks_subnet_clients" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_clients.name
  address_prefixes     = ["10.0.1.0/22"] // Making room for more than 1000 clients
}
