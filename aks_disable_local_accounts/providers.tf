terraform {
  required_version = ">= 0.13.5"
  required_providers {
    azurerm = {
      version = "= 2.97.0"
    }
    azuread = {
      version = "= 1.4.0"
    }
    kubernetes = {
      version = "= 2.8.0"
    }
  }
}

provider "azurerm" {
  features {}
}


data "azuread_service_principal" "aks_aad_server" {
  display_name = "Azure Kubernetes Service AAD Server"
}

# Configuring the kubernetes provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)

  # Using kubelogin to get an AAD token for the cluster.
  # server-id is a fixed value per tenant?
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "kubelogin"
    args = [
      "get-token",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      data.azuread_service_principal.aks_aad_server.application_id,
      "--client-id",
      azuread_application.sp.application_id,
      "--client-secret",
      random_password.passwd.result,
      "-t",
      data.azurerm_subscription.current.tenant_id,
      "-l",
      "spn"
    ]
  }
}
