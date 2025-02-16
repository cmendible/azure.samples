variable "resource_group_name" {
  default = "rg-chaos-mesh-demo"
}

variable "location" {
  default = "spaincentral"
}

variable "cluster_name" {
  default = "aks-chaos-mesh"
}

variable "dns_prefix" {
  default = "aks-chaos-mesh"
}

#  Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aks-chaos-mesh"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks-subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Deploy Kubernetes
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true

  # Enable Application routing add-on with NGINX features
  web_app_routing {
    dns_zone_ids = []
  }

  default_node_pool {
    name                 = "default"
    node_count           = 3
    vm_size              = "Standard_D2s_v3"
    os_disk_size_gb      = 30
    os_disk_type         = "Ephemeral"
    vnet_subnet_id       = azurerm_subnet.aks-subnet.id
    max_pods             = 15
    auto_scaling_enabled = false

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  # Using Managed Identity
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    service_cidr        = "172.0.0.0/16"
    dns_service_ip      = "172.0.0.10"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
  }
}

resource "azurerm_role_assignment" "kubelet_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

resource "azurerm_role_assignment" "kubelet_network_reader" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}

# Install the chaos helm chart
resource "helm_release" "chaos" {
  create_namespace = true
  name             = "chaos-mesh"
  chart            = "chaos-mesh"
  namespace        = "chaos-testing"
  repository       = "https://charts.chaos-mesh.org"

  set {
    name  = "chaosDaemon.runtime"
    value = "containerd"
  }

  set {
    name  = "chaosDaemon.socketPath"
    value = "/run/containerd/containerd.sock"
  }

  # Enable FilterNamespace
  # Annotate namespaces to enable chaos experiments: kubectl annotate ns $NAMESPACE chaos-mesh.org/inject=enabled
  # https://chaos-mesh.org/docs/configure-enabled-namespace/#enable-filternamespace
  set {
    name  = "controllerManager.enableFilterNamespace"
    value = "true"
  }
}
