resource "azurerm_key_vault" "kv" {
  name                        = "batchkvcfmnn"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = false
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "9bbdc603-63eb-4bd5-9bcc-51bccf3ede37" # Microsoft Azure Batch

    # https://docs.microsoft.com/en-us/azure/batch/batch-account-create-portal#create-a-key-vault
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover"
    ]
  }
}