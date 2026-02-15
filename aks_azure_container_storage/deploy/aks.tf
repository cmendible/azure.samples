# Deploy Kubernetes
resource "azurerm_kubernetes_cluster" "k8s" {
  name                              = var.cluster_name
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  dns_prefix                        = var.dns_prefix
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"

  default_node_pool {
    name                 = "default"
    node_count           = 3
    vm_size              = "Standard_L8s_v3" #Local NVMe disks are only available: storage-optimized VMs or GPU accelerated VMs
    os_disk_size_gb      = 30
    os_disk_type         = "Ephemeral"
    vnet_subnet_id       = azurerm_subnet.aks-subnet.id
    max_pods             = 30
    min_count            = 3
    max_count            = 6
    auto_scaling_enabled = true
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
    # The --service-cidr is used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment, including any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connection.
    service_cidr = "172.0.0.0/16"
    # The --dns-service-ip address should be the .10 address of your service IP address range.
    dns_service_ip      = "172.0.0.10"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
  }

}

// Deploy Azure Container Storage extension for AKS
resource "azurerm_kubernetes_cluster_extension" "container_storage" {
  name           = "acstor" # NOTE: the `name` parameter must be "acstor" for Azure CLI compatibility
  cluster_id     = azurerm_kubernetes_cluster.k8s.id
  extension_type = "microsoft.azurecontainerstoragev2"
}

// Create a StorageClass for Azure Container Storage
resource "kubernetes_storage_class_v1" "local" {
  metadata {
    name = "local"
  }

  depends_on = [azurerm_kubernetes_cluster_extension.container_storage]

  storage_provisioner    = "localdisk.csi.acstor.io"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}
