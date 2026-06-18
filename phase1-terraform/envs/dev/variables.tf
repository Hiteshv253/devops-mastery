variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for dev VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnets" {
  description = "Public subnets list"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnets list"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "availability_zones" {
  description = "AZs list"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
