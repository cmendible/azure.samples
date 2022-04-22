resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix = substr(lower(random_id.random.hex), 1, 4)
  name       = "bot-direct-line-${local.name_sufix}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.name
  location = "West Europe"
}

resource "azurerm_user_assigned_identity" "id" {
  name                = local.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_application_insights" "ai" {
  name                = local.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_application_insights_api_key" "key" {
  name                    = local.name
  application_insights_id = azurerm_application_insights.ai.id
  read_permissions        = ["aggregate", "api", "draft", "extendqueries", "search"]
}

resource "azurerm_log_analytics_workspace" "la" {
  name                = local.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_service_plan" "plan" {
  name                = "bot-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "P1v2"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "bot" {
  name                = local.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.id.id,
    ]
  }

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
    websockets_enabled = true
    cors {
      support_credentials = false
      allowed_origins = [
        "https://botservice.hosting.portal.azure.net",
        "https://hosting.onecloud.azure-test.net/"
      ]
    }
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.ai.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai.connection_string
    DIRECTLINE_EXTENSION_VERSION          = "latest"
    DirectLineExtensionKey                = "" // Terraform's azurerm_bot_channel_directline does not return the DirectLine Extension Key
    MicrosoftAppType                      = "UserAssignedMSI"
    MicrosoftAppId                        = azurerm_user_assigned_identity.id.client_id
    MicrosoftAppPassword                  = ""
    MicrosoftAppTenantId                  = data.azurerm_client_config.current.tenant_id
  }
}

resource "azapi_resource" "bot" {
  name      = local.name
  parent_id = azurerm_resource_group.rg.id
  type      = "Microsoft.BotService/botServices@2021-05-01-preview"
  location  = "global"
  body = jsonencode({
    kind = "azurebot"
    sku = {
      name = "S1"
    }
    properties = {
      displayName                       = local.name
      iconUrl                           = "https://docs.botframework.com/static/devportal/client/images/bot-framework-default.png"
      endpoint                          = "https://${local.name}.azurewebsites.net/api/messages"
      msaAppId                          = azurerm_user_assigned_identity.id.client_id
      msaAppTenantId                    = data.azurerm_client_config.current.tenant_id
      msaAppMSIResourceId               = azurerm_user_assigned_identity.id.id
      msaAppType                        = "UserAssignedMSI"
      luisAppIds                        = []
      schemaTransformationVersion       = "1.3"
      isCmekEnabled                     = false
      developerAppInsightKey            = azurerm_application_insights.ai.instrumentation_key
      developerAppInsightsApiKey        = azurerm_application_insights_api_key.key.api_key
      developerAppInsightsApplicationId = azurerm_application_insights.ai.app_id
    }
  })
}

resource "azurerm_bot_channel_directline" "directline" {
  bot_name            = local.name
  location            = "global"
  resource_group_name = azurerm_resource_group.rg.name

  site {
    name                            = "Default Site"
    enabled                         = true
    v1_allowed                      = true
    v3_allowed                      = true
    enhanced_authentication_enabled = false
    trusted_origins                 = []
  }

  depends_on = [
    azapi_resource.bot
  ]
}

resource "azurerm_monitor_diagnostic_setting" "bot_diagnostics" {
  name                       = local.name
  target_resource_id         = azapi_resource.bot.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id

  log {
    category = "BotRequest"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
