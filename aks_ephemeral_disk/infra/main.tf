# ─────────────────────────────────────────────────────────────────────────────
# AKS + Ephemeral OS Disk — intentional size-constraint demonstration
#
# The node pool uses os_disk_type = "Ephemeral" but os_disk_size_gb is
# intentionally omitted.  AKS will request the default 128 GiB OS disk.
# Standard_D4s_v3 only supports 100 GiB on the CacheDisk placement path,
# so Azure will return:
#
#   InvalidParameter: The requested ephemeral OS disk size (128 GiB) exceeds
#   the max cache disk size (100 GiB) supported by VM size Standard_D4s_v3.
#
# To make the cluster deployable, either:
#   (a) Set os_disk_size_gb to a value ≤ 100 (e.g. 80), or
#   (b) Switch to a VM whose cache disk ≥ 128 GiB (e.g. Standard_D8s_v3
#       with 200 GiB cache, or Standard_D16s_v3 with 400 GiB cache).
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size

    # Ephemeral OS disk — OS runs directly from the VM cache (no remote managed
    # disk), giving lower latency and eliminating per-node disk billing.
    os_disk_type    = "Ephemeral"
    os_disk_size_gb = 30

    # os_disk_size_gb is NOT set.
    # AKS will use the image default: 128 GiB.
    # Standard_D4s_v3 cache capacity: 100 GiB.
    # 128 GiB > 100 GiB → deployment fails at the Azure layer.

    # Place the ephemeral disk on the VM cache (not resource/temp disk).
    # "CacheDisk" is the only valid placement for Standard_D4s_v3;
    # the temp disk (32 GiB) is too small for any OS image regardless.
    os_sku = "Ubuntu"
  }

  # Use a system-assigned managed identity — no credential rotation needed.
  identity {
    type = "SystemAssigned"
  }

  # Disable the Kubernetes dashboard (deprecated and a security risk).
  # The azure_policy and http_application_routing add-ons are opt-in below.
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
}
