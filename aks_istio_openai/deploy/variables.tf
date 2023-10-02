variable "resource_group_name" {
  default = "aks-istio-oai"
}

variable "location" {
  default = "West Europe"
}

variable "cluster_name" {
  default = "aks-cfm"
}

variable "dns_prefix" {
  default = "aks-cfm"
}

variable "log_workspace_name" {
  default = "logs-oai"
}

variable "managed_identity_name" {
  default = "aks-workload-identity"
}

variable "aoai_name" {
  default = "openai-cfm"
}

variable "form_recognizer_name" {
  default = "form-cfm"
}

variable "sa_name" {
  default = "openaicfm"
}
