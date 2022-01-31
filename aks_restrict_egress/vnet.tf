# Hub VNET
resource "azurerm_virtual_network" "hub" {
  name                = "hub-network"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.3.0/26"]
}

# Create VNET for AKS
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/16", "192.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Subnet for AKS nodes.
resource "azurerm_subnet" "aks_nodes" {
  name                 = "aks_nodes"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/16"]
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
