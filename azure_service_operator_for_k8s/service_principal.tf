
# Create AAD Aplication
resource "azuread_application" "sp" {
  name     = var.service_principal_name
  homepage = "http://${var.service_principal_name}"

  identifier_uris = [
    "http://${var.service_principal_name}"
  ]

  reply_urls = []

  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
}

# Create the Service Principal
resource "azuread_service_principal" "sp" {
  application_id               = azuread_application.sp.application_id
  app_role_assignment_required = false

  tags = []
}

# Make the Service Principal a Contibutor in the target subscription
resource "azurerm_role_assignment" "sp" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id
}

# Generate a password
resource "random_password" "sp_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  keepers = {
    sp_id = azuread_application.sp.id
  }
}

# Set the Service Principal Password
resource "azuread_application_password" "sp_password" {
  application_object_id = azuread_application.sp.id
  value                 = random_password.sp_password.result
  end_date_relative     = "87600h"
}
