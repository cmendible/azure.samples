# Deploy Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_subscription.current.tenant_id

  sku_name = "standard"

  # Add read & list permissions to the calling client.
  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = []

    secret_permissions = [
      "get",
      "list",
    ]

    storage_permissions = []
  }

  # Add requiered permission so the service principal used by the operator can manage secrets.
  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = azuread_service_principal.sp.object_id

    key_permissions = []

    secret_permissions = [
      "delete",
      "get",
      "list",
      "set"
    ]

    storage_permissions = []
  }
}
