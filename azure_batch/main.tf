data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "batch"
  location = "West Europe"
}

resource "azurerm_role_assignment" "microsoft_azure_batch" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = var.azure_batch_object_id
}

resource "azuread_application" "sp" {
  display_name = "batch_cfm_sp"
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id
}

resource "azuread_service_principal_password" "password" {
  service_principal_id = azuread_service_principal.sp.object_id
}

resource "azurerm_role_assignment" "sp_azure_batch" {
  scope                = azurerm_batch_account.batch.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id # Microsoft Azure Batch
}
