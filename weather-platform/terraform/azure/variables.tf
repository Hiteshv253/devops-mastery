variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "weather-platform-rg"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "weather-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "groq_api_key" {
  description = "Groq API key for AI services"
  type        = string
  sensitive   = true
}

variable "sku_tier" {
  description = "SKU tier for App Service"
  type        = string
  default     = "Standard"
}

variable "sku_size" {
  description = "SKU size for App Service"
  type        = string
  default     = "S1"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 5
}
