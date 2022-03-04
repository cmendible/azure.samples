resource "azurerm_policy_definition" "key_vault_firewall" {
  name         = "Azure Key Vault should disable public network access"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Azure Key Vault should disable public network access"

  metadata = <<METADATA
    {
    "category": "Key Vault"
    }

METADATA


  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.KeyVault/vaults"
          },
          {
            "not": {
              "field": "Microsoft.KeyVault/vaults/createMode",
              "equals": "recover"
            }
          },
          {
            "field": "Microsoft.KeyVault/vaults/networkAcls.defaultAction",
            "notEquals": "Deny"
          }
        ]
      },
      "then": {
        "effect": "Deny"
      }
    }
POLICY_RULE

}

resource "azurerm_resource_group_policy_assignment" "key_vault_firewall_assignment" {
  name                 = "AzureKeyVaultFirewall-policy-assignment"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_definition.key_vault_firewall.id
  description          = "Azure Key Vault should disable public network access Assignment"
  display_name         = "Azure Key Vault should disable public network access Assignment"

  metadata = <<METADATA
    {
    "category": "General"
    }
METADATA
}
