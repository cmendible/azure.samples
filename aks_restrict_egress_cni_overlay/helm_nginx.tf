# https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
resource "helm_release" "nginx-ingress-controller" {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.6.0"
  repository = "https://kubernetes.github.io/ingress-nginx/"
  verify     = false

  values = [
    <<-EOT
controller:
  service:
    externalTrafficPolicy: 'Local'
    loadBalancerIP: ${cidrhost("10.0.0.0/16", 254)}
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: '/healthz'
      service.beta.kubernetes.io/azure-load-balancer-internal: 'true'
EOT
  ]
}
