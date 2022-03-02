
# Create the Private DNS Zones
resource "azurerm_private_dns_zone" "aks_private_dns_zone" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zones with the AKS VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_aks_private_dns_zone" {
  name                  = "privatelink.${var.location}.azmk8s.io-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aks_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
