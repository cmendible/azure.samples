terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {}
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "aks-static-egress-gateway"
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "aks-static-egress-gateway"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "Spain Central"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  default_node_pool {
    name                         = "default"
    node_count                   = 1
    vm_size                      = "Standard_DS2_v2"
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_update_resource" "enable_static_egress_gateway" {
  type                    = "Microsoft.ContainerService/managedClusters@2024-09-02-preview"
  resource_id             = azurerm_kubernetes_cluster.k8s.id
  ignore_missing_property = true
  body = {
    properties = {
      networkProfile = {
        staticEgressGatewayProfile = {
          enabled = true
        }
      }
    }
  }
}

resource "azapi_resource" "gateway_node_pool" {
  type      = "Microsoft.ContainerService/managedClusters/agentPools@2024-09-02-preview"
  parent_id = azurerm_kubernetes_cluster.k8s.id
  name      = "gatewaypool"

  body = {
    properties = {
      mode              = "Gateway"
      osType            = "Linux"
      vmSize            = "Standard_DS2_v2"
      count             = 2
      enableAutoScaling = false
      gatewayProfile = {
        publicIPPrefixSize = 31
      },
    }
  }
  depends_on = [azapi_update_resource.enable_static_egress_gateway]
}

resource "kubectl_manifest" "static_gateway_configuration" {
  yaml_body = <<YAML
    apiVersion: egressgateway.kubernetes.azure.com/v1alpha1
    kind: StaticGatewayConfiguration
    metadata:
      name: static-ip-gateway
      namespace: default
    spec:
      gatewayNodepoolName: ${azapi_resource.gateway_node_pool.name}
      provisionPublicIps: false
      excludeCidrs: 
      - ${azurerm_kubernetes_cluster.k8s.network_profile[0].pod_cidr}
      - ${azurerm_kubernetes_cluster.k8s.network_profile[0].service_cidr}
      - 169.254.169.254/32
    YAML
  depends_on = [
    azapi_update_resource.enable_static_egress_gateway,
    azapi_resource.gateway_node_pool
  ]
}
