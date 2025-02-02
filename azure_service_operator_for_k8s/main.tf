# Get current subscription
data "azurerm_subscription" "current" {}

# Get current client
data "azurerm_client_config" "current" {}

#  Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
