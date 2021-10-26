terraform {
  required_version = "> 0.14"
  required_providers {
    azurerm = {
      version = ">= 2.82.0"
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
  default = "mysql-failover"
}

# Name of the mysql cluster
variable "mysql_name" {
  default = "mysql-failover"
}

resource "random_id" "random" {
  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_mysql_flexible_server" "flexible_server" {
  name                   = "${var.mysql_name}-${lower(random_id.random.hex)}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  backup_retention_days  = 7
  sku_name               = "GP_Standard_D2ds_v4"
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  zone = "1"
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "mysql-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "monitor" {
  name                       = lower("extaudit-${var.mysql_name}-diag")
  target_resource_id         = azurerm_mysql_flexible_server.flexible_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "MySqlAuditLogs"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "MySqlSlowLogs"
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

output "resource_group" {
  value = var.resource_group
}

output "mysql_name" {
  value = azurerm_mysql_flexible_server.flexible_server.name
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.flexible_server.fqdn
}

output "administrator_login" {
  value     = azurerm_mysql_flexible_server.flexible_server.administrator_login
  sensitive = true
}

output "administrator_password" {
  value     = azurerm_mysql_flexible_server.flexible_server.administrator_password
  sensitive = true
}
