resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  resource_group_name  = "${var.resource_group}-${local.name_sufix}"
  storage_account_name = "${var.sa_name}${local.name_sufix}"
  function_name        = "${var.func_name}-${local.name_sufix}"
  func_code            = "./securecopy.zip"
  publish_code_command = "az webapp deployment source config-zip --resource-group ${local.resource_group_name} --name ${local.function_name} --src ${local.func_code}"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}
