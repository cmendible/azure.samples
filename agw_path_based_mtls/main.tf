resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "appgw-delegation"
    service_delegation {
      name = "Microsoft.Network/applicationGateways"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "this" {
  name                = "example-appgw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.example.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  ssl_certificate {
    name     = "wildcard-cert"
    data     = filebase64("contoso.corp.pfx")
    password = "123456"
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.example.id
  }

  # Listener for secure subdomain with mTLS
  http_listener {
    name                           = "listener-secure"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "https-port"
    ssl_certificate_name           = "wildcard-cert"
    require_sni                    = true
    protocol                       = "Https"
    host_names                     = ["*.secure.contoso.com"]
    ssl_profile_name               = "ssl-profile-mtls"
  }

  # Listener for all other subdomains without mTLS
  http_listener {
    name                           = "listener-default"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "https-port"
    ssl_certificate_name           = "wildcard-cert"
    require_sni                    = true
    protocol                       = "Https"
    host_names                     = ["*.contoso.com"]
  }

  backend_address_pool {
    name = "default-pool"
  }

  backend_address_pool {
    name = "secure-pool"
  }

  backend_http_settings {
    name                  = "default-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "secure-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }

  # Trusted client certificate for mTLS validation
  trusted_client_certificate {
    name = "client-cert"
    data = filebase64("contoso.corp.ca.crt")
  }

  # SSL Profile for mTLS - applied only to secure listener
  ssl_profile {
    name = "ssl-profile-mtls"
    ssl_policy {
      policy_type = "Predefined"
      policy_name = "AppGwSslPolicy20220101"
    }
    trusted_client_certificate_names = ["client-cert"]
    verify_client_cert_issuer_dn     = true
  }

  # Path-based routing for secure subdomain
  url_path_map {
    name                               = "path-map-secure"
    default_backend_address_pool_name  = "secure-pool"
    default_backend_http_settings_name = "secure-settings"

    path_rule {
      name                       = "secure-path"
      paths                      = ["/secure/*"]
      backend_address_pool_name  = "secure-pool"
      backend_http_settings_name = "secure-settings"
    }
  }

  # Routing rule for secure subdomain with path-based routing
  request_routing_rule {
    name               = "rule-secure"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener-secure"
    url_path_map_name  = "path-map-secure"
    priority           = 100
  }

  # Routing rule for default traffic
  request_routing_rule {
    name                       = "rule-default"
    rule_type                  = "Basic"
    http_listener_name         = "listener-default"
    backend_address_pool_name  = "default-pool"
    backend_http_settings_name = "default-settings"
    priority                   = 200
  }
}
