# Deploy Kubernetes
resource "azurerm_kubernetes_cluster" "k8s" {
  name                              = var.cluster_name
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  dns_prefix                        = var.dns_prefix
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true

  default_node_pool {
    name                 = "default"
    node_count           = 3
    vm_size              = "Standard_D2s_v3"
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

  workload_autoscaler_profile {
    keda_enabled = true
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

  sku_tier              = "Standard"
}

# Assign the Reader role to the Managed Identity
resource "azurerm_role_assignment" "reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}
