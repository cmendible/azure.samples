# Create the azureoperator-system namespace in k8s
resource "kubernetes_namespace" "azure-service-operator" {
  metadata {
    name = "azureoperator-system"
  }
}

# Create the cert-mnager namespace in k8s
resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

# Install the cert-manager helm chart version 0.12.0
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  version    = "0.12.0"
  namespace  = kubernetes_namespace.cert-manager.metadata.0.name
  repository = "https://charts.jetstack.io"
}

# Install the cert-managerazure-service-operator helm chart version 0.1.0
# azureOperatorKeyvault is used so secrets are saved by the operator in a Key Vault instead of using k8s secrets
resource "helm_release" "azure-service-operator" {
  name       = "aso"
  chart      = "azure-service-operator"
  version    = "0.1.0"
  namespace  = kubernetes_namespace.azure-service-operator.metadata.0.name
  repository = "https://github.com/Azure/azure-service-operator/raw/master/charts/"

  set {
    name  = "azureSubscriptionID"
    value = data.azurerm_subscription.current.subscription_id
  }

  set {
    name  = "azureTenantID"
    value = data.azurerm_subscription.current.tenant_id
  }

  set {
    name  = "azureClientID"
    value = azuread_application.sp.application_id
  }

  set {
    name  = "azureClientSecret"
    value = azuread_application_password.sp_password.value
  }

  set {
    name  = "azureOperatorKeyvault"
    value = azurerm_key_vault.kv.name
  }

  depends_on = [
    helm_release.cert-manager
  ]
}
