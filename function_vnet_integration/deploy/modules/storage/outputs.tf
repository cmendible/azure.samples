output "name" {
  value = azurerm_storage_account.sa.name
}

output "primary_access_key" {
  value = azurerm_storage_account.sa.primary_access_key
}

output "primary_connection_string" {
  value = azurerm_storage_account.sa.primary_connection_string
}

output "content_share_name" {
  value = azurerm_storage_share.content_share.name
}
