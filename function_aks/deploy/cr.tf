resource "azurerm_container_registry" "cr" {
  name                = "craksfunc"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.cr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
