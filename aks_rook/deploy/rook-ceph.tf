# Install rook-ceph using the hem chart
resource "helm_release" "rook-ceph" {
  name             = "rook-ceph"
  chart            = "rook-ceph"
  namespace        = "rook-ceph"
  version          = "1.7.3"
  repository       = "https://charts.rook.io/release/"
  create_namespace = true

  values = [
    "${file("./rook-ceph-operator-values.yaml")}"
  ]

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.npceph
  ]
}

resource "helm_release" "rook-ceph-cluster" {
  name       = "rook-ceph-cluster"
  chart      = "rook-ceph-cluster"
  namespace  = "rook-ceph"
  version    = "1.7.3"
  repository = "https://charts.rook.io/release/"

  values = [
    "${file("./rook-ceph-cluster-values.yaml")}"
  ]

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.npceph,
    helm_release.rook-ceph
  ]
}
