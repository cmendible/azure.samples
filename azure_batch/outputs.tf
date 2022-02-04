output "batch_url" {
  value = "https://${azurerm_batch_account.batch.account_endpoint}"
}

output "batch_accountName" {
  value = azurerm_batch_account.batch.name
}

output "storage_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_key" {
  value     = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}

output "client_id" {
  value = azuread_application.sp.application_id
}

output "client_secret" {
  value     = azuread_service_principal_password.password.value
  sensitive = true
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
