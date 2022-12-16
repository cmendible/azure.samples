# Create the Azure Function plan (Elastic Premium) 
resource "azurerm_service_plan" "plan" {
  name                = "azure-functions-contoso-service-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  os_type             = "Linux"
  sku_name            = "EP1"
  worker_count        = 1


}

# Create Application Insights
resource "azurerm_application_insights" "ai" {
  name                = var.function_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  retention_in_days   = 90
  tags                = var.tags
}

resource "azurerm_linux_function_app" "func_app" {
  name                        = var.function_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  service_plan_id             = azurerm_service_plan.plan.id
  storage_account_name        = var.storage_name
  storage_account_access_key  = var.storage_primary_access_key
  functions_extension_version = "~4"
  https_only                  = true
  tags                        = var.tags

  site_config {
    application_insights_key               = azurerm_application_insights.ai.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.ai.connection_string
    remote_debugging_enabled               = false
    remote_debugging_version               = "VS2019"
    vnet_route_all_enabled                 = true
    runtime_scale_monitoring_enabled       = true
    application_stack {
      node_version = "16"
    }
    pre_warmed_instance_count = 1
  }

  app_settings = {
    https_only                                   = true
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING     = var.storage_primary_connection_string
    WEBSITE_CONTENTSHARE                         = var.storage_content_share_name
    WEBSITE_CONTENTOVERVNET                      = "1"
    SCM_DO_BUILD_DURING_DEPLOYMENT               = false
    WEBSITE_RUN_FROM_PACKAGE                     = 1
    WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS = 0 // Fixes slot swap issue (https://github.com/MicrosoftDocs/azure-docs-pr/pull/219797)
    # WEBSITE_DNS_SERVER                       = var.name_server_ip
    # FUNCTIONS_WORKER_PROCESS_COUNT           = "1"
  }
}

# Enable Regional VNet integration. Function --> service Subnet 
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_function_app.func_app.id
  subnet_id      = var.vnet_integration_subnet_id
}
