# Deploy Kubernetes
resource "azurerm_kubernetes_cluster" "k8s" {
  name                              = local.cluster_name
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  dns_prefix                        = local.dns_prefix
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }

  default_node_pool {
    name                = "default"
    node_count          = 2
    vm_size             = "Standard_D2s_v3"
    os_disk_size_gb     = 30
    os_disk_type        = "Ephemeral"
    vnet_subnet_id      = azurerm_subnet.aks-subnet.id
    max_pods            = 15
    enable_auto_scaling = false
    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Using Managed Identity
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    pod_cidr = "192.168.0.0/16"
    # The --service-cidr is used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment, including any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connection.
    service_cidr = "172.0.0.0/16"
    # The --dns-service-ip address should be the .10 address of your service IP address range.
    dns_service_ip      = "172.0.0.10"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }
}

// deploy new node pool
resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  name                  = "gwnodepool"
  vm_size               = "Standard_D2s_v3"
  node_count            = 1
  os_disk_size_gb       = 30
  os_type               = "Linux"
  vnet_subnet_id        = azurerm_subnet.aks-subnet.id
  max_pods              = 15
  enable_auto_scaling   = false
  node_labels = {
    "node.kubernetes.io/exclude-from-external-load-balancers" = "true"
    "kubeegressgateway.azure.com/mode"                        = "true"
  }
  node_taints = [
    "kubeegressgateway.azure.com/mode=true:NoSchedule"
  ]
}

#helm release
resource "helm_release" "egressgateway" {
  name             = "kube-egress-gateway"
  repository       = "./helm"
  chart            = "kube-egress-gateway"
  namespace        = "kube-egress-gateway-system"
  create_namespace = true

  set {
    name  = "common.imageRepository"
    value = "mcr.microsoft.com/aks"
  }

  set {
    name  = "common.imageTag"
    value = "v0.0.10"
  }

  values = [
    <<EOF
    config:
      azureCloudConfig:
        cloud: "AzurePublicCloud"
        tenantId: "${data.azurerm_subscription.current.tenant_id}"
        subscriptionId: "${data.azurerm_subscription.current.subscription_id}"
        useManagedIdentityExtension: true
        userAssignedIdentityID: "${azurerm_user_assigned_identity.mi.client_id}"
        userAgent: "kube-egress-gateway-controller"
        resourceGroup: "${azurerm_kubernetes_cluster.k8s.node_resource_group}"
        location: "${var.location}"
        gatewayLoadBalancerName: "kubeegressgateway-ilb"
        loadBalancerResourceGroup: "${azurerm_resource_group.rg.name}"
        vnetName: "${azurerm_virtual_network.vnet.name}"
        vnetResourceGroup: "${azurerm_resource_group.rg.name}"
        subnetName: "${azurerm_subnet.aks-subnet.name}"
    EOF
  ]

  depends_on = [azurerm_kubernetes_cluster_node_pool.node_pool]
}

data "azurerm_resource_group" "node_resource_group" {
  name = azurerm_kubernetes_cluster.k8s.node_resource_group
}

data "azurerm_resources" "vmss" {
  type                = "Microsoft.Compute/virtualMachineScaleSets"
  resource_group_name = azurerm_kubernetes_cluster.k8s.node_resource_group
  depends_on          = [azurerm_kubernetes_cluster_node_pool.node_pool]
}

locals {
  vmss = [for r in data.azurerm_resources.vmss.resources : r if can(regex("gwnodepool", r.name))]
}

# kubernets manifest for static gateway configuration
resource "kubectl_manifest" "static_gateway_configuration" {
  yaml_body  = <<YAML
    apiVersion: egressgateway.kubernetes.azure.com/v1alpha1
    kind: StaticGatewayConfiguration
    metadata:
      name: static-egress-gateway-default
      namespace: default
    spec:
      gatewayVmssProfile:
        vmssResourceGroup: ${azurerm_kubernetes_cluster.k8s.node_resource_group}
        vmssName: ${local.vmss[0].name}
        publicIpPrefixSize: 31
      provisionPublicIps: false
      defaultRoute: staticEgressGateway
      excludeCidrs:
        - ${azurerm_kubernetes_cluster.k8s.network_profile[0].service_cidr}
        - ${azurerm_kubernetes_cluster.k8s.network_profile[0].pod_cidr}
    YAML
  depends_on = [helm_release.egressgateway]
}
