# Create a Managed identity for the Azure AI Foundry service
resource "azurerm_user_assigned_identity" "ai_foundry_identity" {
  name                = "mi-ai-foundry-identity"           # Name of the user-assigned identity
  location            = azurerm_resource_group.rg.location # Location from the resource group
  resource_group_name = azurerm_resource_group.rg.name     # Resource group name
}

# Create Azure AI Foundry service
resource "azapi_resource" "ai_foundry_hub" {
  type                      = "Microsoft.MachineLearningServices/workspaces@2024-10-01"
  name                      = var.ai_foundry_hub_name
  location                  = azurerm_ai_services.ai.location
  parent_id                 = azurerm_resource_group.rg.id
  schema_validation_enabled = false
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.ai_foundry_identity.id # User-assigned identity for the AI Foundry service
    ]
  }
  body = {
    kind : "Hub"
    properties = {
      systemDatastoresAuthMode = "identity"
      storageAccount           = azurerm_storage_account.st.id
      keyVault                 = azurerm_key_vault.kv.id
      containerRegistry        = azurerm_container_registry.acr.id
      applicationInsights      = azurerm_application_insights.appi.id
      publicNetworkAccess      = "Enabled"
      managedNetwork = {
        isolationMode = "AllowOnlyApprovedOutbound"
        firewallSku   = "Basic"
        status = {
          sparkReady = true
        }
        # outboundRules = {
        #   "storage_blob_outbound_rule" = {
        #     type = "PrivateEndpoint"
        #     destination = {
        #       serviceResourceId = azurerm_storage_account.st.id # Reference to the storage account
        #       sparkEnabled      = true                          # Enable Spark for this outbound rule
        #       subresourceTarget = "blob"                        # Target subresource for the outbound rule
        #     }
        #   }
        # }
      }
      primaryUserAssignedIdentity = azurerm_user_assigned_identity.ai_foundry_identity.id
      provisionNetworkNow         = true
      workspaceHubConfig = {
        defaultWorkspaceResourceGroup = azurerm_resource_group.rg.id
      }
      v1LegacyMode        = false
      enableDataIsolation = true
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_role_assignment" "hub_hub_connection_approver" {
  scope                = azapi_resource.ai_foundry_hub.id                                # Scope of the role assignment
  role_definition_name = "Azure AI Enterprise Network Connection Approver"               # Role definition name
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}
