variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2023 in us-east-1)"
  type        = string
  default     = "ami-0b6d9d3d33ba97d99" 
}

variable "instance_type" {
  description = "EC2 Instance Size"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of AWS SSH Key Pair (Optional, leave blank to launch without key)"
  type        = string
  default     = null
}
