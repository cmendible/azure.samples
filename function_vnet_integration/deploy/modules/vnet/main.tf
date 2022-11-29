# Create spoke
resource "azurerm_virtual_network" "spoke" {
  name                = "spoke-network"
  address_space       = var.spoke_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = []
  tags                = var.tags
}

# Create the Subnet for VNET Integration
resource "azurerm_subnet" "vnet_integration" {
  name                 = "appservices"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = var.vnet_integration_address_prefixes

  enforce_private_link_service_network_policies = true

  service_endpoints = [
    "Microsoft.Storage"
  ]

  # Delegate the subnet to "Microsoft.Web/serverFarms"
  delegation {
    name = "acctestdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
