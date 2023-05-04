resource "azurerm_api_management_backend" "backend" {
  name                = "mendibledotcom"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = "https://carlos.mendible.com"
}

resource "azurerm_api_management_api" "me" {
  count               = 2
  name                = "mendibledotcom_${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "mendibledotcom_${count.index}"
  path                = "mendibledotcom_${count.index}"
  protocols           = ["https"]

  subscription_required = false
}

resource "azurerm_api_management_api_operation" "me_operation" {
  count               = 2
  operation_id        = "mendibledotcom_-${count.index}"
  api_name            = azurerm_api_management_api.me[count.index].name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "GET"
  method              = "GET"
  url_template        = "/"
  description         = "mendible.com reusing backend"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "me_policy" {
  count               = 2
  api_name            = azurerm_api_management_api_operation.me_operation[count.index].api_name
  api_management_name = azurerm_api_management_api_operation.me_operation[count.index].api_management_name
  resource_group_name = azurerm_api_management_api_operation.me_operation[count.index].resource_group_name
  operation_id        = azurerm_api_management_api_operation.me_operation[count.index].operation_id

  xml_content = <<XML
<policies>
  <inbound>
        <set-backend-service backend-id="${azurerm_api_management_backend.backend.name}" />
        <base />
    </inbound>
    <outbound>
        <base />
    </outbound>
    <backend>
        <forward-request timeout="60" />
    </backend>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}
