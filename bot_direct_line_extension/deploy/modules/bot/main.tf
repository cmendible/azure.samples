resource "azurerm_template_deployment" "bot-arm" {
  name                = var.deployment_name
  resource_group_name = var.resource_group_name
  template_body       = file("${path.module}/bot_template.json")

  parameters = {
    "bot_name"            = var.bot_name
    "bot_endpoint"        = var.bot_endpoint
    "msaAppTenantId"      = var.msaAppTenantId
    "msaAppMSIResourceId" = var.msaAppMSIResourceId
    "msaAppId"            = var.msaAppId
  }

  deployment_mode = "Incremental"
}
