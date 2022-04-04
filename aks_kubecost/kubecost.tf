# Create the kubecost namespace
resource "kubernetes_namespace" "kubecost" {
  metadata {
    name = "kubecost"
  }
}

# Install kubecost using the hem chart
resource "helm_release" "kubecost" {
  name       = "kubecost"
  chart      = "cost-analyzer"
  namespace  = "kubecost"
  version    = "1.91.2"
  repository = "https://kubecost.github.io/cost-analyzer/"

  # Set the cluster name
  set {
    name  = "kubecostProductConfigs.clusterName"
    value = var.aks_name
  }

  # Set the currency
  set {
    name  = "kubecostProductConfigs.currencyCode"
    value = "EUR"
  }

  # Set the region
  set {
    name  = "kubecostProductConfigs.azureBillingRegion"
    value = "NL"
  }
  
  # Generate a secret based on the Azure configuration provided below
  set {
    name  = "kubecostProductConfigs.createServiceKeySecret"
    value = true
  }

  # Azure Subscription ID
  set {
    name  = "kubecostProductConfigs.azureSubscriptionID"
    value = data.azurerm_subscription.current.subscription_id
  }

  # Azure Client ID
  set {
    name  = "kubecostProductConfigs.azureClientID"
    value = azuread_application.kubecost.application_id
  }

  # Azure Client Password
  set {
    name  = "kubecostProductConfigs.azureClientPassword"
    value = random_password.passwd.result
  }

  # Azure Tenant ID
  set {
    name  = "kubecostProductConfigs.azureTenantID"
    value = data.azurerm_subscription.current.tenant_id
  }
}