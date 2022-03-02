resource "azurerm_public_ip" "gateway" {
  name                = "gateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = var.domain_name_label
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
  probe_name                     = "${azurerm_virtual_network.vnet.name}-probe"
}

resource "azurerm_application_gateway" "gateway" {
  name                = "aks-appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.gateway.id
  }

  ssl_certificate {
    name     = "certificate"
    data     = filebase64("server.pfx")
    password = "1234"
  }

  trusted_root_certificate {
    name     = "aks"
    data     = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    fqdns = [ 
      azurerm_kubernetes_cluster.aks.private_fqdn
    ]
  }

  probe {
    name     = local.probe_name
    protocol = "Https"
    host     = azurerm_kubernetes_cluster.aks.private_fqdn
    path     = "/livez" // healthz is deprecated
    match {
      status_code = ["401"]
    }
    port                = 443
    timeout             = 30
    interval            = 30
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                           = local.http_setting_name
    cookie_based_affinity          = "Disabled"
    path                           = "/" 
    port                           = 443
    protocol                       = "Https"
    request_timeout                = 60
    host_name                      = azurerm_kubernetes_cluster.aks.private_fqdn
    trusted_root_certificate_names = [ "aks" ]
    probe_name                     = local.probe_name
  }
  
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name           = "certificate"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}