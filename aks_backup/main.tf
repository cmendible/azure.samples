data "azurerm_client_config" "current" {}

locals {
  backup_location = "northeurope"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}-backup"
  location = var.location
}

# Create the Storage Account required by velero.
resource "azurerm_storage_account" "sa" {
  name                      = var.sa_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
}

# Create velero container
resource "azurerm_storage_container" "backup" {
  name                  = "backup"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}

module "aks" {
  source                = "./aks"
  location              = var.location
  resource_group        = var.resource_group
  aks_name              = var.aks_name
  sta_name              = var.sa_name
  backup_resource_group = azurerm_resource_group.rg.name
  storage_account_id    = azurerm_storage_account.sa.id
}
