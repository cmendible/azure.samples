# Resource Group Name
variable "resource_group" {
  default = "rg"
}

variable "location" {
  default = "westeurope"
}

# Storage Account name
variable "sa_name" {
  default = "sta"
}

# Function App name
variable "func_name" {
  default = "func"
}

variable "spoke_address_space" {
  default = ["10.6.0.0/16"]
}

variable "vnet_integration_address_prefixes" {
  default = ["10.6.2.0/28"]
}

# Resource Tags
variable "tags" {
  default = {
    env = "test"
  }
}

