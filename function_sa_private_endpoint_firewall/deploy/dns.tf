# Create the blob.core.windows.net Private DNS Zone
resource "azurerm_private_dns_zone" "private" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create an A record pointing to the Storage Account private endpoint
resource "azurerm_private_dns_cname_record" "cname" {
  name                = "${var.sa_name}.blob.core.windows.net"
  zone_name           = azurerm_private_dns_zone.private.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = "${var.sa_name}.privatelink.blob.core.windows.net"
}

resource "azurerm_private_dns_a_record" "sa" {
  name                = var.sa_name
  zone_name           = azurerm_private_dns_zone.private.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.endpoint.private_service_connection[0].private_ip_address]
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa" {
  name                  = "test"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
