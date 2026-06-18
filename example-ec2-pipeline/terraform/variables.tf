variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Machine Image ID (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Replace with valid regional AMI
}

variable "key_pair_name" {
  description = "Name of the SSH Key Pair in AWS Console to log in"
  type        = string
}
