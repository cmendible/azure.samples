resource "random_id" "random" {
  byte_length = 8
}

data "azuread_client_config" "current" {}

data "azuread_user" "current" {
  object_id = data.azuread_client_config.current.object_id
}

module "current_public_ip" {
  source = "./modules/public_ip"
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  resource_group_name  = "${var.resource_group}-${local.name_sufix}"
  storage_account_name = "${var.sa_name}${local.name_sufix}"
  function_name        = "${var.func_name}-${local.name_sufix}"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

# Create VNETs
module "vnet" {
  source                            = "./modules/vnet"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  spoke_address_space               = var.spoke_address_space
  vnet_integration_address_prefixes = var.vnet_integration_address_prefixes
  tags                              = var.tags
}

# Create Storage Account
module "storage" {
  source                     = "./modules/storage"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = local.storage_account_name
  public_ip                  = module.current_public_ip.ip
  vnet_integration_subnet_id = module.vnet.vnet_integration_id
  tags                       = var.tags
}

# Create Function
module "function" {
  source                            = "./modules/function"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  function_name                     = local.function_name
  storage_name                      = module.storage.name
  storage_primary_connection_string = module.storage.primary_connection_string
  storage_primary_access_key        = module.storage.primary_access_key
  storage_content_share_name        = module.storage.content_share_name
  vnet_integration_subnet_id        = module.vnet.vnet_integration_id
  tags                              = var.tags
}
