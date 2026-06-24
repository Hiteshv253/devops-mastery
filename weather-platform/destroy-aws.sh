#!/bin/bash

# AWS Destroy Script for Weather Platform
# This script destroys all AWS resources created by Terraform

set -e

echo "=========================================="
echo "Weather Platform - AWS Destroy"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
PROJECT_NAME="weather-platform"

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi

# Navigate to AWS Terraform directory
cd terraform/aws

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init \
    -backend-config="bucket=weather-platform-terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate" \
    -backend-config="region=$AWS_REGION"

# Warning
echo -e "${RED}WARNING: This will destroy all AWS resources for $PROJECT_NAME${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destroy cancelled."
    exit 0
fi

# Destroy Terraform resources
echo -e "${YELLOW}Destroying Terraform resources...${NC}"
terraform destroy \
    -var="aws_region=$AWS_REGION" \
    -var="project_name=$PROJECT_NAME" \
    -auto-approve

# Empty and delete S3 bucket
echo -e "${YELLOW}Emptying S3 bucket...${NC}"
aws s3 rm s3://weather-platform-terraform-state --recursive --region "$AWS_REGION"

echo -e "${YELLOW}Deleting S3 bucket...${NC}"
aws s3 rb s3://weather-platform-terraform-state --region "$AWS_REGION"

# Delete DynamoDB table
echo -e "${YELLOW}Deleting DynamoDB table...${NC}"
aws dynamodb delete-table --table-name weather-platform-terraform-locks --region "$AWS_REGION"

echo ""
echo "=========================================="
echo -e "${GREEN}Destroy Complete!${NC}"
echo "=========================================="
echo "All AWS resources have been destroyed."
echo "=========================================="
