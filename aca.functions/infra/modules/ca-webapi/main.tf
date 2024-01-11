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
          targetPort = 8080
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
            name  = "chat-copilot-webapi"
            image = "cmendibl3/aca-functions"
            resources = {
              cpu    = 0.5
              memory = "1Gi"
            }
            env = [],
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
