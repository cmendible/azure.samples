# Location of the services
variable "location" {
  default = "northeurope"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-restricted"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-restricted-egress"
}
