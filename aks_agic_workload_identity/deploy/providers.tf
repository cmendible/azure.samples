terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.44.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.0"
    }
  }
}

terraform {
  required_version = ">= 1.1.8"
}

provider "azurerm" {
  features {}
}

# Configuring the kubernetes provider
# AKS resource name is aks: azurerm_kubernetes_cluster.aks
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

# Configuring the helm provider
# AKS resource name is aks: azurerm_kubernetes_cluster.aks
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k8s.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
  }
}