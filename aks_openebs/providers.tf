terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 2.57.0"
    }
    kubernetes = {
      version = "= 2.1.0"
    }
    helm = {
      version = "= 2.1.2"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configuring the kubernetes provider
# AKS resource name is aks: azurerm_kubernetes_cluster.aks
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# Configuring the helm provider
# AKS resource name is aks: azurerm_kubernetes_cluster.aks
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}
