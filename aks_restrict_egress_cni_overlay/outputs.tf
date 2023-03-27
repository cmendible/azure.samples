output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "firewal_public_ip" {
  value = azurerm_public_ip.firewall_public_ip.ip_address
}
