terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "weather-platform-terraform"
    storage_account_name = "weatherplatformtfstate"
    container_name       = "terraform-state"
    key                  = "weather-platform/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
