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

# Configuring the kubernetes provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)

  # Using kubelogin to get an AAD token for the cluster.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "kubelogin"
    args = [
      "get-token",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      data.azuread_service_principal.aks_aad_server.application_id, # Application Id of the Azure Kubernetes Service AAD Server.
      "--client-id",
      azuread_application.sp.application_id, // Application Id of the Service Principal we'll create via terraform.
      "--client-secret",
      random_password.passwd.result, // The Service Principal's secret.
      "-t",
      data.azurerm_subscription.current.tenant_id, // The AAD Tenant Id.
      "-l",
      "spn" // Login using a Service Principal..
    ]
  }
}