# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_user_assigned_identity" "aks" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "private_aks"
}

resource "azurerm_role_assignment" "kubelet_aks_private_dns_zone_contributor" {
  scope                = azurerm_private_dns_zone.aks_private_dns_zone.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

data "azurerm_subscription" "current" {}

data "azuread_client_config" "current" {}

resource "azuread_group" "aks_admins" {
  display_name     = "aks_admins"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
  members = [
    data.azuread_client_config.current.object_id,
  ]
}