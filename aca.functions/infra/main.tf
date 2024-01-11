data "azurerm_subscription" "current" {}

resource "random_id" "random" {
  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  storage_account_name = "${var.storage_account_name}${local.name_sufix}"
}

module "vnet" {
  source               = "./modules/vnet"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = var.virtual_network_name
}

module "mi" {
  source                = "./modules/mi"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  managed_identity_name = var.managed_identity_name
}

resource "azurerm_role_assignment" "id_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = module.mi.principal_id
}

module "log" {
  source              = "./modules/log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  log_name            = var.log_name
}

module "appi" {
  source              = "./modules/appi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  appi_name           = var.appi_name
  log_id              = module.log.log_id
}

module "st" {
  source               = "./modules/st"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = local.storage_account_name
  principal_id         = module.mi.principal_id
}

module "cae" {
  source            = "./modules/cae"
  location          = azurerm_resource_group.rg.location
  resource_group_id = azurerm_resource_group.rg.id
  cae_name          = var.cae_name
  cae_subnet_id     = module.vnet.cae_subnet_id
  log_workspace_id  = module.log.log_workspace_id
  log_key           = module.log.log_key
  appi_key          = module.appi.appi_key
}

module "ca_webapi" {
  source                     = "./modules/ca-webapi"
  location                   = azurerm_resource_group.rg.location
  resource_group_id          = azurerm_resource_group.rg.id
  ca_name                    = var.ca_webapi_name
  cae_id                     = module.cae.cae_id
  cae_default_domain         = module.cae.defaultDomain
  managed_identity_id        = module.mi.mi_id
  storage_account_name       = module.st.storage_account_name
  storage_container_name     = module.st.storage_container_name
  tenant_id                  = data.azurerm_subscription.current.tenant_id
  managed_identity_client_id = module.mi.client_id
}
