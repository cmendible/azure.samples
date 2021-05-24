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
}

# Create the Subnet for the Azure Function. This is thge subnet where we'll enable Vnet Integration.
resource "azurerm_subnet" "jump" {
  name                 = "jump"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_service_network_policies = true
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
    default_action             = "Deny"
    virtual_network_subnet_ids = []
    ip_rules = [
      jsondecode(data.http.current_public_ip.body).ip
    ]
  }

  static_website {
  }
}

resource "azurerm_storage_blob" "page" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "index.html"
}

# Create the Private endpoint. This is where the Storage account gets a private IP inside the VNet.
resource "azurerm_private_endpoint" "endpoint_web" {
  name                = "sa-endpoint_web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "sa-privateserviceconnection-web"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["web"]
  }
}

# Create the blob.core.windows.net Private DNS Zone
resource "azurerm_private_dns_zone" "private_web" {
  name                = "privatelink.web.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_cname_record" "cname_web" {
  name                = "${var.sa_name}.z6.web.core.windows.net"
  zone_name           = azurerm_private_dns_zone.private_web.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = "${var.sa_name}.privatelink.web.core.windows.net"
}

# Create an A record pointing to the Storage Account private endpoint
resource "azurerm_private_dns_a_record" "sa_private_web" {
  name                = var.sa_name
  zone_name           = azurerm_private_dns_zone.private_web.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.endpoint_web.private_service_connection[0].private_ip_address]
}

# Link the Private Zone with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sa_private_web" {
  name                  = "test_web"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_web.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_public_ip" "pip" {
    name                         = "jumpbox-ip"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "jumpbox-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}