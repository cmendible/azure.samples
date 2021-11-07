# Location of the services
variable "location" {
  default = "west europe"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-openebs"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-openebs"
}
