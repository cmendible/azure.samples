resource "azurerm_batch_account" "batch" {
  name                 = "testbatchaccountcfm"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  pool_allocation_mode = "UserSubscription"
  storage_account_id   = azurerm_storage_account.sa.id
  key_vault_reference {
    id  = azurerm_key_vault.kv.id
    url = azurerm_key_vault.kv.vault_uri
  }

  depends_on = [
    azurerm_role_assignment.microsoft_azure_batch
  ]
}

resource "azurerm_batch_pool" "ubuntu_pool" {
  name                = "ubuntu"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_batch_account.batch.name
  display_name        = "ubuntu"
  vm_size             = "Standard_d2s_v3"
  node_agent_sku_id   = "batch.node.ubuntu 20.04"

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

resource "azurerm_batch_pool" "redhat_pool" {
  name                = "redhat"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_batch_account.batch.name
  display_name        = "redhat"
  vm_size             = "Standard_d2s_v3"
  node_agent_sku_id   = "batch.node.el 8"

  fixed_scale {
    target_dedicated_nodes = 1
  }

  storage_image_reference {
    publisher = "redhat"
    offer     = "rhel"
    sku       = "82gen2"
    version   = "latest"
  }
}

resource "azurerm_batch_job" "job" {
  name          = "myJob"
  batch_pool_id = azurerm_batch_pool.redhat_pool.id
}
