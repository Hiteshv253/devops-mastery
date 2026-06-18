# Remote State Backend Configuration (MNC Standard)
# Stores TF state in S3 and uses DynamoDB for state locking.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # In MNC environments, backend parameters are usually injected dynamically 
  # via `-backend-config=backend.hcl` during `terraform init` to avoid hardcoding.
  # Below is the standard declaration for AWS S3 and DynamoDB:
  
  # backend "s3" {
  #   bucket         = "mnc-devops-tfstate-bucket"
  #   key            = "dev/vpc/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-locks"
  #   encrypt        = true
  # }

  # For local learning/testing, we fallback to a local backend:
  backend "local" {
    path = "terraform.tfstate"
  }
}
