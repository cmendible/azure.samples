# Create VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # Use Private DNS Zone. That's right we have to add this magical IP here.
  # Note: this was preventing Azure Firewall from being deployed!!!
  # dns_servers = ["168.63.129.16"]
}

# Create the Subnet for the Azure Function. This is the subnet where we'll enable Vnet Integration.
resource "azurerm_subnet" "service" {
  name                 = "service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  # Delegate the subnet to "Microsoft.Web/serverFarms"
  delegation {
    name = "acctestdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage"]
}

# Create the Subnet for the private endpoints. This is where the IP of the private endpoint will live.
resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

# Create the Subnet for the firewall
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/26"]
}
