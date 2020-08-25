# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Create VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "private-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # Use Private DNS Zone. That's right we have to add this magical IP here.
  dns_servers = ["168.63.129.16"]
}

# Create the Subnet for the Azure Function. This is thge subnet where we'll enable Vnet Integration.
resource "azurerm_subnet" "service" {
  name                 = "service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_service_network_policies = true

  # Delegate the subnet to "Microsoft.Web/serverFarms"
  delegation {
    name = "acctestdelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create the Subnet for the private endpoints. This is where the IP of the private enpoint will live.
resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

# Get current public IP. We'll need this so we can access the Storage Account from our PC.
data "http" "current_public_ip" {
  url = "http://ipinfo.io/json"
  request_headers = {
    Accept = "application/json"
  }
}

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
    default_action             = var.sa_firewall_enabled ? "Deny" : "Allow"
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
}

# Create the blob.core.windows.net Private DNS Zone
resource "azurerm_private_dns_zone" "private" {
  name                = "core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create an A record pointing to each Storage Account service private endpoint
resource "azurerm_private_dns_a_record" "sa" {
  count               = length(var.sa_services)
  name                = "${var.sa_name}.${var.sa_services[count.index]}"
  zone_name           = azurerm_private_dns_zone.private.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.endpoint[count.index].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "sa_privatelink" {
  count               = length(var.sa_services)
  name                = "${var.sa_name}.privatelink.${var.sa_services[count.index]}"
  zone_name           = azurerm_private_dns_zone.private.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.endpoint[count.index].private_service_connection[0].private_ip_address]
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa" {
  name                  = "test"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Create a container to hold the Azure Function Zip
resource "azurerm_storage_container" "functions" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Create a blob with the Azure Function zip
resource "azurerm_storage_blob" "function" {
  name                   = "securecopy.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.functions.name
  type                   = "Block"
  source                 = "./securecopy.zip"
}

# Create a SAS token so the Function can access the blob and deploy the zip
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
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
  start  = "2020-08-25"
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

# Create the Azure Function plan (Elastic Premium) 
resource "azurerm_app_service_plan" "plan" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  kind = "elastic"
  sku {
    tier     = "ElasticPremium"
    size     = "EP1"
    capacity = 1
  }
}

# Create Application Insights
resource "azurerm_application_insights" "ai" {
  name                = "func-pe-test"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90
}

# Create the Azure Function App
resource "azurerm_function_app" "func_app" {
  name                       = "func-pe-test"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~3"

  app_settings = {
    https_only                     = true
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key
    privatecfm_STORAGE             = azurerm_storage_account.sa.primary_connection_string
    # With this setting we'll force all outbound traffic through the VNet
    WEBSITE_VNET_ROUTE_ALL = "1"
    # WEBSITE_DNS_SERVER     = "168.63.129.16"
    # Properties used to deploy the zip
    HASH            = filesha256("./securecopy.zip")
    WEBSITE_USE_ZIP = "https://${azurerm_storage_account.sa.name}.blob.core.windows.net/${azurerm_storage_container.functions.name}/${azurerm_storage_blob.function.name}${data.azurerm_storage_account_sas.sas.sas}"
  }
}

# Enable Regional VNet integration. Function --> service Subnet 
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_function_app.func_app.id
  subnet_id      = azurerm_subnet.service.id
}
