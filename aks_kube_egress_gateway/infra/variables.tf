variable "resource_group_name" {
  default = "rg-kube-egress-gateway"
}

variable "location" {
  default = "westeurope"
}

variable "cluster_name" {
  default = "aks-kube-egress-gateway"
}

variable "dns_prefix" {
  default = "aks-kube-egress-gateway"
}

variable "log_workspace_name" {
  default = "log-kube-egress-gateway"
}

variable "managed_identity_name" {
  default = "mi-aks"
}
