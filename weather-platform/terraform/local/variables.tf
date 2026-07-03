variable "project_name" {
  type        = string
  description = "Project name"
  default     = "weather-platform"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "local"
}

variable "groq_api_key" {
  type        = string
  description = "Groq API Key"
  sensitive   = true
}


variable "docker_image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}
