# Create Managed Identity
resource "azurerm_user_assigned_identity" "mi" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = local.managed_identity_name
}

# Assign the Network Contributor role to the Managed Identity
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Assign the Network Contributor role to the Managed Identity
resource "azurerm_role_assignment" "network_contributor" {
  scope                = data.azurerm_resource_group.node_resource_group.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Assign the Virtual Machine Contributor role to the Managed Identity
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = local.vmss[0].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_federated_identity_credential" "federation" {
  name                = "aks-workload-identity"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.mi.id
  subject             = "system:serviceaccount:kube-egress-gateway-system:kube-egress-gateway-controller-manager"
}


