# Get current subscription
data "azurerm_subscription" "current" {}

# Get current client
data "azurerm_client_config" "current" {}

# Get the Resource Group where the k8s cluster is deployed.
data "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
}

# Get the k8s cluster configuration info.
data "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}
