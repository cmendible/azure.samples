resource "azurerm_storage_account" "sa" {
  name                            = var.sa_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  # We are enabling the firewall only allowing traffic from our PC's public IP.
  #   network_rules {
  #     default_action             = "Deny"
  #     virtual_network_subnet_ids = []
  #     ip_rules = [
  #       jsondecode(data.http.current_public_ip.body).ip
  #     ]
  #   }
}

# Create data container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.sa.name
}
