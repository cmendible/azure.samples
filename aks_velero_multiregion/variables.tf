# Location of the services
variable "location" {
  default = "west europe"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-velero"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aksvelero"
}

# Name of the Servic Principal used by Kubecost
variable "kubecost_sp_name" {
  default = "kubecost"
}

variable "sa_name" {
  default = "aksvelerosa"
}
