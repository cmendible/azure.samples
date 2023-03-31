# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Get current Subscription
data "azurerm_subscription" "current" {}

# Get current Client
data "azuread_client_config" "current" {}

# We'll need the Application Id of the Azure Kubernetes Service AAD Server.
data "azuread_service_principal" "aks_aad_server" {
  display_name = "Azure Kubernetes Service AAD Server"
}

# Create VNET for AKS
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Subnet for AKS.
resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

# Create the AKS cluster.
# Cause this is a test node_count is set to 1 
resource "azurerm_kubernetes_cluster" "aks" {
  name                   = var.aks_name
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  dns_prefix             = var.aks_name
  local_account_disabled = true

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
    os_disk_type    = "Ephemeral"
    vnet_subnet_id  = azurerm_subnet.aks.id
  }

  # Using Managed Identity
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = [
      azuread_group.aks_admins.object_id,
    ]
    azure_rbac_enabled = false
    managed            = true
    tenant_id          = data.azurerm_subscription.current.tenant_id
  }
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = "nolocalaccounts"
  }
}
