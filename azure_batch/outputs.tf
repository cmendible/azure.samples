output "batch_url" {
  value = "https://${azurerm_batch_account.batch.account_endpoint}"
}

output "batch_accountName" {
  value = azurerm_batch_account.batch.name
}

output "batch_key" {
  value = azurerm_batch_account.batch.primary_access_key
  sensitive = true
}

output "storage_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_key" {
  value = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}
