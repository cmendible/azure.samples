provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "apim-mock"
  location = "West Europe"
}

resource "azurerm_api_management" "apim" {
  name                = "apim-cfm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "cmendible"
  publisher_email     = "cmendible@msft.io"

  sku_name = "Developer_1"

  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
XML

  }
}

resource "azurerm_api_management_api" "api" {
  name                = "mock-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Mock API"
  path                = "mock"
  protocols           = ["https"]
}

resource "azurerm_api_management_api_operation" "api_operarion" {
  operation_id        = "user-delete"
  api_name            = azurerm_api_management_api.api.name
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

resource "azurerm_api_management_api_operation_policy" "mock" {
  api_name            = azurerm_api_management_api_operation.api_operarion.api_name
  api_management_name = azurerm_api_management_api_operation.api_operarion.api_management_name
  resource_group_name = azurerm_api_management_api_operation.api_operarion.resource_group_name
  operation_id        = azurerm_api_management_api_operation.api_operarion.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <mock-response status-code="200" content-type="application/json"/>
  </inbound>
</policies>
XML

}

output "url" {
  value = "${azurerm_api_management.apim.gateway_url}/mock"
}
