terraform {
  required_version = "> 0.14"
  required_providers {
    azuread = {
      version = ">= 2.6.0"
    }
    azurerm = {
      version = ">= 2.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

// This is the AAD Application Registration for the API
resource "azuread_application" "api" {
  display_name    = "passport-test-api"
  identifier_uris = ["api://passport-test-api"]


  app_role {
    allowed_member_types = ["User"]
    description          = "ReadOnly roles have limited query access"
    display_name         = "ReadOnly"
    enabled              = true
    id                   = "497406e4-012a-4267-bf18-45a1cb148a01"
    value                = "User"
  }

  // Add access to User.Read.All (Microsoft Graph)
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type = "Role"
    }
  }

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = null

    // Add our sample client as a known Application
    known_client_applications = [
      azuread_application.client.application_id
    ]

    // This is the scope we'll validate in our APIs
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access example on behalf of the signed-in user."
      admin_consent_display_name = "Access example"
      enabled                    = true
      id                         = "a7ef8bb6-5085-49a1-b803-517b5a439668"
      type                       = "User"
      value                      = "read"
    }
  }
}

// This is the AAD Application Registration for the client.
resource "azuread_application" "client" {
  display_name = "passport-client"

  // We'll be using a PowerShell client
  public_client {
    redirect_uris = [
      "http://localhost/",
    ]
  }
  
  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = null
  }

  // You can also use Gisela's web client
  web {
    redirect_uris = [
      "http://localhost:8000/give/me/the/code"
    ]
  }
}

// Pre authorize our client
resource "azuread_application_pre_authorized" "pre_authorized" {
  application_object_id = azuread_application.api.object_id
  authorized_app_id     = azuread_application.client.application_id
  permission_ids        = ["a7ef8bb6-5085-49a1-b803-517b5a439668"]
}

// You'll need the following output values to configure your application na use the PowerShell client
output "tenant_id" {
  description = "TENANT_ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "api_client_id" {
  description = "API CLIENT_ID"
  value       = azuread_application.api.application_id
}

output "client_id" {
  description = "client CLIENT_ID"
  value       = azuread_application.client.application_id
}

output "powershell_command" {
  value     = "./client.ps1 ${data.azurerm_client_config.current.tenant_id} ${azuread_application.client.application_id}"
}