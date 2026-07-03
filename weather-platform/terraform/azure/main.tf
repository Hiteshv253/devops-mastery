terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
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
  backend "azurerm" {
    # Backend configuration details are provided dynamically via backend-config options during init
  }
}

provider "azurerm" {
  features {}
}

module "azure_infrastructure" {
  source = "../modules/azure"

  location            = var.location
  resource_group_name = var.resource_group_name
  project_name        = var.project_name
  environment         = var.environment
  vm_size             = var.vm_size
  node_count          = var.node_count
  min_count           = var.min_count
  max_count           = var.max_count
}

provider "kubernetes" {
  host                   = module.azure_infrastructure.aks_cluster_endpoint
  client_certificate     = base64decode(module.azure_infrastructure.aks_cluster_client_certificate)
  client_key             = base64decode(module.azure_infrastructure.aks_cluster_client_key)
  cluster_ca_certificate = base64decode(module.azure_infrastructure.aks_cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.azure_infrastructure.aks_cluster_endpoint
    client_certificate     = base64decode(module.azure_infrastructure.aks_cluster_client_certificate)
    client_key             = base64decode(module.azure_infrastructure.aks_cluster_client_key)
    cluster_ca_certificate = base64decode(module.azure_infrastructure.aks_cluster_ca_certificate)
  }
}

module "kubernetes_resources" {
  source = "../modules/kubernetes"

  project_name              = var.project_name
  environment               = var.environment
  groq_api_key              = var.groq_api_key
  storage_class_provisioner = "disk.csi.azure.com"
  storage_class_name        = "standard"
  ingress_class_name        = "webapp-routing"
  docker_image_repository   = "${module.azure_infrastructure.acr_login_server}/weather-platform"
  docker_image_tag          = var.docker_image_tag
  helm_values_file          = "${path.module}/../../helm/weather-platform/values-azure.yaml"
}
