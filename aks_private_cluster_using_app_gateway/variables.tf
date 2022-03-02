# Location of the services
variable "location" {
  default = "westeurope"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-private-app-gateway"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-private"
}

variable "domain_name_label" {
  default = "cfm23"
}
