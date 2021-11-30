# Create a public Ip for the firewall
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "fw-cfm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "No-Zone"
}

# Create the firewall
resource "azurerm_firewall" "firewall" {
  count               = var.enable_firewall ? 1 : 0
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
resource "azurerm_firewall_network_rule_collection" "rules" {
  count               = var.enable_firewall ? 1 : 0
  name                = "dns_and_private_endpoints"
  azure_firewall_name = azurerm_firewall.firewall[0].name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "DNS"
    source_addresses      = azurerm_subnet.service.address_prefixes
    destination_ports     = ["53"]
    destination_addresses = [azurerm_container_group.containergroup.ip_address]
    protocols             = ["UDP"]
  }

  rule {
    name                  = "STA"
    source_addresses      = azurerm_subnet.service.address_prefixes
    destination_ports     = ["443"]
    destination_addresses = azurerm_subnet.endpoint.address_prefixes
    protocols             = ["TCP"]
  }
}
