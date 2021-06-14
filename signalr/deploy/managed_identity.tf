
# Create Managed Identity
resource "azurerm_user_assigned_identity" "mi" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = var.managed_identity_name
}

# Assign the Reader role to the Managed Identity
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Assign the Managed Identity Operator role to the AKS Service Principal
resource "azurerm_role_assignment" "mi_operator" {
  scope                = azurerm_user_assigned_identity.mi.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
}