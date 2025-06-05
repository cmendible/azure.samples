# Create an Azure Key Vault resource
resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name                          # Name of the Key Vault
  location                      = azurerm_resource_group.rg.location          # Location from the resource group
  resource_group_name           = azurerm_resource_group.rg.name              # Resource group name
  tenant_id                     = data.azurerm_subscription.current.tenant_id # Azure tenant ID
  public_network_access_enabled = false
  enable_rbac_authorization     = true       # Enable RBAC authorization for Key Vault
  sku_name                      = "standard" # SKU tier for the Key Vault
  purge_protection_enabled      = false      # Enables purge protection to prevent accidental deletion

  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    ip_rules = [
      data.http.current_public_ip.response_body
    ]
  }
}

resource "azurerm_role_assignment" "hub_kv_connection_approver" {
  scope                = azurerm_key_vault.kv.id                                         # Scope of the role assignment
  role_definition_name = "Azure AI Enterprise Network Connection Approver"               # Role definition name
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_kv_admin" {
  scope                = azurerm_key_vault.kv.id                                         # Scope of the role assignment
  role_definition_name = "Key Vault Administrator"                                       # Role definition name
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_kv_ai_admin" {
  scope                = azurerm_key_vault.kv.id                                         # Scope of the role assignment
  role_definition_name = "Azure AI Administrator"                                        # Role definition name
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "me_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
