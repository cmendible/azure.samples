
# Create the Private DNS Zones
resource "azurerm_private_dns_zone" "private" {
  count               = length(var.sa_services)
  name                = "privatelink.${var.sa_services[count.index]}.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zones with the Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa" {
  count                 = length(var.sa_services)
  name                  = "privatelink.${var.sa_services[count.index]}.core.windows.net-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private[count.index].name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_network_profile" "np" {
  name                = "bindnp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  container_network_interface {
    name = "bindnic"

    ip_configuration {
      name      = "bindipconfig"
      subnet_id = azurerm_subnet.dns.id
    }
  }
}

resource "azurerm_container_group" "containergroup" {
  name                = "bind"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  network_profile_id  = azurerm_network_profile.np.id

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