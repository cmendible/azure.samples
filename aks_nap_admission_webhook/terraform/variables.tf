variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
  default     = "rg-aks-nap-webhook"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aks-nap-webhook"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.33"
}

variable "system_node_pool_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "system_node_pool_count" {
  description = "Initial node count for the system node pool."
  type        = number
  default     = 2
}

variable "acr_name" {
  description = "Globally unique name for the Azure Container Registry (3-50 alphanumeric chars)."
  type        = string
  default     = "acrnapwebhook"
}

variable "cert_manager_chart_version" {
  description = "Version of the cert-manager Helm chart to install."
  type        = string
  default     = "v1.16.3"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    environment = "dev"
    project     = "aks-nap-admission-webhook"
  }
}
