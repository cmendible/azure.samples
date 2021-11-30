variable "location" {
  default = "west central us"
}

variable "resource_group" {
  default = "func-custom-dns"
}

variable "func_name" {
  default = "func"
}

variable "sa_name" {
  default = "privatesta"
}

variable "sa_services" {
  default = ["blob", "table", "queue", "file"]
  type    = list(any)
}

variable "enable_firewall" {
  default = true
  type    = bool
}
