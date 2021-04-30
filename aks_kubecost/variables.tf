# Location of the services
variable "location" {
  default = "west europe"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-kubecost"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aksmsftkubecost"
}

# Name of the Servic Principal used by Kubecost
variable "kubecost_sp_name" {
  default = "kubecost"
}