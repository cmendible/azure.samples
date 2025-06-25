# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "fd-private-rg"
  location = "westeurope"
}

# Azure Front Door Premium Profile
resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "fd-private-profile"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin_group" "group" {
  name                     = "fd-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {}
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                          = "fd-private-endpoint"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_storage_account.sa.primary_web_host
  origin_host_header             = azurerm_storage_account.sa.primary_web_host
  priority                       = 1
  weight                         = 500

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    target_type            = "web"
    location               = azurerm_storage_account.sa.location
    private_link_target_id = azurerm_storage_account.sa.id
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "st-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}


resource "azurerm_cdn_frontdoor_rule_set" "rule" {
  name                     = "strule"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "st-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.rule.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain = true

  # cache {
  #   query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
  #   query_strings                 = ["account", "settings"]
  #   compression_enabled           = true
  #   content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  # }
}
