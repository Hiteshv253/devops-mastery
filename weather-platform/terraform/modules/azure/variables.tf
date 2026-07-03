variable "location" {
  type        = string
  description = "Azure region"
  default     = "EastUS"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
  default     = "weather-platform-rg"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "weather-platform"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_D2s_v5"
}

variable "node_count" {
  type        = number
  description = "AKS system node pool count"
  default     = 2
}

variable "min_count" {
  type        = number
  description = "AKS node autoscaler min count"
  default     = 2
}

variable "max_count" {
  type        = number
  description = "AKS node autoscaler max count"
  default     = 5
}
