variable "resource_group_name" {
  default = "aks-workload-identity"
}

variable "location" {
  default = "West Europe"
}

variable "cluster_name" {
  default = "aks-cfm"
}

variable "dns_prefix" {
  default = "aks-cfm"
}

variable "log_workspace_name" {
  default = "aks-cfm-logs"
}

variable "managed_identity_name" {
  default = "aks-workload-identity"
}
