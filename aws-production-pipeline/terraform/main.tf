# Complete AWS Infrastructure for Development and Production Environments
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Custom VPC for Isolation
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops-realtime-vpc"
  }
}

# 2. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "devops-igw"
  }
}

# 4. Route Table for Internet Gateway routing
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "devops-public-rt"
  }
}

# 5. Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. AWS Elastic Container Registry (ECR) for storing Docker images
resource "aws_ecr_repository" "app_repo" {
  name                 = "devops-realtime-app"
  image_tag_mutability = "MUTABLE"
 //force_destroy        = true # Allows automatic deletion via terraform destroy even if contains images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devops-app-ecr"
  }
}

# 7. Security Group for EC2 Web Servers
resource "aws_security_group" "web_sg" {
  name        = "devops-web-sg"
  description = "Security group for Dev and Prod web servers"
  vpc_id      = aws_vpc.devops_vpc.id

  # SSH for deployment
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Dev Port (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prod Port (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. IAM Role for EC2 instances to pull from ECR
resource "aws_iam_role" "ec2_ecr_role" {
  name = "devops-ec2-ecr-pull-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach ECR ReadOnly policy to the role
resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach SSM Core policy for keyless Systems Manager Run Command
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile to attach the role to EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devops-ec2-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# 9. Development EC2 Instance
resource "aws_instance" "dev_ec2" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.key_pair_name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name        = "dev-ec2-server"
    Environment = "development"
  }
}

# 10. Production EC2 Instance
resource "aws_instance" "prod_ec2" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.key_pair_name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name        = "prod-ec2-server"
    Environment = "production"
  }
}
