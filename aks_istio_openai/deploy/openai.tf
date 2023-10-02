resource "azurerm_cognitive_account" "openai" {
  name                          = var.aoai_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  location                      = "eastus"
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  custom_subdomain_name         = var.aoai_name
}

resource "azurerm_cognitive_deployment" "gpt_35_turbo" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0301"
  }

  scale {
    type = "Standard"
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type     = "Standard"
    capacity = 1
  }
}

resource "azurerm_cognitive_account" "openai_2" {
  name                          = "${var.aoai_name}-2"
  kind                          = "OpenAI"
  sku_name                      = "S0"
  location                      = "eastus"
  resource_group_name           = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  custom_subdomain_name         = "${var.aoai_name}-2"
}

resource "azurerm_cognitive_deployment" "gpt_35_turbo_2" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai_2.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0301"
  }

  scale {
    type     = "Standard"
    capacity = 120
  }
}

resource "azurerm_cognitive_deployment" "embedding_1" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai_2.id
  rai_policy_name      = "Microsoft.Default"
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type     = "Standard"
    capacity = 239
  }
}
