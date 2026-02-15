resource "kubernetes_pod_v1" "fiopod" {
  metadata {
    name = "fiopod"
  }

  depends_on = [kubernetes_storage_class_v1.local]

  spec {
    node_selector = {
      "kubernetes.io/os" = "linux"
    }

    container {
      name  = "fio"
      image = "mayadata/fio"
      args  = ["sleep", "1000000"]
      volume_mount {
        name       = "ephemeralvolume"
        mount_path = "/volume"
      }
    }

    volume {
      name = "ephemeralvolume"
      ephemeral {
        volume_claim_template {
          spec {
            volume_mode        = "Filesystem"
            access_modes       = ["ReadWriteOnce"]
            storage_class_name = "local" # This should match the name of the StorageClass created for Azure Container Storage
            resources {
              requests = {
                storage = "10Gi"
              }
            }
          }
        }
      }
    }
  }
}
