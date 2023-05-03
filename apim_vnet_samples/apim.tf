resource "azurerm_api_management" "apim" {
  name                 = local.api_management_name
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = "Developer_1"
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

   depends_on = [
    azurerm_subnet_network_security_group_association.nsg_association
  ]
}

resource "azurerm_api_management_product" "starter" {
  product_id            = "starter"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Starter"
  description           = "A subscription to this product will allow you to make 100 calls per hour. Rate limit applied: 10 calls per minute."
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_policy" "starter" {
  product_id          = azurerm_api_management_product.starter.product_id
  api_management_name = azurerm_api_management_product.starter.api_management_name
  resource_group_name = azurerm_api_management_product.starter.resource_group_name

  xml_content = <<XML
  <policies>
    <inbound>
      <base />
      <rate-limit calls="10" renewal-period="60"/>
      <quota calls="100" renewal-period="3600"/>
    </inbound>
  </policies>
  XML
}

resource "azurerm_api_management_product" "premium" {
  product_id            = "premium"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Premium"
  description           = "A subscription to this product will allow you to make 10,000 calls per hour. Rate limit applied: 600 calls per minute."
  subscription_required = true
  approval_required     = true
  subscriptions_limit   = 1
  published             = true
}

resource "azurerm_api_management_product_policy" "premium" {
  product_id          = azurerm_api_management_product.premium.product_id
  api_management_name = azurerm_api_management_product.premium.api_management_name
  resource_group_name = azurerm_api_management_product.premium.resource_group_name

  xml_content = <<XML
  <policies>
    <inbound>
      <base />
      <rate-limit calls="600" renewal-period="60"/>
      <quota calls="10000" renewal-period="3600"/>
    </inbound>
  </policies>
  XML
}