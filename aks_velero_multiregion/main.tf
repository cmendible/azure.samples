data "azurerm_client_config" "current" {}

locals {
  backup_location = "eastus2"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}-backup"
  location = local.backup_location
}

# Create the "private" Storage Account.
resource "azurerm_storage_account" "sa" {
  name                      = var.sa_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
}

# Create input container
resource "azurerm_storage_container" "bucket" {
  name                  = "velero"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}


# Create Application registration for velero
resource "azuread_application" "velero" {
  display_name = "velero_sp"
  owners = [
    data.azurerm_client_config.current.object_id,
  ]
}

# Create Service principal for velero
resource "azuread_service_principal" "velero" {
  application_id = azuread_application.velero.application_id
  owners = [
    data.azurerm_client_config.current.object_id,
  ]
}

# Create velero's Service principal password
resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.velero.id
}

module "aks" {
  source                = "./aks"
  location              = var.location
  resource_group        = var.resource_group
  aks_name              = var.aks_name
  sta_name              = var.sa_name
  backup_resource_group = azurerm_resource_group.rg.name
  client_id             = azuread_application.velero.application_id
  client_secret         = azuread_service_principal_password.main.value
}

module "aks-dr" {
  source                = "./aks"
  location              = local.backup_location
  resource_group        = "${var.resource_group}-dr"
  aks_name              = "${var.aks_name}-dr"
  sta_name              = var.sa_name
  backup_resource_group = azurerm_resource_group.rg.name
  client_id             = azuread_application.velero.application_id
  client_secret         = azuread_service_principal_password.main.value
}

resource "azurerm_role_assignment" "sp_storage_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.velero.object_id
}

resource "azurerm_role_assignment" "sp_aks_contributor" {
  scope                = module.aks.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.velero.object_id
}

resource "azurerm_role_assignment" "sp_aks_dr_contributor" {
  scope                = module.aks-dr.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.velero.object_id
}
