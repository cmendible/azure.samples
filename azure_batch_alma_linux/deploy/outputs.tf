output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "batch_account_name" {
  value = azurerm_batch_account.this.name
}

output "batch_pool_name" {
  value = azurerm_batch_pool.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}
