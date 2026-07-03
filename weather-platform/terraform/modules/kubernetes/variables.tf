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

variable "groq_api_key" {
  type        = string
  description = "Groq API Key"
  default     = "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"
}

variable "storage_class_provisioner" {
  type        = string
  description = "Storage class provisioner type"
  default     = "rancher.io/local-path" # default for local k8s bootstrap
}

variable "storage_class_name" {
  type        = string
  description = "Storage class name"
  default     = "standard"
}

variable "ingress_class_name" {
  type        = string
  description = "Ingress class name"
  default     = "nginx"
}

variable "helm_values_file" {
  type        = string
  description = "Path to environment specific helm values file"
  default     = ""
}

variable "docker_image_repository" {
  type        = string
  description = "App Docker Image Repository"
  default     = "ghcr.io/hiteshv253/devops-mastery/weather-platform"
}

variable "docker_image_tag" {
  type        = string
  description = "App Docker Image Tag"
  default     = "latest"
}
