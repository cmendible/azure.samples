# Create the "private" Storage Account.
resource "azurerm_storage_account" "sa" {
  name                      = local.storage_account_name
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
    bypass = ["None"]
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

resource "azurerm_storage_share" "content_share" {
  name                 = "func-pe-test-398e1aee"
  storage_account_name = azurerm_storage_account.sa.name
}

# Create the Private endpoint for each Storage Account Service. This is how the Storage account gets the private IPs inside the VNet.
resource "azurerm_private_endpoint" "endpoint" {
  count               = length(var.sa_services)
  name                = "sa-${var.sa_services[count.index]}-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "sa-${var.sa_services[count.index]}-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = [var.sa_services[count.index]]
  }

  private_dns_zone_group {
    name                 = "privatelink.${var.sa_services[count.index]}.core.windows.net"
    private_dns_zone_ids = [azurerm_private_dns_zone.private[count.index].id]
  }
}
