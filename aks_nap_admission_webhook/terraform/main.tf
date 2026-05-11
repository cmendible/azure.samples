# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# AKS Cluster with Node Auto Provisioning (NAP)
#
# NAP requires:
#   - network_plugin = "azure" or "none"  (azure CNI recommended)
#   - network_policy = "cilium" and network_data_plane = "cilium"
#   - node_provisioning_profile { mode = "Auto" }
#   - The system node pool must have only_critical_addons_enabled = true
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # System node pool — runs only cluster-critical addons.
  # NAP provisions additional node pools on demand.
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool_vm_size
    node_count                   = var.system_node_pool_count
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # Enable Node Auto Provisioning.
  node_provisioning_profile {
    mode = "Auto"
  }

  # Managed identity for the control plane.
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI + Cilium data plane (required for NAP).
  network_profile {
    network_plugin     = "azure"
    network_policy     = "cilium"
    network_data_plane = "cilium"
    load_balancer_sku  = "standard"
  }

  # Enable OIDC issuer and Workload Identity.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Azure Container Registry
# ---------------------------------------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

# Grant the AKS kubelet identity AcrPull so nodes can pull images without
# storing registry credentials as Kubernetes secrets.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# ---------------------------------------------------------------------------
# cert-manager (via Helm)
#
# Installs cert-manager from the Jetstack Helm repository.
# CRDs are installed as part of the release.
# ---------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}
