data "azurerm_client_config" "current" {}

# Create the velero namespace
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

# Install velero using the hem chart
resource "helm_release" "velero" {
  name       = "velero"
  chart      = "velero"
  namespace  = "velero"
  version    = "2.29.4"
  repository = "https://vmware-tanzu.github.io/helm-charts"

  set {
    name  = "credentials.secretContents.cloud"
    value = <<EOF
    AZURE_SUBSCRIPTION_ID=${data.azurerm_client_config.current.subscription_id} 
    AZURE_TENANT_ID=${data.azurerm_client_config.current.tenant_id}
    AZURE_CLIENT_ID=${var.client_id}
    AZURE_CLIENT_SECRET=${var.client_secret}
    AZURE_RESOURCE_GROUP=${azurerm_kubernetes_cluster.aks.node_resource_group}
    AZURE_CLOUD_NAME=AzurePublicCloud
    EOF
  }

  set {
    name  = "configuration.provider"
    value = "azure"
  }

  set {
    name  = "configuration.backupStorageLocation.name"
    value = "azure"
  }

  set {
    name  = "configuration.backupStorageLocation.provider"
    value = "azure"
  }

  set {
    name  = "configuration.backupStorageLocation.default"
    value = true
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = "velero"
  }

  set {
    name  = "configuration.backupStorageLocation.config.resourceGroup"
    value = var.backup_resource_group
  }

  set {
    name  = "configuration.backupStorageLocation.config.storageAccount"
    value = var.sta_name
  }

  set {
    name  = "snapshotsEnabled"
    value = true
  }

  set {
    name  = "deployRestic"
    value = true
  }

  set {
    name  = "configuration.features"
    value = "EnableCSI"
  }

  set {
    name  = "configuration.volumeSnapshotLocation.name"
    value = "azure"
  }

  # Do not use restic as default method
  set {
    name  = "configuration.defaultVolumesToRestic"
    value = false
  }

  set {
    name  = "configuration.resticTimeout"
    value = "6h"
  }

  set {
    name  = "restic.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "restic.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "restic.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "restic.resources.limits.memory"
    value = "2048Mi"
  }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-csi"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-csi:v0.2.0"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }

  set {
    name  = "initContainers[1].name"
    value = "velero-plugin-for-microsoft-azure"
  }

  set {
    name  = "initContainers[1].image"
    value = "velero/velero-plugin-for-microsoft-azure:master"
  }

  set {
    name  = "initContainers[1].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[1].volumeMounts[0].name"
    value = "plugins"
  }
}
