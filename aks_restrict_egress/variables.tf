# Location of the services
variable "location" {
  default = "spain central"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-restricted-egress"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-restricted-egress"
}
