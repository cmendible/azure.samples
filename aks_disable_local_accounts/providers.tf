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
  config_path    = "~/.kube/config"
}

resource "null_resource" "sp_login" {
  provisioner "local-exec" {
    command = "az login --service-principal -u ${azuread_application.sp.application_id} -p ${random_password.passwd.result} --tenant ${data.azurerm_subscription.current.tenant_id} --allow-no-subscriptions"
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${var.resource_group} --overwrite-existing"
  }
  depends_on = [
    null_resource.sp_login
  ]
}

resource "null_resource" "kubelogin" {
  provisioner "local-exec" {
    command = "kubelogin convert-kubeconfig -l spn --client-id ${azuread_application.sp.application_id} --client-secret '${random_password.passwd.result}'"
  }
  depends_on = [
    null_resource.sp_login
  ]
}
