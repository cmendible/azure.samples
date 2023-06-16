resource "azurerm_public_ip" "gateway" {
  name                = "${var.gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
}

locals {
  backend_address_pool_name      = "${var.gateway_name}-beap"
  frontend_port_name             = "${var.gateway_name}-feport"
  frontend_ip_configuration_name = "${var.gateway_name}-feip"
  http_setting_name              = "${var.gateway_name}-be-htst"
  listener_name                  = "${var.gateway_name}-httplstn"
  request_routing_rule_name      = "${var.gateway_name}-rqrt"
}

resource "azurerm_application_gateway" "gateway" {
  name                = var.gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.AppGwSubnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 100
  }
}

resource "azurerm_role_assignment" "agic_contributor" {
  scope                = azurerm_application_gateway.gateway.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}
