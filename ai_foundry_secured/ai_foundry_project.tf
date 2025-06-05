# Create an AI Foundry Project within the AI Foundry service
resource "azurerm_ai_foundry_project" "ai_foundry_project" {
  name               = var.ai_foundry_project_name        # Project name
  location           = azurerm_resource_group.rg.location # Location from the AI Foundry service
  ai_services_hub_id = azapi_resource.ai_foundry_hub.id   # Associated AI Foundry service

  identity {
    type = "SystemAssigned" # Enable system-assigned managed identity
  }
}

resource "azapi_resource" "ai_services_connection" {
  type                      = "Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview" # Resource type and API version
  name                      = "${azurerm_ai_services.ai.name}-connection"                                   # Resource name
  location                  = "global"                                                                      # Resource location
  parent_id                 = azapi_resource.ai_foundry_hub.id                                              # Parent resource group
  schema_validation_enabled = false
  body = {
    properties = {
      category      = "AIServices"
      target        = azurerm_ai_services.ai.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_ai_services.ai.id
      }
      credentials = {
        clientId = azurerm_user_assigned_identity.ai_foundry_identity.client_id # Client ID of the user-assigned identity
      }
    }
  }
}

resource "azurerm_role_assignment" "ai_foundry_project_developer" {
  scope                = azurerm_ai_foundry_project.ai_foundry_project.id
  role_definition_name = "Azure AI Developer"
  principal_id         = data.azurerm_client_config.current.object_id
}
