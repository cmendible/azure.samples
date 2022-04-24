resource "azurerm_resource_group" "rg" {
  name     = "azdo_demo"
  location = "West Europe"
}

# resource "azurerm_app_service_plan" "dev" {
#   name                = "__appserviceplan__"
#   location            = azurerm_resource_group.dev.location
#   resource_group_name = azurerm_resource_group.dev.name

#   sku {
#     tier = "Free"
#     size = "F1"
#   }
# }

# resource "azurerm_app_service" "dev" {
#   name                = "__appservicename__"
#   location            = azurerm_resource_group.dev.location
#   resource_group_name = azurerm_resource_group.dev.name
#   app_service_plan_id = azurerm_app_service_plan.dev.id

# }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "demo-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "demo-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}

resource "azurerm_container_registry" "acr" {
  name                = "demok8s"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
