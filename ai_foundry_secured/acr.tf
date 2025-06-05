# Create an Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                          = var.container_registry_name        # Container registry name
  location                      = azurerm_resource_group.rg.location # Location from the resource group
  resource_group_name           = azurerm_resource_group.rg.name     # Resource group name
  sku                           = "Premium"                          # SKU tier for the container registry
  admin_enabled                 = true                               # Enable admin user for the registry
  public_network_access_enabled = false

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = "${data.http.current_public_ip.response_body}/32" # Allow access from the current public IP
    }
  }
}

resource "azurerm_role_assignment" "hub_acr_connection_approver" {
  scope                = azurerm_container_registry.acr.id # Scope of the role assignment
  role_definition_name = "Azure AI Enterprise Network Connection Approver"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_acr_connection_contributor" {
  scope                = azurerm_container_registry.acr.id # Scope of the role assignment
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}
  