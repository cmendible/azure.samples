# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Create VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Subnet for AKS. This is the subnet where we'll enable Vnet Integration.
resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

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
    vnet_subnet_id  = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }
}

# Create Application registration for kubecost
resource "azuread_application" "kubecost" {
  display_name               = var.kubecost_sp_name
  identifier_uris            = ["http://${var.kubecost_sp_name}"]
}

# Create Service principal for kubecost
resource "azuread_service_principal" "kubecost" {
  application_id = azuread_application.kubecost.application_id
}

# Create Password
resource "random_password" "passwd" {
  length      = 32
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
   keepers = {
    aks_app_id = azuread_application.kubecost.id
  }
}

# Create kubecost's Service principal password
resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.kubecost.id
  value                = random_password.passwd.result
  end_date             = "2099-01-01T00:00:00Z"
}

# Get current Subscription
data "azurerm_subscription" "current" {
}

# Create kubecost custom role
resource "azurerm_role_definition" "kubecost" {
  name        = "kubecost_rate_card_query"
  scope       = data.azurerm_subscription.current.id
  description = "kubecost Rate Card query role"

  permissions {
    actions     = [
      "Microsoft.Compute/virtualMachines/vmSizes/read",
      "Microsoft.Resources/subscriptions/locations/read",
      "Microsoft.Resources/providers/read",
      "Microsoft.ContainerService/containerServices/read",
      "Microsoft.Commerce/RateCard/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

# Assign kubecost's custom role
resource "azurerm_role_assignment" "kubecost" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = azurerm_role_definition.kubecost.name
  principal_id         = azuread_service_principal.kubecost.object_id
}