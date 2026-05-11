output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster."
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS API server."
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "get_credentials_command" {
  description = "az CLI command to fetch kubeconfig for this cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL (used for Workload Identity federation)."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "acr_login_server" {
  description = "Login server hostname for the container registry."
  value       = azurerm_container_registry.main.login_server
}

output "docker_build_push_commands" {
  description = "Commands to build and push the webhook image to ACR."
  value       = <<-EOT
    az acr login --name ${azurerm_container_registry.main.name}
    docker build -t ${azurerm_container_registry.main.login_server}/pv-zone-fix-webhook:latest .
    docker push ${azurerm_container_registry.main.login_server}/pv-zone-fix-webhook:latest
  EOT
}
