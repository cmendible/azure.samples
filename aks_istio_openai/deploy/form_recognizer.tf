resource "azurerm_cognitive_account" "form" {
  name                          = var.form_recognizer_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  kind                          = "FormRecognizer"
  sku_name                      = "S0"
  public_network_access_enabled = true
  custom_subdomain_name         = var.form_recognizer_name
}
