output "host" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.host
}

output "mi_id" {
  value     = azurerm_user_assigned_identity.mi.id
  sensitive = true
}

output "mi_client_id" {
  value     = azurerm_user_assigned_identity.mi.client_id
  sensitive = true
}

