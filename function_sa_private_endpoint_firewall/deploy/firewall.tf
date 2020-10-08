# Create a public Ip for the firewall
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "fw-cfm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the firewall
resource "azurerm_firewall" "firewall" {
  name                = "fw-cfm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
}

# Create the firewall rules
# This scenario can be implemented using any third party NVA or Azure Firewall network rules instead of application rules.
# https://docs.microsoft.com/en-us/azure/private-link/inspect-traffic-with-azure-firewall
resource "azurerm_firewall_network_rule_collection" "example" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100

  action = "Allow"

  rule {
    name = "testrule"

    source_addresses = azurerm_subnet.service.address_prefixes

    destination_ports = [
      "443",
    ]

    destination_addresses = [
      azurerm_private_endpoint.endpoint.private_service_connection[0].private_ip_address
    ]

    protocols = [
      "TCP"
    ]
  }
}
