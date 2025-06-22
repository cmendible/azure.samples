# Create a public Ip for the firewall
resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "fw-cfm-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the firewall
resource "azurerm_firewall" "firewall" {
  name                = "fw-cfm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  firewall_policy_id  = azurerm_firewall_policy.policy.id
  sku_tier            = "Standard"
  sku_name            = "AZFW_VNet"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
}

resource "azurerm_firewall_policy" "policy" {
  name                = "network_rule_fqdn_enabled"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "policies" {
  name               = "aks"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 100

  network_rule_collection {
    name     = "aksfwnr"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "apiudp"
      source_addresses      = ["*"]
      destination_ports     = [1194]
      destination_addresses = ["AzureCloud.WestEurope"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "apitcp"
      source_addresses      = ["*"]
      destination_ports     = [9000]
      destination_addresses = ["AzureCloud.WestEurope"]
      protocols             = ["TCP"]
    }

    rule {
      name              = "time"
      source_addresses  = ["*"]
      destination_ports = [123]
      destination_fqdns = ["ntp.ubuntu.com"]
      protocols         = ["UDP"]
    }
  }

  application_rule_collection {
    name     = "aksfwar"
    priority = 200
    action   = "Allow"

    rule {
      name = "fqdn"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = ["*"]
      destination_fqdn_tags = ["AzureKubernetesService"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "aks_api_policies" {
  name               = "aks-api"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 200

  application_rule_collection {
    name     = "aksfwar"
    priority = 200
    action   = "Allow"

    rule {
      name = "aks-api"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = ["*"]
      destination_fqdn_tags = [azurerm_kubernetes_cluster.aks.fqdn]
    }
  }

  depends_on = [azurerm_firewall_policy_rule_collection_group.policies]
}
