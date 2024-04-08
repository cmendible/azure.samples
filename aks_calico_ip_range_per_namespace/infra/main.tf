data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "random_id" "random" {
  byte_length = 8
}

locals {
  sufix                 = substr(lower(random_id.random.hex), 1, 4)
  name_sufix            = "-${local.sufix}"
  resource_group_name   = "${var.resource_group_name}${local.name_sufix}"
  cluster_name          = "${var.cluster_name}${local.name_sufix}"
  dns_prefix            = "${var.dns_prefix}${local.name_sufix}"
  log_workspace_name    = "${var.log_workspace_name}${local.name_sufix}"
  vnetName              = "vnet-aks${local.name_sufix}"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}
