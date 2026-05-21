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
  default     = "shared"
}
