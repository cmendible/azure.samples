output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.k8s.name
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.k8s.id
}

output "cluster_location" {
  description = "The location of the AKS cluster"
  value       = azurerm_kubernetes_cluster.k8s.location
}
