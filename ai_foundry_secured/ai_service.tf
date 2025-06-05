# Deploy Azure AI Services resource
resource "azurerm_ai_services" "ai" {
  name                         = var.ai_services_name               # AI Services resource name
  location                     = azurerm_resource_group.rg.location # Location from the resource group
  resource_group_name          = azurerm_resource_group.rg.name     # Resource group name
  sku_name                     = "S0"                               # Pricing SKU tier
  local_authentication_enabled = false
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt4o"
  cognitive_account_id = azurerm_ai_services.ai.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-05-13"
  }
  sku {
    name     = "GlobalStandard"
    capacity = 200
  }
}

resource "azurerm_role_assignment" "hub_ai" {
  scope                = azurerm_ai_services.ai.id # Scope of the role assignment
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}
