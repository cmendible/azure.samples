resource "azurerm_api_management_api" "mock_api" {
  name                = "mock-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Mock API"
  path                = "mock"
  protocols           = ["https"]
}

resource "azurerm_api_management_api_operation" "mock_api_operation" {
  operation_id        = "mock-get"
  api_name            = azurerm_api_management_api.mock_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Mock Operation"
  method              = "GET"
  url_template        = "/"
  description         = "This a mocked operation."

  response {
    status_code = 200
    representation {
      content_type = "application/json"
      sample       = <<EOF
      { "sampleField": "test" }
EOF
    }
  }
}

resource "azurerm_api_management_api_operation_policy" "mock_policy" {
  api_name            = azurerm_api_management_api_operation.mock_api_operation.api_name
  api_management_name = azurerm_api_management_api_operation.mock_api_operation.api_management_name
  resource_group_name = azurerm_api_management_api_operation.mock_api_operation.resource_group_name
  operation_id        = azurerm_api_management_api_operation.mock_api_operation.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <mock-response status-code="200" content-type="application/json"/>
  </inbound>
</policies>
XML
}