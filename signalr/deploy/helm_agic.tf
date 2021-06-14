resource "helm_release" "application-gateway-kubernetes-ingress" {
  name       = "ingress-azure"
  chart      = "ingress-azure"
  version    = "1.4.0"
  repository = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"
  verify     = false

  values = [
    <<-EOT
# This file contains the essential configs for the ingress controller helm chart

# Verbosity level of the App Gateway Ingress Controller
verbosityLevel: 3

################################################################################
# Specify which application gateway the ingress controller will manage
#
appgw:
    subscriptionId: ${data.azurerm_subscription.current.subscription_id}
    resourceGroup: ${azurerm_resource_group.rg.name}
    name: ${azurerm_application_gateway.agic.name}
    usePrivateIP: false

    # Setting appgw.shared to "true" will create an AzureIngressProhibitedTarget CRD.
    # This prohibits AGIC from applying config for any host/path.
    # Use "kubectl get AzureIngressProhibitedTargets" to view and change this.
    shared: false

################################################################################
# Specify which kubernetes namespace the ingress controller will watch
# Default value is "default"
# Leaving this variable out or setting it to blank or empty string would
# result in Ingress Controller observing all acessible namespaces.
#
# kubernetes:
#   watchNamespace: <namespace>

################################################################################
# Specify the authentication with Azure Resource Manager
#
# Two authentication methods are available:
# - Option 1: AAD-Pod-Identity (https://github.com/Azure/aad-pod-identity)
armAuth:
    type: aadPodIdentity
    identityResourceID: ${azurerm_user_assigned_identity.mi.id}
    identityClientID: ${azurerm_user_assigned_identity.mi.client_id}

## Alternatively you can use Service Principal credentials
# armAuth:
#    type: servicePrincipal
#    secretJSON: <<Generate this value with: "az ad sp create-for-rbac --subscription <subscription-uuid> --sdk-auth | base64 -w0" >>

################################################################################
# Specify if the cluster is RBAC enabled or not
rbac:
    enabled: true # true/false
EOT
  ]
}
