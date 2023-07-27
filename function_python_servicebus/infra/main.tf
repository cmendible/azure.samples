resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  storage_account_name = "stsb${local.name_sufix}"
  plan_name            = "plan-sb${local.name_sufix}"
  function_name        = "func-sb${local.name_sufix}"
  sb_name              = "sb-${local.name_sufix}"
}

resource "azurerm_resource_group" "rg" {
  name     = "azure-functions-sb"
  location = "West Europe"
}

resource "azurerm_storage_account" "st" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "ws" {
  name                = "log-func"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = "appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.ws.id
  application_type    = "web"
}


resource "azurerm_service_plan" "plan" {
  name                = local.plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P2v2"
}

resource "azurerm_linux_function_app" "func" {
  name                        = local.function_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  service_plan_id             = azurerm_service_plan.plan.id
  storage_account_name        = azurerm_storage_account.st.name
  storage_account_access_key  = azurerm_storage_account.st.primary_access_key
  functions_extension_version = "~4"

  app_settings = {
    "AzureServiceBusConnectionString" = azurerm_servicebus_namespace.ns.default_primary_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.appinsights.instrumentation_key
    // https://learn.microsoft.com/en-us/azure/azure-functions/python-scale-performance-reference#use-multiple-language-worker-processes
    "FUNCTIONS_WORKER_PROCESS_COUNT" = "1"
    "PYTHON_THREADPOOL_THREAD_COUNT" = "None"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_servicebus_namespace" "ns" {
  name                = local.sb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_topic" "entry" {
  name         = "entry"
  namespace_id = azurerm_servicebus_namespace.ns.id

  # enable_partitioning = true
  # support_ordering    = true
}

resource "azurerm_servicebus_subscription" "receiver_one" {
  name               = "receiver_one"
  topic_id           = azurerm_servicebus_topic.entry.id
  max_delivery_count = 1
  # requires_session   = true
}

resource "azurerm_servicebus_subscription" "receiver_two" {
  name               = "receiver_two"
  topic_id           = azurerm_servicebus_topic.entry.id
  max_delivery_count = 1
  # requires_session   = true
}

resource "azurerm_servicebus_subscription" "receiver_three" {
  name               = "receiver_three"
  topic_id           = azurerm_servicebus_topic.entry.id
  max_delivery_count = 1
  # requires_session   = true
}

resource "azurerm_servicebus_queue" "queue" {
  name         = "backlog"
  namespace_id = azurerm_servicebus_namespace.ns.id
  # enable_partitioning = true
  # requires_session    = true
}

resource "azurerm_servicebus_queue" "queue_two" {
  name         = "backlog_two"
  namespace_id = azurerm_servicebus_namespace.ns.id
  # enable_partitioning = true
  # requires_session    = true
}

output "function_name" {
  value = azurerm_linux_function_app.func.name
}
