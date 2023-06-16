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

locals {
  namespace = "kube-system"
  helm_release_name      = "agic"
}

resource "azurerm_federated_identity_credential" "federation" {
  name                = "aks-workload-identity"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.mi.id
  subject             = "system:serviceaccount:${local.namespace}:${local.helm_release_name}-sa-ingress-azure"
}
