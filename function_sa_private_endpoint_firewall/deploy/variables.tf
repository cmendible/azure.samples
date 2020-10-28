variable location {
  default = "west europe"
}

variable resource_group {
  default = "private-webapp"
}

variable sa_name {
  default = "private231418"
}

variable function_required_sa {
  default = "privatefunction231418"
}

variable function_name {
  default = "private-webapp-231418"
}

variable "sa_firewall_enabled" {
  default = false
  type    = bool
}