# Location of the services
variable "location" {
  default = "northeurope"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-private"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-private"
}
