resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix                      = substr(lower(random_id.random.hex), 1, 4)
  storage_account_name            = "stquarkus${local.name_sufix}"
  plan_name                       = "plan-quarkus${local.name_sufix}"
  function_name                   = "func-quarkus${local.name_sufix}"
}

resource "azurerm_resource_group" "rg" {
  name     = "azure-functions-quarkus"
  location = "West Europe"
}

resource "azurerm_storage_account" "st" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = local.plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "func" {
  name                        = local.function_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  service_plan_id             = azurerm_service_plan.plan.id
  storage_account_name        = azurerm_storage_account.st.name
  storage_account_access_key  = azurerm_storage_account.st.primary_access_key
  functions_extension_version = "~4"

  site_config {}
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}
