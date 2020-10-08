
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
  name                = "${var.function_name}-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90
}

# Create the Azure Function App
resource "azurerm_function_app" "func_app" {
  name                       = var.function_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.function_required_sa.name
  storage_account_access_key = azurerm_storage_account.function_required_sa.primary_access_key
  version                    = "~3"

  app_settings = {
    https_only                     = true
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key
    privatecfm_STORAGE             = azurerm_storage_account.sa.primary_connection_string
    # With this setting we'll force all outbound traffic through the VNet
    WEBSITE_VNET_ROUTE_ALL = "1"
    WEBSITE_DNS_SERVER = "168.63.129.16"
    # Properties used to deploy the zip
    HASH            = filesha256("./securecopy.zip")
    WEBSITE_USE_ZIP = "https://${azurerm_storage_account.function_required_sa.name}.blob.core.windows.net/${azurerm_storage_container.functions.name}/${azurerm_storage_blob.function.name}${data.azurerm_storage_account_sas.sas.sas}"
  }
}

# Enable Regional VNet integration. Function --> service Subnet 
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_function_app.func_app.id
  subnet_id      = azurerm_subnet.service.id
}
