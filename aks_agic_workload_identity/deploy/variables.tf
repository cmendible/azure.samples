variable "resource_group_name" {
  default = "aks-workload-identity"
}

variable "location" {
  default = "North Europe"
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

variable "gateway_name" {
  default = "appgw-cfm"
}

