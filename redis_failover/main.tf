terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = "= 2.57.0"
    }
    random = {
      version = "= 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Location of the services
variable "location" {
  default = "west europe"
}

# Resource Group Name
variable "resource_group" {
  default = "redis-failover"
}

# Name of the Redis cluster
variable "redis_name" {
  default = "redis-failover"
}

resource "random_id" "random" {
  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_redis_cache" "redis" {
  name                = "${var.redis_name}-${lower(random_id.random.hex)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  zones = ["1", "2"]
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "redis-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "monitor" {
  name                       = lower("extaudit-${var.redis_name}-diag")
  target_resource_id         = azurerm_redis_cache.redis.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "ConnectedClientList"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [metric]
  }
}

output "redis_name" {
  value = azurerm_redis_cache.redis.name
}

output "redis_host_name" {
  value = azurerm_redis_cache.redis.hostname
}

output "redis_primary_access_key" {
  value     = azurerm_redis_cache.redis.primary_access_key
  sensitive = true
}
