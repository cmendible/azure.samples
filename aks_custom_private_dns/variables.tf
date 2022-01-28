# Location of the services
variable "location" {
  default = "westeurope"
}

# Resource Group Name
variable "resource_group" {
  default = "aks-enhanced-subnet"
}

# Name of the AKS cluster
variable "aks_name" {
  default = "aks-priavate"
}

variable "private_dns_zone_in_hub" {
  default = false
}
