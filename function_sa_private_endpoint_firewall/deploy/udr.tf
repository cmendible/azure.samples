# Create UDR for the service subnet
resource "azurerm_route_table" "service" {
  name                          = "service"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "to-private-endpoint"
    address_prefix         = "${azurerm_private_endpoint.endpoint.private_service_connection[0].private_ip_address}/32"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

# Attach UDR to the service subnet
resource "azurerm_subnet_route_table_association" "service" {
  subnet_id      = azurerm_subnet.service.id
  route_table_id = azurerm_route_table.service.id
}
