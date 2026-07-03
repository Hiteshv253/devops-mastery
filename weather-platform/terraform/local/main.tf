terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "kubernetes_resources" {
  source = "../modules/kubernetes"

  project_name              = var.project_name
  environment               = var.environment
  groq_api_key              = var.groq_api_key
  storage_class_provisioner = "rancher.io/local-path"
  storage_class_name        = "standard"
  ingress_class_name        = "nginx"
  docker_image_tag          = var.docker_image_tag
  helm_values_file          = "${path.module}/../../helm/weather-platform/values-local.yaml"
}
