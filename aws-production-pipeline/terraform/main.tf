# Simple learning Terraform code with a self-contained custom VPC network 
# (This guarantees successful deployment even if your AWS account has no default VPC subnets)

terraform {
  required_version = ">= 1.0.0"
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

# 1. Custom VPC for network isolation
resource "aws_vpc" "learning_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "learning-vpc"
  }
}

# 2. Public Subnet inside our VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.learning_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Automatically assigns a public IP to EC2 instances

  tags = {
    Name = "learning-subnet"
  }
}

# 3. Internet Gateway (Allows traffic to flow in/out of the VPC)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.learning_vpc.id

  tags = {
    Name = "learning-igw"
  }
}

# 4. Route Table (Directs outbound traffic to the Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.learning_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "learning-route-table"
  }
}

# 5. Connect our Route Table to our Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Security Group (Created inside our Custom VPC)
resource "aws_security_group" "web_sg" {
  name        = "simple-web-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.learning_vpc.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simple-sg"
  }
}

# 7. UAT EC2 Instance (Placed in our custom subnet)
resource "aws_instance" "uat_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name        = "uat-ec2-server"
    Environment = "UAT"
  }
}

# 8. Production EC2 Instance (Placed in our custom subnet)
resource "aws_instance" "prod_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name        = "production-ec2-server"
    Environment = "Production"
  }
}
