resource "azapi_resource" "ca_function" {
  schema_validation_enabled = false
  name                      = "func-${var.ca_name}"
  location                  = var.location
  parent_id                 = var.resource_group_id
  type                      = "Microsoft.Web/sites@2023-01-01"
  body = jsonencode({
    kind = "functionapp,linux,container,azurecontainerapps"
    properties : {
      language             = "dotnet-isolated"
      managedEnvironmentId = "${var.cae_id}"
      siteConfig = {
        linuxFxVersion = "DOCKER|cmendibl3/aca-functions:0.2.0"
        appSettings = [
          {
            name  = "AzureWebJobsStorage"
            value = var.storage_connection_string
          },
          {
            name  = "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"
            value = var.storage_connection_string
          },
          {
            name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
            value = var.appi_instrumentation_key
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
            value = "InstrumentationKey=${var.appi_instrumentation_key}"
          },
          {
            name  = "FUNCTIONS_WORKER_RUNTIME"
            value = "dotnet-isolated"
          },
          {
            name  = "FUNCTIONS_EXTENSION_VERSION"
            value = "~4"
          }
        ]
      }
      workloadProfileName = "Consumption"
      resourceConfig = {
        cpu    = 1
        memory = "2Gi"
      }
      httpsOnly = true
    }
  })
}
