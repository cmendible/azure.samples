resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}"
  location = var.location
}

# --- Networking ---

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "batch" {
  name                 = "snet-batch"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- Storage (for start task script) ---

resource "azurerm_storage_account" "this" {
  name                            = replace("st${var.prefix}", "-", "")
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "scripts" {
  name               = "scripts"
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_storage_blob" "start_task" {
  name                   = "start-task.sh"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/start-task.sh"
}

data "azurerm_storage_account_sas" "this" {
  connection_string = azurerm_storage_account.this.primary_connection_string
  https_only        = true
  start             = timestamp()
  expiry            = timeadd(timestamp(), "8760h") # 1 year

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# --- Batch Account ---

resource "azurerm_batch_account" "this" {
  name                                = replace("ba${var.prefix}", "-", "")
  location                            = azurerm_resource_group.this.location
  resource_group_name                 = azurerm_resource_group.this.name
  pool_allocation_mode                = "BatchService"
  storage_account_id                  = azurerm_storage_account.this.id
  storage_account_authentication_mode = "StorageKeys"
}

# --- Batch Pool with AlmaLinux + Moby ---

resource "azurerm_batch_pool" "this" {
  name                = "alma-pool"
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_batch_account.this.name
  vm_size             = var.batch_pool_vm_size
  node_agent_sku_id   = "batch.node.el 9"
  display_name        = "AlmaLinux Docker Pool"

  fixed_scale {
    target_dedicated_nodes = var.batch_pool_node_count
  }

  storage_image_reference {
    publisher = "almalinux"
    offer     = "almalinux-x86_64"
    sku       = "9-gen2"
    version   = "latest"
  }

  container_configuration {
    type = "DockerCompatible"
  }

  network_configuration {
    subnet_id = azurerm_subnet.batch.id
  }

  start_task {
    command_line       = "bash -c 'chmod +x start-task.sh && ./start-task.sh'"
    wait_for_success   = true
    task_retry_maximum = 3
    user_identity {
      auto_user {
        elevation_level = "Admin"
        scope           = "Pool"
      }
    }

    resource_file {
      http_url  = "${azurerm_storage_blob.start_task.url}${data.azurerm_storage_account_sas.this.sas}"
      file_path = "start-task.sh"
    }
  }
}

# --- Test Job that runs a Docker container ---

resource "azurerm_batch_job" "test" {
  name          = "test-docker-job"
  batch_pool_id = azurerm_batch_pool.this.id
}

resource "null_resource" "test_task" {
  depends_on = [azurerm_batch_job.test]

  provisioner "local-exec" {
    command = <<-EOT
      az batch task create \
        --job-id "test-docker-job" \
        --json-file ${path.module}/test-task.json \
        --account-name ${azurerm_batch_account.this.name} \
        --account-endpoint ${azurerm_batch_account.this.account_endpoint}
    EOT
  }
}

resource "null_resource" "test_container_task" {
  depends_on = [azurerm_batch_job.test]

  provisioner "local-exec" {
    command = <<-EOT
      az batch task create \
        --job-id "test-docker-job" \
        --json-file ${path.module}/test-container-task.json \
        --account-name ${azurerm_batch_account.this.name} \
        --account-endpoint ${azurerm_batch_account.this.account_endpoint}
    EOT
  }
}
