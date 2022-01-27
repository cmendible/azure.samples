variable "location" {
  default = "west europe"
}

variable "resource_group" {
  default = "private-endpoint"
}

variable "sa_name" {
  default = "privatecfm"
}

variable "func_name" {
  default = "func-pe-test"
}

variable "sa_services" {
  default = ["blob", "table", "queue", "file"]
  type    = list(any)
}
