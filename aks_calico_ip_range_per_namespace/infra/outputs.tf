// resource group name
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

// cluster name
output "cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}