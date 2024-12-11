# Create the Storage Account.
resource "azurerm_storage_account" "sa" {
  name                            = local.storage_account_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  network_rules {
    default_action = "Allow"
    bypass = [ "AzureServices" ]
  }
}

resource "azurerm_storage_container" "container" {
  name                  = local.container_name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}
