# Location of the services
variable "location" {
  default = "westeurope"
}

# Resource Group Name
variable "resource_group" {
  default = "soft-delete-kv-firewall-policy"
}

variable "key_vault_name" {
  default = "cfmkv23"
}
