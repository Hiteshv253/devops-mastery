terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    # Backend configuration details are provided dynamically via backend-config options during init
  }
}

provider "aws" {
  region = var.aws_region
}

module "aws_infrastructure" {
  source = "../modules/aws"

  aws_region     = var.aws_region
  project_name   = var.project_name
  environment    = var.environment
  instance_types = var.instance_types
  desired_size   = var.desired_size
  min_size       = var.min_size
  max_size       = var.max_size
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.aws_infrastructure.eks_cluster_name
}

provider "kubernetes" {
  host                   = module.aws_infrastructure.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.aws_infrastructure.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.aws_infrastructure.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.aws_infrastructure.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "kubernetes_resources" {
  source = "../modules/kubernetes"

  project_name              = var.project_name
  environment               = var.environment
  groq_api_key              = var.groq_api_key
  storage_class_provisioner = "kubernetes.io/aws-ebs"
  storage_class_name        = "standard"
  ingress_class_name        = "alb"
  docker_image_repository   = module.aws_infrastructure.ecr_repository_url
  docker_image_tag          = var.docker_image_tag
  helm_values_file          = "${path.module}/../../helm/weather-platform/values-aws.yaml"
}
