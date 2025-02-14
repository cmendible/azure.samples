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
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"
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
  priority           = 1000

  network_rule_collection {
    name     = "aksfwnr"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "apiudp"
      source_addresses      = ["*"]
      destination_ports     = [1194]
      destination_addresses = ["AzureCloud.NorthEurope"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "apitcp"
      source_addresses      = ["*"]
      destination_ports     = [9000]
      destination_addresses = ["AzureCloud.NorthEurope"]
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

  network_rule_collection {
    name     = "to-internet"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "to-internet"
      source_addresses      = ["10.0.0.0/16"]
      destination_ports     = ["*"]
      destination_addresses = ["0.0.0.0/0"]
      protocols             = ["TCP"]
    }
  }

  application_rule_collection {
    name     = "aksfwar"
    priority = 500
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
  priority           = 1100

   network_rule_collection {
      name     = "aksfwnr"
      priority = 100
      action   = "Allow"
      // For applications outside of the kube-system or gatekeeper-system namespaces that needs 
      // to talk to the API server, an additional network rule to allow TCP communication to port
      // 443 for the API server IP in addition to adding application rule for fqdn-tag AzureKubernetesService is required.
      rule {
        name                  = "apiiptcp"
        source_addresses      = ["*"]
        destination_ports     = [443]
        destination_addresses = [data.dns_a_record_set.aks.addrs[0]]
        protocols             = ["TCP"]
      }
    }

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
}

resource "azurerm_firewall_policy_rule_collection_group" "ingress_service" {
  name               = "ingress"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 100

  nat_rule_collection {
    name     = "ingress"
    priority = "100"
    action   = "Dnat"
    rule {
      name                = "ingress"
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall_public_ip.ip_address
      destination_ports   = ["80"]
      translated_address  = cidrhost("10.0.0.0/16", 254)
      translated_port     = "80"
      protocols           = ["TCP"]
    }
  }
}
