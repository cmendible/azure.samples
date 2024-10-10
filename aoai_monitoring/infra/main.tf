resource "random_id" "random" {
  byte_length = 8
}

locals {
  sufix                   = substr(lower(random_id.random.hex), 1, 5) 
  name_sufix              = "-${local.sufix}"
  apim_name               = "${var.apim_name}${local.name_sufix}"
  resource_group_name     = "${var.resource_group_name}${local.name_sufix}"
  log_name                = "log-${var.apim_name}${local.name_sufix}"
  azopenai_name           = "${var.azopenai_name}${local.name_sufix}"
  appi_name               = "appi-${var.apim_name}${local.name_sufix}"
  logger_name             = "openai-appi-logger"
  backend_url             = "${azurerm_cognitive_account.openai.endpoint}openai"
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = local.log_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = local.appi_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.logs.id
}

resource "azapi_resource" "apim" {
  type      = "Microsoft.ApiManagement/service@2023-03-01-preview"
  name      = local.apim_name
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
  schema_validation_enabled = false # requiered for now
  body = {
    sku = {
      name     = "StandardV2"
      capacity = 1
    }
    properties = {
      publisherEmail        = var.publisher_email
      publisherName         = var.publisher_name
      apiVersionConstraint  = {}
      developerPortalStatus = "Disabled"
      virtualNetworkType    = "None"
    }
  }
  response_export_values = [
    "identity.principalId",
    "properties.gatewayUrl"
  ]
}

resource "azurerm_api_management_backend" "openai" {
  name                = "openai-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azapi_resource.apim.name
  protocol            = "http"
  url                 = local.backend_url
  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }
}

resource "azapi_resource" "apim_backend_pool" {
  type                      = "Microsoft.ApiManagement/service/backends@2023-09-01-preview"
  parent_id                 = azapi_resource.apim.id
  name                      = "openai-backend-pool"
  schema_validation_enabled = false # requiered for now
  body = {
    properties = {
      description = "Azure OpenAI Backend Pool"
      type        = "Pool"
      pool = {
        services = [
          {
            id       = azurerm_api_management_backend.openai.id
            priority = 1
            weight   = 1
          }
        ]
      }
    }
  }
}

resource "azurerm_api_management_logger" "appi_logger" {
  name                = local.logger_name
  api_management_name = azapi_resource.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.appinsights.id

  application_insights {
    instrumentation_key = azurerm_application_insights.appinsights.instrumentation_key
  }
}

// https://learn.microsoft.com/en-us/semantic-kernel/deploy/use-ai-apis-with-api-management#setup-azure-api-management-instance-with-azure-openai-api
resource "azurerm_api_management_api" "openai" {
  name                  = "openai-api"
  resource_group_name   = azurerm_resource_group.rg.name
  api_management_name   = azapi_resource.apim.name
  revision              = "1"
  display_name          = "Azure Open AI API"
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = false
  service_url           = local.backend_url

  import {
    content_format = "openapi-link"
    content_value  = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-10-01-preview/inference.json"
  }
}

resource "azurerm_api_management_named_value" "tenant_id" {
  name                = "tenant-id"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azapi_resource.apim.name
  display_name        = "TENANT_ID"
  value               = data.azurerm_subscription.current.tenant_id
}

resource "azurerm_api_management_api_policy" "policy" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azapi_resource.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
    <policies>
        <inbound>
            <base />
            <validate-jwt header-name="Authorization" failed-validation-httpcode="403" failed-validation-error-message="Forbidden">
                <openid-config url="https://login.microsoftonline.com/{{TENANT_ID}}/v2.0/.well-known/openid-configuration" />
                <issuers>
                    <issuer>https://sts.windows.net/{{TENANT_ID}}/</issuer>
                </issuers>
                <required-claims>
                    <claim name="aud">
                        <value>https://cognitiveservices.azure.com</value>
                    </claim>
                </required-claims>
            </validate-jwt>

            <choose>
                <when condition="@(context.Request.Body.As<JObject>(preserveContent: true)["messages"]?.All(message => message["content"].All(content => !(content is JObject))) == true)">
                    
                    <!-- If all type properties are 'text' or there are no type properties, apply the new Azure OpenAI policies -->
                    
                    <trace source="Azure OpenAI Policies" severity="information">
                        <message>Using Azure OpenAI policies.</message>
                        <metadata name="Using_Azure_OpenAI_Policies" value="true" />
                    </trace>
                    
                    <azure-openai-emit-token-metric
                        namespace="AzureOpenAI">
                        <dimension name="API ID" />
                        <dimension name="Operation ID" />
                        <dimension name="Client IP" value="@(context.Request.IpAddress)" />
                    </azure-openai-emit-token-metric>

                    <azure-openai-token-limit
                      counter-key="@(context.Request.IpAddress)"
                      tokens-per-minute="10000" estimate-prompt-tokens="false" remaining-tokens-variable-name="remainingTokens" />
                </when>
                <otherwise>
                    <trace source="Azure OpenAI Policies" severity="information">
                        <message>Not using Azure OpenAI policies.</message>
                        <metadata name="Using_Azure_OpenAI_Policies" value="false" />
                    </trace>
                </otherwise>
            </choose>

            <set-backend-service backend-id="${azapi_resource.apim_backend_pool.name}" />
        </inbound>
        <backend>
          <base />
        </backend>
        <outbound>
            <base />
        </outbound>
        <on-error>
          <base />
        </on-error>
    </policies>
    XML
  depends_on  = [azurerm_api_management_named_value.tenant_id]
}

# https://github.com/aavetis/azure-openai-logger/blob/main/README.md
# KQL Query to extract OpenAI data from Application Insights
# customMetrics
# | extend ip = tostring(parse_json(customDimensions).["Client IP"])
# | summarize totalValueSum = sum(valueSum) by name, ip
resource "azurerm_api_management_diagnostic" "diagnostics" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azapi_resource.apim.name
  api_management_logger_id = azurerm_api_management_logger.appi_logger.id

  sampling_percentage       = 100
  always_log_errors         = true
  log_client_ip             = false
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes     = 8192
    headers_to_log = []
    data_masking {
      query_params {
        mode  = "Hide"
        value = "*"
      }
    }
  }

  frontend_response {
    body_bytes     = 8192
    headers_to_log = []
  }

  backend_request {
    body_bytes     = 8192
    headers_to_log = []
    data_masking {
      query_params {
        mode  = "Hide"
        value = "*"
      }
    }
  }

  backend_response {
    body_bytes     = 8192
    headers_to_log = []
  }
}

# https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest#emit-custom-metrics
resource "azapi_update_resource" "diagnostics" {
  type        = "Microsoft.ApiManagement/service/diagnostics@2022-08-01"
  resource_id = azurerm_api_management_diagnostic.diagnostics.id

  body = {
    properties = {
      loggerId = azurerm_api_management_logger.appi_logger.id
      metrics  = true
    }
  }
}

resource "azurerm_cognitive_account" "openai" {
  name                          = local.azopenai_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  location                      = "swedencentral"
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  custom_subdomain_name         = local.azopenai_name
}

resource "azurerm_cognitive_deployment" "gpt_35_turbo" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.Default"
  scale {
    type     = "Standard"
    capacity = 40
  }
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }
}

resource "azurerm_role_assignment" "openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azapi_resource.apim.output.identity.principalId
}