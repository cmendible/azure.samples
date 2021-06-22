resource "azurerm_virtual_network_peering" "server" {
  name                      = "servertoclients"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_clients.id
}

resource "azurerm_virtual_network_peering" "clients" {
  name                      = "clientstoserver"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_clients.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}