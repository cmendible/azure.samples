output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group containing the AKS cluster."
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = "AKS cluster name."
}

output "cluster_id" {
  value       = azurerm_kubernetes_cluster.main.id
  description = "AKS cluster resource ID."
}

output "kube_config_command" {
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
  description = "Run this command to merge the cluster credentials into your kubeconfig."
}
