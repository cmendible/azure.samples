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

  # Enable Application routing add-on with NGINX features
  web_app_routing {
    dns_zone_ids = []
  }

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
    os_disk_type    = "Ephemeral"
    vnet_subnet_id  = azurerm_subnet.aks_nodes.id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  # Using Managed Identity
  identity {
    type         = "SystemAssigned"
    identity_ids = []
  }

  network_profile {
    # The --service-cidr is used to assign internal services in the AKS cluster an IP address. This IP address range should be an address space that isn't in use elsewhere in your network environment, including any on-premises network ranges if you connect, or plan to connect, your Azure virtual networks using Express Route or a Site-to-Site VPN connection.
    service_cidr = "172.0.0.0/16"
    # The --dns-service-ip address should be the .10 address of your service IP address range.
    dns_service_ip      = "172.0.0.10"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "userDefinedRouting"
  }

  role_based_access_control_enabled = true

  depends_on = [
    azurerm_firewall.firewall,
    azurerm_firewall_policy_rule_collection_group.policies,
    azurerm_virtual_network_peering.peer-vnet-hub-with-vnet,
    azurerm_virtual_network_peering.peer-vnet-vnet-with-hub
  ]
}

data "dns_a_record_set" "aks" {
  host = azurerm_kubernetes_cluster.aks.fqdn
}

resource "azurerm_role_assignment" "kubelet_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "kubelet_network_reader" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}