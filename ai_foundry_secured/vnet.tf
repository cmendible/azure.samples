# Create spoke
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke"
  address_space       = ["10.6.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Subnet for jumpbox
resource "azurerm_subnet" "jumpbox" {
  name                                          = "sub-jumpbox"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.spoke.name
  address_prefixes                              = ["10.6.2.0/24"]
  private_link_service_network_policies_enabled = true
}

# Create the Subnet for Private Endpoints
resource "azurerm_subnet" "privateendpoints" {
  name                                          = "sub-pe"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.spoke.name
  address_prefixes                              = ["10.6.3.0/24"]
  private_link_service_network_policies_enabled = true
}
