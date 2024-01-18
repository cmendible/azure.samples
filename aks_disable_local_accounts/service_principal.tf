data "azurerm_client_config" "current" {}

resource "azuread_application" "sp" {
  display_name = var.sp_name
  owners = [
    data.azurerm_client_config.current.object_id
  ]
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id
  owners = [
    data.azurerm_client_config.current.object_id
  ]
}

# Create kubecost's Service principal password
resource "azuread_service_principal_password" "sp_password" {
  service_principal_id = azuread_service_principal.sp.id
  end_date             = "2099-01-01T00:00:00Z"
}

resource "azuread_group" "aks_admins" {
  display_name     = "aks_admins"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    data.azuread_client_config.current.object_id,
    azuread_service_principal.sp.object_id,
  ]
}
