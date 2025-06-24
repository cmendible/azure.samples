
# Create the Private DNS Zones
resource "azurerm_private_dns_zone" "private" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zones with the Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub_private" {
  name                  = "privatelink.${var.location}.azmk8s.io-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_container_group" "containergroup" {
  name                = "bind"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.dns.id]

  container {
    name   = "bind"
    image  = "cmendibl3/dnsforwarder"
    cpu    = "1"
    memory = "1"

    ports {
      port     = 53
      protocol = "UDP"
    }
  }
}
