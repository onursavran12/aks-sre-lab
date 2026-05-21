variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aks-sre-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Null means Azure default."
  type        = string
  default     = null
}

variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_B2ms"
}

variable "user_node_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_B2ms"
}

variable "user_node_min_count" {
  description = "Minimum user nodes"
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum user nodes"
  type        = number
  default     = 2
}
