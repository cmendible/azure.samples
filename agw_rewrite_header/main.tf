terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_application_gateway" "main" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  # Backend pool - shared by both listeners
  backend_address_pool {
    name = "shared-backend-pool"

    fqdns = [
      "backend-server.example.com"
    ]
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  # HTTP Listener for a.com
  http_listener {
    name                           = "listener-a-com"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
    host_name                      = "a.com"
  }

  # HTTP Listener for b.com
  http_listener {
    name                           = "listener-b-com"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
    host_name                      = "b.com"
  }

  # URL Rewrite Rule Set - adds X-Original-Host header
  rewrite_rule_set {
    name = "add-original-host-header"

    rewrite_rule {
      name          = "add-x-original-host"
      rule_sequence = 100

      request_header_configuration {
        header_name  = "X-Original-Host"
        header_value = "{http_req_host}"
      }
    }
  }

  # Request routing rule for a.com
  request_routing_rule {
    name                       = "routing-rule-a-com"
    rule_type                  = "Basic"
    http_listener_name         = "listener-a-com"
    backend_address_pool_name  = "shared-backend-pool"
    backend_http_settings_name = "backend-http-settings"
    rewrite_rule_set_name      = "add-original-host-header"
    priority                   = 100
  }

  # Request routing rule for b.com
  request_routing_rule {
    name                       = "routing-rule-b-com"
    rule_type                  = "Basic"
    http_listener_name         = "listener-b-com"
    backend_address_pool_name  = "shared-backend-pool"
    backend_http_settings_name = "backend-http-settings"
    rewrite_rule_set_name      = "add-original-host-header"
    priority                   = 200
  }
}

# Supporting resources
resource "azurerm_resource_group" "main" {
  name     = "rg-appgateway-example"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-appgateway"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "pip-appgateway"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
