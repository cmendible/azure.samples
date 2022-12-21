# Create the Storage Account.
resource "azurerm_storage_account" "sa" {
  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  enable_https_traffic_only       = true
  tags                            = var.tags
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      var.vnet_integration_subnet_id
    ]
    ip_rules = [
      var.public_ip
    ]
    bypass = [
      "AzureServices"
    ]
  }
}

resource "azurerm_storage_share" "content_share" {
  name                 = var.storage_account_name
  storage_account_name = azurerm_storage_account.sa.name
  quota                = "10"
}

resource "azurerm_storage_share" "content_share_pre" {
  name                 = "${var.storage_account_name}-pre"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = "10"
}
