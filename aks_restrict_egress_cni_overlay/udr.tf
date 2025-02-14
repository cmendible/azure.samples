# Create UDR for the service subnet
resource "azurerm_route_table" "restrict" {
  name                = "restrict-aks-egress"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  route {
    name           = "to-internet"
    address_prefix = "${azurerm_public_ip.firewall_public_ip.ip_address}/32"
    next_hop_type  = "Internet"
  }
}

# Attach UDR to the service subnet
resource "azurerm_subnet_route_table_association" "restrict" {
  subnet_id      = azurerm_subnet.aks_nodes.id
  route_table_id = azurerm_route_table.restrict.id
}
