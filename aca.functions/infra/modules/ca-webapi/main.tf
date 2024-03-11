resource "azapi_resource" "ca_webapi" {
  name      = var.ca_name
  location  = var.location
  parent_id = var.resource_group_id
  type      = "Microsoft.App/containerApps@2022-11-01-preview"
  identity {
    type = "UserAssigned"
    identity_ids = [
      var.managed_identity_id
    ]
  }

  body = jsonencode({
    properties : {
      managedEnvironmentId = "${var.cae_id}"
      configuration = {
        secrets = []
        ingress = {
          external   = true
          targetPort = 80
          transport  = "Http"

          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
          corsPolicy = {
            allowedOrigins = [
              "*"
            ]
            allowedHeaders   = ["*"]
            allowCredentials = false
          }
        }
        dapr = {
          enabled = false
        }
      }
      template = {
        containers = [
          {
            name  = "welcome-function"
            image = "cmendibl3/aca-functions:0.2.0"
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = [
              {
                name  = "FUNCTIONS_WORKER_RUNTIME"
                value = "dotnet-isolated"
              },
              {
                name  = "FUNCTIONS_EXTENSION_VERSION"
                value = "~4"
              }
            ],
          },
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })
  response_export_values = ["properties.configuration.ingress.fqdn"]
}
