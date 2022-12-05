resource "azurerm_api_management" "apim" {
  name                 = var.api_management_name
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = "Developer_1"
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

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

  depends_on = [
    azurerm_subnet_network_security_group_association.nsg_association
  ]
}
