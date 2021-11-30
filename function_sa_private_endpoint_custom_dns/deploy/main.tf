resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  resource_group_name  = "${var.resource_group}-${local.name_sufix}"
  storage_account_name = "${var.sa_name}${local.name_sufix}"
  function_name        = "${var.func_name}-${local.name_sufix}"
  func_code            = "./securecopy.zip"
  publish_code_command = "az webapp deployment source config-zip --resource-group ${local.resource_group_name} --name ${local.function_name} --src ${local.func_code}"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

# Create the Azure Function plan (Elastic Premium) 
resource "azurerm_app_service_plan" "plan" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  reserved            = true # this has to be set to true for Linux. Not related to the Premium Plan

  kind = "elastic"
  sku {
    tier     = "ElasticPremium"
    size     = "EP1"
    capacity = 1
  }
  maximum_elastic_worker_count = 20
}

# Create the Azure Function App
resource "azurerm_function_app" "func_app" {
  name                       = local.function_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~3"
  https_only                 = true
  os_type                    = "linux"

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1",
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    WEBSITE_VNET_ROUTE_ALL   = "1"
    WEBSITE_CONTENTOVERVNET  = "1"
    WEBSITE_DNS_SERVER       = azurerm_container_group.containergroup.ip_address
    privatecfm_STORAGE       = azurerm_storage_account.sa.primary_connection_string
  }

  depends_on = [
    azurerm_private_endpoint.endpoint,
    azurerm_private_dns_zone_virtual_network_link.sa,
    azurerm_virtual_network_peering.peer-vnet-hub-with-vnet,
    azurerm_virtual_network_peering.peer-vnet-vnet-with-hub,
  ]
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [
    local.publish_code_command,
    azurerm_function_app.func_app,
    azurerm_app_service_virtual_network_swift_connection.vnet_integration
  ]
  triggers = {
    input_json           = filemd5(local.func_code)
    publish_code_command = local.publish_code_command
  }
}

# Enable Regional VNet integration. Function --> service Subnet 
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_function_app.func_app.id
  subnet_id      = azurerm_subnet.service.id
}

