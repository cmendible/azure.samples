# Create spoke
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-flex"
  address_space       = ["10.6.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_servers         = []
}

# Create the Subnet for VNET Integration
resource "azurerm_subnet" "flex" {
  name                 = "flex"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.6.2.0/24"]

  # Delegate the subnet to "Microsoft.App/environments"
  delegation {
    name = "flex-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
