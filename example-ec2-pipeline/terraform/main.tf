# Infrastructure Configuration for Dev & Prod EC2 Instances
provider "aws" {
  region = var.aws_region
}

# 1. Security Group for Dev and Prod EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-app-sg"
  description = "Security group for App instances"

  # SSH Access (For administration and pipeline deployment)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict to corporate VPN or GitHub Runner IPs
  }

  # HTTP Port for Development instance
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Port for Production instance
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules (Allow internet access to download updates/packages)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "devops-ec2-sg"
  }
}

# 2. Development EC2 Instance
resource "aws_instance" "dev_server" {
  ami           = var.ami_id # Amazon Linux 2023 or Ubuntu
  instance_type = "t2.micro" # Free-tier eligible
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = "dev-ec2-instance"
    Environment = "development"
    Project     = "DevOps-Mastery"
  }

  # User data to automatically install and run docker/webserver
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              EOF
}

# 3. Production EC2 Instance
resource "aws_instance" "prod_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name        = "prod-ec2-instance"
    Environment = "production"
    Project     = "DevOps-Mastery"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              EOF
}
