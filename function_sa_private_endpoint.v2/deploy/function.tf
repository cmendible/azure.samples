# Create the Azure Function plan (Elastic Premium) 
resource "azurerm_app_service_plan" "plan" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  kind = "elastic"
  sku {
    tier     = "ElasticPremium"
    size     = "EP1"
    capacity = 1
  }
}

# Create Application Insights
resource "azurerm_application_insights" "ai" {
  name                = local.function_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90
}

# Create the Azure Function App
resource "azurerm_windows_function_app" "func_app" {
  name                        = local.function_name
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  service_plan_id             = azurerm_app_service_plan.plan.id
  storage_account_name        = azurerm_storage_account.sa.name
  storage_account_access_key  = azurerm_storage_account.sa.primary_access_key
  functions_extension_version = "~3"

  site_config {}

  app_settings = {
    https_only                               = true
    APPINSIGHTS_INSTRUMENTATIONKEY           = azurerm_application_insights.ai.instrumentation_key
    privatecfm_STORAGE                       = azurerm_storage_account.sa.primary_connection_string
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.sa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.content_share.name
    # With this setting we'll force all outbound traffic through the VNet
    WEBSITE_VNET_ROUTE_ALL  = "1"
    WEBSITE_CONTENTOVERVNET = "1"
    # WEBSITE_DNS_SERVER     = "168.63.129.16"
  }

  depends_on = [
    azurerm_private_endpoint.endpoint,
    azurerm_private_dns_zone_virtual_network_link.sa,
  ]
}


# # Create the Azure Function App
# resource "azurerm_function_app" "func_app" {
#   name                       = local.function_name
#   location                   = azurerm_resource_group.rg.location
#   resource_group_name        = azurerm_resource_group.rg.name
#   app_service_plan_id        = azurerm_app_service_plan.plan.id
#   storage_account_name       = azurerm_storage_account.sa.name
#   storage_account_access_key = azurerm_storage_account.sa.primary_access_key
#   version                    = "~3"

#   app_settings = {
#     https_only                               = true
#     APPINSIGHTS_INSTRUMENTATIONKEY           = azurerm_application_insights.ai.instrumentation_key
#     privatecfm_STORAGE                       = azurerm_storage_account.sa.primary_connection_string
#     WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.sa.primary_connection_string
#     WEBSITE_CONTENTSHARE                     = azurerm_storage_share.content_share.name
#     # With this setting we'll force all outbound traffic through the VNet
#     WEBSITE_VNET_ROUTE_ALL  = "1"
#     WEBSITE_CONTENTOVERVNET = "1"
#     # WEBSITE_DNS_SERVER     = "168.63.129.16"
#   }

#   depends_on = [
#     azurerm_private_endpoint.endpoint,
#     azurerm_private_dns_zone_virtual_network_link.sa,
#   ]
# }

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [
    local.publish_code_command,
    azurerm_windows_function_app.func_app,
    azurerm_app_service_virtual_network_swift_connection.vnet_integration
  ]
  triggers = {
    input_json           = filemd5(local.func_code)
    publish_code_command = local.publish_code_command
  }
}

# Enable Regional VNet integration. Function --> service Subnet 
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_function_app.func_app.id
  subnet_id      = azurerm_subnet.service.id
}
