#!/bin/bash

# AWS Deployment Script for Weather Platform
# This script deploys the weather platform to AWS using Terraform

set -e

echo "=========================================="
echo "Weather Platform - AWS Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
PROJECT_NAME="weather-platform"
ENVIRONMENT=${ENVIRONMENT:-"production"}
DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-"latest"}
GROQ_API_KEY=${GROQ_API_KEY}

# Check required variables
if [ -z "$GROQ_API_KEY" ]; then
    echo -e "${RED}Error: GROQ_API_KEY environment variable is required${NC}"
    echo "Please set it: export GROQ_API_KEY=your_api_key"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi

# Navigate to AWS Terraform directory
cd terraform/aws

# Step 1: Initialize Terraform
echo -e "${YELLOW}Step 1: Initializing Terraform...${NC}"
terraform init \
    -backend-config="bucket=weather-platform-terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate" \
    -backend-config="region=$AWS_REGION"

# Step 2: Create S3 bucket for Terraform state (if not exists)
echo -e "${YELLOW}Step 2: Creating S3 bucket for Terraform state...${NC}"
aws s3api head-bucket --bucket weather-platform-terraform-state --region "$AWS_REGION" 2>/dev/null || \
    aws s3 mb s3://weather-platform-terraform-state --region "$AWS_REGION"

# Create DynamoDB table for state locking (if not exists)
echo -e "${YELLOW}Step 3: Creating DynamoDB table for state locking...${NC}"
aws dynamodb describe-table --table-name weather-platform-terraform-locks --region "$AWS_REGION" 2>/dev/null || \
    aws dynamodb create-table \
        --table-name weather-platform-terraform-locks \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION"

# Re-initialize with backend
echo -e "${YELLOW}Step 4: Re-initializing Terraform with backend...${NC}"
terraform init \
    -backend-config="bucket=weather-platform-terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate" \
    -backend-config="region=$AWS_REGION"

# Step 5: Validate Terraform configuration
echo -e "${YELLOW}Step 5: Validating Terraform configuration...${NC}"
terraform validate

# Step 6: Plan Terraform deployment
echo -e "${YELLOW}Step 6: Planning Terraform deployment...${NC}"
terraform plan \
    -var="aws_region=$AWS_REGION" \
    -var="project_name=$PROJECT_NAME" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -out=tfplan

# Step 7: Apply Terraform deployment
echo -e "${YELLOW}Step 7: Applying Terraform deployment...${NC}"
terraform apply tfplan

# Step 8: Get ECR repository URL
echo -e "${YELLOW}Step 8: Getting ECR repository URL...${NC}"
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
echo "ECR Repository: $ECR_REPO_URL"

# Step 9: Login to ECR
echo -e "${YELLOW}Step 9: Logging in to ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO_URL"

# Step 10: Build Docker image
echo -e "${YELLOW}Step 10: Building Docker image...${NC}"
cd ../..
docker build -t "$PROJECT_NAME:$DOCKER_IMAGE_TAG" .

# Step 11: Tag Docker image for ECR
echo -e "${YELLOW}Step 11: Tagging Docker image for ECR...${NC}"
docker tag "$PROJECT_NAME:$DOCKER_IMAGE_TAG" "$ECR_REPO_URL:$DOCKER_IMAGE_TAG"

# Step 12: Push Docker image to ECR
echo -e "${YELLOW}Step 12: Pushing Docker image to ECR...${NC}"
docker push "$ECR_REPO_URL:$DOCKER_IMAGE_TAG"

# Step 13: Update ECS task definition with new image
echo -e "${YELLOW}Step 13: Updating ECS task definition...${NC}"
cd terraform/aws
terraform apply \
    -var="aws_region=$AWS_REGION" \
    -var="project_name=$PROJECT_NAME" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -auto-approve

# Step 14: Get Load Balancer DNS
echo -e "${YELLOW}Step 14: Getting Load Balancer DNS...${NC}"
LB_DNS=$(terraform output -raw load_balancer_dns)

# Step 15: Wait for deployment to be ready
echo -e "${YELLOW}Step 15: Waiting for deployment to be ready...${NC}"
echo "This may take 5-10 minutes..."
sleep 30

# Check if service is healthy
for i in {1..30}; do
    if curl -f -s "http://$LB_DNS/" > /dev/null 2>&1; then
        echo -e "${GREEN}Deployment successful!${NC}"
        break
    fi
    echo "Waiting for service to be ready... ($i/30)"
    sleep 10
done

# Output deployment information
echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo "Load Balancer DNS: http://$LB_DNS"
echo "ECS Cluster: $(terraform output -raw ecs_cluster_name)"
echo "ECS Service: $(terraform output -raw ecs_service_name)"
echo "ECR Repository: $ECR_REPO_URL"
echo "CloudWatch Logs: $(terraform output -raw cloudwatch_log_group)"
echo "SNS Topic: $(terraform output -raw sns_topic_arn)"
echo ""
echo -e "${YELLOW}To destroy the deployment, run: ./destroy-aws.sh${NC}"
echo "=========================================="
