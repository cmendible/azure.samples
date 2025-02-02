# Create the azureoperator-system namespace in k8s
resource "kubernetes_namespace" "azure-service-operator" {
  metadata {
    name = "azureserviceoperator-system"
  }
}

# Create the cert-mnager namespace in k8s
resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

# Install the cert-manager helm chart
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  version    = "1.16.3"
  namespace  = kubernetes_namespace.cert-manager.metadata.0.name
  repository = "https://charts.jetstack.io"

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# Install the cert-managerazure-service-operator helm chart
resource "helm_release" "azure-service-operator" {
  name       = "aso"
  chart      = "azure-service-operator"
  version    = "2.11.0"
  namespace  = kubernetes_namespace.azure-service-operator.metadata.0.name
  repository = "https://raw.githubusercontent.com/Azure/azure-service-operator/refs/heads/main/v2/charts/"

  set {
    name  = "crdPattern"
    value = "*"
  }

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
    value = azurerm_user_assigned_identity.mi.client_id
  }

  set {
    name  = "useWorkloadIdentityAuth"
    value = "true"
  }

  depends_on = [
    helm_release.cert-manager
  ]
}
