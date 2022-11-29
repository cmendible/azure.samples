variable "resource_group_name" {}
variable "location" {}

variable "spoke_address_space" {
  default = []
}

variable "vnet_integration_address_prefixes" {
  default = []
}

variable "tags" {
  default = {}
}
