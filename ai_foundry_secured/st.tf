# Create an Azure Storage Account
resource "azurerm_storage_account" "st" {
  name                          = var.storage_account_name           # Storage account name
  location                      = azurerm_resource_group.rg.location # Location from the resource group
  resource_group_name           = azurerm_resource_group.rg.name     # Resource group name
  account_tier                  = "Standard"                         # Performance tier
  account_replication_type      = "LRS"                              # Locally-redundant storage replication
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices"
    ]
    ip_rules = [
      data.http.current_public_ip.response_body
    ]
  }
}

resource "azurerm_role_assignment" "hub_sta_connection_approver" {
  scope                = azurerm_storage_account.st.id # Scope of the role assignment
  role_definition_name = "Azure AI Enterprise Network Connection Approver"
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_sta_contributor" {
  scope                = azurerm_storage_account.st.id                                   # Scope of the role assignment
  role_definition_name = "Contributor"                                                   # Role definition name for contributor
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

resource "azurerm_role_assignment" "hub_sta_blob_data_contributor" {
  scope                = azurerm_storage_account.st.id                                   # Scope of the role assignment
  role_definition_name = "Storage Blob Data Contributor"                                 # Role definition name for contributor
  principal_id         = azurerm_user_assigned_identity.ai_foundry_identity.principal_id # Principal ID of the user-assigned identity
}

# Create the Private endpoint. This is where the Storage account gets a private IP inside the VNet.sur
resource "azurerm_private_endpoint" "endpoint" {
  name                = "sa-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "sa-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatelink-sta"
    private_dns_zone_ids = [azurerm_private_dns_zone.sta.id]
  }
}

resource "azurerm_private_dns_zone" "sta" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa" {
  name                  = "sta"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sta.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_endpoint" "table_endpoint" {
  name                = "table-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "table-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "privatelink-table"
    private_dns_zone_ids = [azurerm_private_dns_zone.table_sta.id]
  }
}

resource "azurerm_private_dns_zone" "table_sta" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "table_sa" {
  name                  = "table"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.table_sta.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_endpoint" "queue_endpoint" {
  name                = "queue-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "queue-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name                 = "privatelink-queue"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue_sta.id]
  }
}

resource "azurerm_private_dns_zone" "queue_sta" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "queue_sa" {
  name                  = "queue"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queue_sta.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_endpoint" "file_endpoint" {
  name                = "file-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "file-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.st.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "privatelink-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.file_sta.id]
  }
}

resource "azurerm_private_dns_zone" "file_sta" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "file_sa" {
  name                  = "file"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file_sta.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}
