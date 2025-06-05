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

resource "azurerm_private_endpoint" "acr_endpoint" {
  name                = "acr-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "acr-privateserviceconnection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "privatelink-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

# Create the privatelink.file.core.windows.net Private DNS Zone
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io" # Private DNS zone for Azure Container Registry
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}
