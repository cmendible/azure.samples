resource "azurerm_resource_group" "rg" {
  name     = "testbatch"
  location = "West Europe"
}

resource "azurerm_storage_account" "sa" {
  name                     = "teststoragecfm"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_batch_account" "batch" {
  name                 = "testbatchaccount"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  pool_allocation_mode = "BatchService"
  storage_account_id   = azurerm_storage_account.sa.id
}

resource "azurerm_batch_pool" "pool" {
  name                = "ubuntu"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_batch_account.batch.name
  display_name        = "ubuntu"
  vm_size             = "Standard_d2s_v3"
  node_agent_sku_id   = "batch.node.ubuntu 20.04" #batch.node.centos 7

  fixed_scale {
    target_dedicated_nodes = 1
  }

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_batch_job" "job" {
  name          = "myJob"
  batch_pool_id = azurerm_batch_pool.pool.id
}
