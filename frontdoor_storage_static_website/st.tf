# Storage Account with Static Website
resource "azurerm_storage_account" "sa" {
  name                       = "privatestorageacct"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
}

resource "azurerm_storage_account_static_website" "static" {
  storage_account_id = azurerm_storage_account.sa.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_storage_blob" "page" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "index.html"
  content_type           = "text/html"
}

# Private Endpoint
resource "azurerm_private_endpoint" "pe" {
  name                = "storage-private-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "storage-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["web"]
  }

  private_dns_zone_group {
    name                 = "privatelink-st"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns.id]
  }
}

resource "azurerm_private_dns_zone" "dns" {
  name                = "privatelink.web.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink" {
  name                  = "dnslink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
