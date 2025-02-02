variable "resource_group_name" {
  default = "rg-aso-demo"
}

variable "location" {
  default = "northeurope"
}

variable "cluster_name" {
  default = "aks-aso"
}

variable "dns_prefix" {
  default = "aks-aso"
}

variable "managed_identity_name" {
  default = "aks-workload-identity"
}
