output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_container_name" {
  value = azurerm_storage_container.content.name
}

output "connection_string" {
  value = azurerm_storage_account.sa.primary_connection_string
}