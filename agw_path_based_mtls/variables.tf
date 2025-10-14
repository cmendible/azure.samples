variable "name" {
  default     = "path_mtls_appgw"
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "spaincentral"
}
