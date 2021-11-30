# Hub VNET
resource "azurerm_virtual_network" "hub" {
  name                = "hub-network"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Firewall subnet
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.0.0/26"]
}

# DNS subnet
resource "azurerm_subnet" "dns" {
  name                 = "dns"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.2.0/24"]

  delegation {
    name = "acidelegationservice"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Subnet for the Azure Function. This is thge subnet where we'll enable Vnet Integration.
resource "azurerm_subnet" "service" {
  name                 = "service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_service_network_policies = true

  # Delegate the subnet to "Microsoft.Web/serverFarms"
  delegation {
    name = "acctestdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create the Subnet for the private endpoints. This is where the IP of the private enpoint will live.
resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

# Azure Virtual Network peering between Virtual Network A and B
resource "azurerm_virtual_network_peering" "peer-vnet-hub-with-vnet" {
  name                         = "peer-vnet-hub-with-vnet"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
}

# Azure Virtual Network peering between Virtual Network B and A
resource "azurerm_virtual_network_peering" "peer-vnet-vnet-with-hub" {
  name                         = "peer-vnet-b-with-a"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  depends_on                   = [azurerm_virtual_network_peering.peer-vnet-hub-with-vnet]
}