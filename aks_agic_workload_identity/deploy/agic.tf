# Install agic using the hem chart
resource "helm_release" "agic" {
  name       = local.helm_release_name
  chart      = "ingress-azure"
  namespace  = local.namespace
  version    = "1.7.1"
  repository = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"

  set {
    name  = "verbosityLevel"
    value = "3"
  }

  set {
    name  = "appgw.subscriptionId"
    value = data.azurerm_client_config.current.subscription_id
  }

  set {
    name  = "appgw.resourceGroup"
    value = azurerm_resource_group.rg.name
  }

  set {
    name  = "appgw.name"
    value = azurerm_application_gateway.gateway.name
  }

  set {
    name  = "appgw.usePrivateIP"
    value = "false"
  }

  set {
    name  = "appgw.shared"
    value = "false"
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }

  set {
    name  = "armAuth.type"
    value = "workloadIdentity"
  }

  set {
    name  = "armAuth.identityClientID"
    value = azurerm_user_assigned_identity.mi.client_id
  }

  depends_on = [azurerm_federated_identity_credential.federation]
}
