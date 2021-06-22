resource "azurerm_signalr_service" "signalr" {
  name                = var.signalr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_S1"
    capacity = 1
  }

  features {
    flag  = "ServiceMode"
    value = "Default"
  }
}