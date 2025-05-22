output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.mi.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "kv_name" {
  value = azurerm_key_vault.kv.name
}
