variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Replace with your regional Amazon Linux 2023 AMI
}

variable "key_pair_name" {
  description = "AWS EC2 Key Pair Name for SSH access"
  type        = string
}
