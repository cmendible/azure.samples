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

# resource "azurerm_application_insights_api_key" "key" {
#   name                    = local.name
#   application_insights_id = azurerm_application_insights.ai.id
#   read_permissions        = ["aggregate", "api", "draft", "extendqueries", "search"]
# }

data "azurerm_client_config" "current" {}

module "bot" {
  source              = "./modules/bot"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_name     = local.name
  bot_name            = local.name
  bot_endpoint        = "https://${local.name}.azurewebsites.net/api/messages"
  msaAppTenantId      = data.azurerm_client_config.current.tenant_id
  msaAppMSIResourceId = azurerm_user_assigned_identity.id.id
  msaAppId            = azurerm_user_assigned_identity.id.client_id
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
    module.bot
  ]
}

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
