resource "random_id" "random" {
  byte_length = 8
}

locals {
  name_sufix           = substr(lower(random_id.random.hex), 1, 4)
  resource_group_name  = "${var.resource_group_name}-${local.name_sufix}"
  storage_account_name = "${var.storage_account_name}${local.name_sufix}"
  function_name        = "${var.function_name}-${local.name_sufix}"
  container_name       = "deploymentpackage"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

resource "azapi_resource" "func" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = azurerm_resource_group.rg.location
  name                      = local.function_name
  parent_id                 = azurerm_resource_group.rg.id
  body = {
    kind = "functionapp,linux",
    identity = {
      type : "SystemAssigned"
    }
    properties = {
      serverFarmId           = azurerm_service_plan.plan.id,
      httpsOnly              = true
      virtualNetworkSubnetId = azurerm_subnet.flex.id
      functionAppConfig = {
        deployment = {
          storage = {
            type  = "blobcontainer",
            value = "${azurerm_storage_account.sa.primary_blob_endpoint}${local.container_name}",
            name  = local.container_name,
            authentication = {
              type = "systemassignedidentity"
            }
          }
        },
        scaleAndConcurrency = {
          maximumInstanceCount = 40,
          instanceMemoryMB     = 2048
        },
        runtime = {
          name    = "dotnet-isolated",
          version = "8.0"
        }
      },
      siteConfig = {
        appSettings = [
          {
            name  = "AzureWebJobsStorage__accountName",
            value = azurerm_storage_account.sa.name
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING",
            value = azurerm_application_insights.appi.connection_string
          }
        ]
      }
    }
  }

  response_export_values = [
    "identity.principalId",
  ]
}

resource "azurerm_role_assignment" "storage_roleassignment" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.func.output.identity.principalId
}
