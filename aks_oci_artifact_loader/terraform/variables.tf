variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
  default     = "rg-oci-artifact-demo"
}

variable "location" {
  description = "Azure region. Run `az aks get-versions --location <region>` to verify 1.36 availability."
  type        = string
  default     = "swedencentral"
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name (3-50 alphanumeric characters)."
  type        = string
  # Override with: -var acr_name=myuniqueacr
}

variable "aks_name" {
  description = "AKS cluster name."
  type        = string
  default     = "aks-oci-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version. Must be >= 1.36 for stable image volumes support."
  type        = string
  default     = "1.36"

  validation {
    condition     = tonumber(split(".", var.kubernetes_version)[1]) >= 36
    error_message = "kubernetes_version must be 1.36 or higher. Image volumes are stable in 1.36."
  }
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM SKU for the default node pool. Run `az aks list-vm-skus --location <region>` to verify availability."
  type        = string
  default     = "Standard_D2s_v3"
}
