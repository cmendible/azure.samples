# Location of the services
variable "location" {
  default = "west europe"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-no-local-accounts"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aksnolocalaccounts"
}

variable "sp_name" {
  default = "aksnolocalaccounts"
}
