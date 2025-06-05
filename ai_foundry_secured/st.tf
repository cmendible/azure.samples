# Create an Azure Storage Account
resource "azurerm_storage_account" "st" {
  name                          = var.storage_account_name           # Storage account name
  location                      = azurerm_resource_group.rg.location # Location from the resource group
  resource_group_name           = azurerm_resource_group.rg.name     # Resource group name
  account_tier                  = "Standard"                         # Performance tier
  account_replication_type      = "LRS"                              # Locally-redundant storage replication
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices"
    ]
    ip_rules = [
      data.http.current_public_ip.response_body
    ]
  }
}

resource "azurerm_role_assignment" "hub_sta_connection_approver" {
  scope                = azurerm_storage_account.st.id # Scope of the role assignment
  role_definition_name = "Azure AI Enterprise Network Connection Approver"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_sta_contributor" {
  scope                = azurerm_storage_account.st.id                                   # Scope of the role assignment
  role_definition_name = "Contributor"                                                   # Role definition name for contributor
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_sta_blob_data_contributor" {
  scope                = azurerm_storage_account.st.id                                   # Scope of the role assignment
  role_definition_name = "Storage Blob Data Contributor"                                 # Role definition name for contributor
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}
