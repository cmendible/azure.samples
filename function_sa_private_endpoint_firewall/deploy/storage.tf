
# Create the "private" Storage Account.
resource "azurerm_storage_account" "sa" {
  name                      = var.sa_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  # We are enabling the firewall only allowing traffic from our PC's public IP.
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = []
    ip_rules = [
      jsondecode(data.http.current_public_ip.body).ip
    ]
  }
}

# Create input container
resource "azurerm_storage_container" "input" {
  name                  = "input"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}

# Create output container
resource "azurerm_storage_container" "output" {
  name                  = "output"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}

# Create the Storage Account required by Azure Functions.
resource "azurerm_storage_account" "function_required_sa" {
  name                      = var.function_required_sa
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true

  # We are enabling the firewall only allowing traffic from service subnet.
  # Set sa_firewall_enabled to true in a second deployment!
  network_rules {
    default_action             = var.sa_firewall_enabled ? "Deny" : "Allow"
    virtual_network_subnet_ids = var.sa_firewall_enabled ? [azurerm_subnet.service.id] : []
    ip_rules                   = var.sa_firewall_enabled ? [jsondecode(data.http.current_public_ip.body).ip] : []
  }
}

# Create a container to hold the Azure Function Zip
resource "azurerm_storage_container" "functions" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.function_required_sa.name
  container_access_type = "private"
}

# Create a blob with the Azure Function zip
resource "azurerm_storage_blob" "function" {
  name                   = "securecopy.zip"
  storage_account_name   = azurerm_storage_account.function_required_sa.name
  storage_container_name = azurerm_storage_container.functions.name
  type                   = "Block"
  source                 = "./securecopy.zip"
}

# Create a SAS token so the Function can access the blob and deploy the zip
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.function_required_sa.primary_connection_string
  https_only        = false
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
  start  = "2020-10-07"
  expiry = "2025-05-18"
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}
