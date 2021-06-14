resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  chart      = "redis"
  namespace  = "redis"
  version    = "12.1.2"
  repository = "https://charts.bitnami.com/bitnami"
  verify     = false
}

data "kubernetes_secret" "redis_secret" {
  metadata {
    name      = "redis"
    namespace = "redis"
  }
  depends_on = [
    helm_release.redis
  ]
}
