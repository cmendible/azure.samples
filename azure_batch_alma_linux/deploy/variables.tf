variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "swedencentral"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "batch-alma"
}

variable "batch_pool_vm_size" {
  description = "VM size for the Batch pool nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "batch_pool_node_count" {
  description = "Number of dedicated nodes in the Batch pool"
  type        = number
  default     = 1
}
