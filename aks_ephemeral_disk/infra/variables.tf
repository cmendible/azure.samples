variable "resource_group_name" {
  type        = string
  default     = "rg-aks-ephemeral-demo"
  description = "Name of the resource group."
}

variable "location" {
  type        = string
  default     = "spaincentral"
  description = "Azure region for all resources."
}

variable "cluster_name" {
  type        = string
  default     = "aks-ephemeral-demo"
  description = "Name of the AKS cluster."
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version. Defaults to the latest available if null."
}

# ─────────────────────────────────────────────────────────────────────────────
# VM size is deliberately chosen so that the DEFAULT AKS OS disk (128 GiB)
# exceeds the cache capacity of the VM.
#
# Standard_D4s_v3 specs:
#   vCPUs  : 4
#   Memory : 16 GiB
#   Temp   : 32 GiB   (temp / resource disk — NOT used for ephemeral here)
#   Cache  : 100 GiB  ← max capacity for CacheDisk placement
#
# AKS default OS disk when os_disk_size_gb is omitted = 128 GiB
#
# Result: 128 GiB (default) > 100 GiB (cache) → Azure rejects the request:
#   "The requested ephemeral OS disk size exceeds the VM cache size."
# ─────────────────────────────────────────────────────────────────────────────
variable "node_vm_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = <<-EOT
    VM size for the system node pool.
    Standard_D4s_v3 cache disk = 100 GiB.
    AKS default OS disk        = 128 GiB (os_disk_size_gb not set).
    128 GiB > 100 GiB → ephemeral disk placement will be rejected by Azure.
    Change the VM size to standard_d16s_v5 (cache = 200 GiB, comfortably above 128 GiB).
  EOT
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Initial node count for the system node pool."
}
