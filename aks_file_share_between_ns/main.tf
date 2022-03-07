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

# Create the Storage Account.
resource "azurerm_storage_account" "sa" {
  name                      = var.sa_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Premium"
  account_replication_type  = "LRS"
  account_kind              = "FileStorage"
  enable_https_traffic_only = true
  # We are enabling the firewall only allowing traffic from our PC's public IP.
  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = []
  }
}

resource "azurerm_storage_share" "share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.sa.name

  acl {
    id = "e084263c-58e4-413e-a98f-6b2a45f1c7c3"
    access_policy {
      permissions = "rwdl"
    }
  }
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
}

# Assign kubelet identity as SA Contributor 
resource "azurerm_role_assignment" "aks_kubelet_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}


resource "null_resource" "cluster_credentials" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${var.aks_name} -g ${var.resource_group} --overwrite-existing"
  }
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# Deploy Storage Class and sample PVC
resource "null_resource" "csi_storage_class_sample" {
  provisioner "local-exec" {
    command = "sed 's/<resourceGroup>/${var.resource_group}/;s/<storageAccountName>/${var.sa_name}/' storageclass-azurefile-csi.yaml | kubectl apply -f -"
  }

  depends_on = [
    azurerm_role_assignment.aks_kubelet_contributor,
    null_resource.cluster_credentials
  ]
}
