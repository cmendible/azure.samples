resource "kubernetes_namespace" "kubecost" {
  metadata {
    name = "kubecost"
  }
}

resource "helm_release" "kubecost" {
  name       = "kubecost"
  chart      = "cost-analyzer"
  namespace  = "kubecost"
  version    = "1.79.1"
  repository = "https://kubecost.github.io/cost-analyzer/"
  
  set {
    name  = "kubecostProductConfigs.createServiceKeySecret"
    value = true
  }

  set {
    name  = "kubecostProductConfigs.azureSubscriptionID"
    value = data.azurerm_subscription.current.id
  }

  set {
    name  = "kubecostProductConfigs.azureClientID"
    value = azuread_application.kubecost.application_id
  }

  set {
    name  = "kubecostProductConfigs.azureClientPassword"
    value = random_password.passwd.result
  }

  set {
    name  = "kubecostProductConfigs.azureTenantID"
    value = data.azurerm_subscription.current.tenant_id
  }

  set {
    name  = "kubecostProductConfigs.clusterName"
    value = var.aks_name
  }

  set {
    name  = "kubecostProductConfigs.currencyCode"
    value = "EUR"
  }

  set {
    name  = "kubecostProductConfigs.azureBillingRegion"
    value = "NL"
  }
}