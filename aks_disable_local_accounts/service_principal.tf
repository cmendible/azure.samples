resource "azuread_application" "sp" {
  display_name    = var.sp_name
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id
}

# Generate password for the Service Principal
resource "random_password" "passwd" {
  length      = 32
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  keepers = {
    aks_app_id = azuread_application.sp.id
  }
}

# Create kubecost's Service principal password
resource "azuread_service_principal_password" "sp_password" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.passwd.result
  end_date             = "2099-01-01T00:00:00Z"
}

resource "azuread_group" "aks_admins" {
  display_name     = "aks_admins"
  owners           = [data.azuread_client_config.current.object_id]

  members = [
    data.azuread_client_config.current.object_id,
    azuread_service_principal.sp.object_id,
  ]
}
