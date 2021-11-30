# Create UDR for the service subnet
resource "azurerm_route_table" "service" {
  count                         = var.enable_firewall ? 1 : 0
  name                          = "service"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }
}

# Attach UDR to the service subnet
resource "azurerm_subnet_route_table_association" "service" {
  count          = var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.service.id
  route_table_id = azurerm_route_table.service[0].id
}
