variable location {
  default = "west europe"
}

variable resource_group {
  default = "private-endpoint"
}

variable sa_name {
  default = "privatecfm"
}

variable "sa_services" {
  default = ["blob", "table", "queue", "file"]
  type    = list
}

variable "sa_firewall_enabled" {
  default = true
  type    = bool
}
