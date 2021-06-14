# Deploy Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_subscription.current.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = []

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set"
    ]

    storage_permissions = []
  }

  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = azurerm_user_assigned_identity.mi.principal_id

    key_permissions = []

    secret_permissions = [
      "get",
      "list"
    ]

    storage_permissions = []
  }
}

resource "azurerm_key_vault_secret" "redis" {
  name         = "redisPass"
  value        = data.kubernetes_secret.redis_secret.data["redis-password"]
  key_vault_id = azurerm_key_vault.kv.id
}
