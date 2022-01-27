# Create the privatelink.*.core.windows.net Private DNS Zone
resource "azurerm_private_dns_zone" "private" {
  count               = length(var.sa_services)
  name                = "privatelink.${var.sa_services[count.index]}.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zones with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa" {
  count                 = length(var.sa_services)
  name                  = "privatelink.${var.sa_services[count.index]}.core.windows.net-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private[count.index].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
