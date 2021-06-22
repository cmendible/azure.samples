resource "azurerm_signalr_service" "signalr" {
  name                = var.signalr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_S1"
    capacity = 1
  }

  features {
    flag  = "ServiceMode"
    value = "Default"
  }
}

# Create the privatelink.service.signalr.net Private DNS Zone
resource "azurerm_private_dns_zone" "signalr" {
  name                = "privatelink.service.signalr.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_endpoint" "signalr_endpoint" {
  name                = "signalr-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.signalr_subnet.id

  private_service_connection {
    name                           = "signalr-peconnection"
    private_connection_resource_id = azurerm_signalr_service.signalr.id
    is_manual_connection           = false
    subresource_names              = ["signalr"]
  }

  private_dns_zone_group {
    name = "privatelink-signalr"
    private_dns_zone_ids = [azurerm_private_dns_zone.signalr.id]
  }
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "signalr" {
  name                  = "signalr"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.signalr.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "signalr_clients" {
  name                  = "signalr"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.signalr.name
  virtual_network_id    = azurerm_virtual_network.vnet_clients.id
}