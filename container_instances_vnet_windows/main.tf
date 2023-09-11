resource "azurerm_resource_group" "rg" {
  name     = "aci-windows"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aci-network"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aci" {
  name                 = "aci"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.0.0/29"]

  delegation {
    name = "acidelegationservice"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_container_group" "aci" {
  name                = "aci"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Windows"

  container {
    name   = "server-core"
    image  = "mcr.microsoft.com/windows/servercore:10.0.17763.1158-amd64"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    commands = ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]
  }

  subnet_ids = [
    azurerm_subnet.aci.id
  ]

}
