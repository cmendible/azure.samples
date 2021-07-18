# Deploy Kubernetes
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name                = "default"
    node_count          = 2
    vm_size             = "Standard_D2s_v3"
    os_disk_size_gb     = 30
    os_disk_type        = "Ephemeral"
    vnet_subnet_id      = azurerm_subnet.aks-subnet.id
    max_pods            = 15
    enable_auto_scaling = false
  }

  # Using Managed Identity
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    # The --service-cidr is used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment, including any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connection.
    service_cidr = "172.0.0.0/16"
    # The --dns-service-ip address should be the .10 address of your service IP address range.
    dns_service_ip = "172.0.0.10"
    # The --docker-bridge-address lets the AKS nodes communicate with the underlying management platform. This IP address must not be within the virtual network IP address range of your cluster, and shouldn't overlap with other address ranges in use on your network.
    docker_bridge_cidr = "172.17.0.1/16"
    network_plugin     = "azure"
    network_policy     = "calico"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "linux_spot" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  name                  = "lin"
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1 # note: this is the "maximum" price
  os_type               = "Linux"
  # "The virtual machine size Standard_D2s_v3 has a cache size of 53687091200 bytes, but the OS disk requires 137438953472 bytes. Use a VM size with larger cache or disable ephemeral OS."
  # https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks#size-requirements
  vm_size             = "Standard_DS3_v2"
  os_disk_type        = "Ephemeral"
  node_count          = 0
  enable_auto_scaling = true
  max_count           = 3
  min_count           = 0
}

data "azurerm_resource_group" "node_resource_group" {
  name = azurerm_kubernetes_cluster.k8s.node_resource_group
}

# Assign the Contributor role to the AKS kubelet identity
resource "azurerm_role_assignment" "kubelet_contributor" {
  scope                = data.azurerm_resource_group.node_resource_group.id
  role_definition_name = "Contributor" #"Virtual Machine Contributor"?
  principal_id         = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "kubelet_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}
