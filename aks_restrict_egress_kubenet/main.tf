# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Create the AKS cluster.
# Cause this is a test node_count is set to 1 
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_name

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
    os_disk_type    = "Ephemeral"
    vnet_subnet_id  = azurerm_subnet.aks_nodes.id
  }

  # Using Managed Identity
  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.mi.id
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.mi.client_id
    object_id                 = azurerm_user_assigned_identity.mi.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.mi.id
  }

  network_profile {
    # The --service-cidr is used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment, including any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connection.
    service_cidr = "172.0.0.0/16"
    # The --dns-service-ip address should be the .10 address of your service IP address range.
    dns_service_ip = "172.0.0.10"
    # The --docker-bridge-address lets the AKS nodes communicate with the underlying management platform. This IP address must not be within the virtual network IP address range of your cluster, and shouldn't overlap with other address ranges in use on your network.
    docker_bridge_cidr = "172.17.0.1/16"
    network_plugin     = "kubenet"
    outbound_type      = "userDefinedRouting"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }

  depends_on = [
    azurerm_firewall.firewall,
    azurerm_subnet_route_table_association.restrict,
    azurerm_virtual_network_peering.peer-vnet-hub-with-vnet,
    azurerm_virtual_network_peering.peer-vnet-vnet-with-hub
  ]
}

data "azurerm_resource_group" "node_resource_group" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
}

# Assign the Owner role to the AKS kubelet identity
resource "azurerm_role_assignment" "kubelet_rg_owner" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner" #"Virtual Machine Contributor"?
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Assign the Contributor role to the AKS kubelet identity
# resource "azurerm_role_assignment" "kubelet_contributor" {
#   scope                = data.azurerm_resource_group.node_resource_group.id
#   role_definition_name = "Contributor" #"Virtual Machine Contributor"?
#   principal_id         = azurerm_user_assigned_identity.mi.principal_id
# }

resource "azurerm_role_assignment" "kubelet_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_role_assignment" "kubelet_udr_contributor" {
  scope                = azurerm_route_table.restrict.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}