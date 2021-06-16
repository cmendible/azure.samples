variable "resource_group_name" {
  default = "aks-signalr-server"
}

variable "managed_identity_name" {
  default = "signalr"
}

variable "managed_identity_selector" {
  default = "reads-vault"
}

variable "location" {
  default = "West Europe"
}

variable "cluster_name" {
  default = "aks-signalr-server"
}

variable "dns_prefix" {
  default = "aks-signalr-server"
}

variable "agent_count" {
  default = 3
}

variable "key_vault_name" {
  default = "aks-signalr-war-kv"
}