terraform {
  required_version = "> 0.12"
}

provider "azurerm" {
  version = "~> 2.26"
  features {}
}

provider "azuread" {
  version = "~> 1.0"
}

provider "kubernetes" {
  version = "~> 1.13.1"

  load_config_file       = false
  host                   = data.azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  version = "~> 1.3.0"

  kubernetes {
    load_config_file = false

    username = data.azurerm_kubernetes_cluster.k8s.kube_config.0.username
    password = data.azurerm_kubernetes_cluster.k8s.kube_config.0.password

    host                   = data.azurerm_kubernetes_cluster.k8s.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
  }
}
