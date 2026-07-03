variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
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

variable "instance_types" {
  type        = list(string)
  description = "EKS node group instance types"
  default     = ["t3.medium"]
}

variable "desired_size" {
  type        = number
  description = "Desired number of EKS worker nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of EKS worker nodes"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of EKS worker nodes"
  default     = 5
}
