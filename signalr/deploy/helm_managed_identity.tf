resource "helm_release" "aad-pod-identity" {
  name       = "aad-pod-identity"
  chart      = "aad-pod-identity"
  version    = "3.0.3"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  verify     = false

  values = [
    <<-EOT
azureIdentities:
  ${var.managed_identity_name}:
    name: ${var.managed_identity_name}
    type: 0
    resourceID: ${azurerm_user_assigned_identity.mi.id}
    clientID: ${azurerm_user_assigned_identity.mi.client_id}
    binding:
      name: ${var.managed_identity_name}
      selector: ${var.managed_identity_name}
EOT
  ]
}
