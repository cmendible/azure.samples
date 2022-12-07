# Location of the services
variable "location" {
  default = "uksouth"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-backup"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aksbackup"
}

# Name of the Servic Principal used by Kubecost
variable "kubecost_sp_name" {
  default = "kubecost"
}

variable "sa_name" {
  default = "aksbackup2314"
}

