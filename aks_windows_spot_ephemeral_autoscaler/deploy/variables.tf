variable "resource_group_name" {
  default = "aks-win"
}

variable "location" {
  default = "West Europe"
}

variable "cluster_name" {
  default = "aks-win"
}

variable "dns_prefix" {
  default = "aks-win"
}

variable "agent_count" {
  default = 3
}

variable "log_workspace_name" {
  default = "aks-win-logs"
}
