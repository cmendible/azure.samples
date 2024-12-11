variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-func-flex"
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "northeurope"
}

variable "function_name" {
  description = "The name of the azure function"
  type        = string
  default     = "func-flex"
}

variable "plan_name" {
  description = "The name of the app service plan"
  type        = string
  default     = "plan-func-flex"
}

variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
  default     = "stfuncflex"
}

variable "log_name" {
  description = "The name of the log analytics workspace"
  type        = string
  default     = "log-func-flex"
}

variable "appi_name" {
  description = "The name of the application insights"
  type        = string
  default     = "appi-func-flex"
}
