#!/bin/bash

# Azure Deployment Script for Weather Platform
# This script deploys the weather platform to Azure using Terraform

set -e

echo "=========================================="
echo "Weather Platform - Azure Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-"weather-platform-rg"}
LOCATION=${LOCATION:-"East US"}
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

# Check Azure CLI
echo -e "${YELLOW}Checking Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not installed${NC}"
    echo "Please install it: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Azure login
echo -e "${YELLOW}Checking Azure login...${NC}"
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

# Set Azure subscription
echo -e "${YELLOW}Setting Azure subscription...${NC}"
az account set --subscription $(az account show --query id -o tsv)

# Navigate to Azure Terraform directory
cd terraform/azure

# Step 1: Create resource group
echo -e "${YELLOW}Step 1: Creating resource group...${NC}"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags "Project=$PROJECT_NAME" "Environment=$ENVIRONMENT"

# Step 2: Create storage account for Terraform state
echo -e "${YELLOW}Step 2: Creating storage account for Terraform state...${NC}"
STORAGE_ACCOUNT_NAME="weatherplatformtfstate"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --allow-blob-public-access false

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

# Create container for Terraform state
echo -e "${YELLOW}Step 3: Creating container for Terraform state...${NC}"
az storage container create \
    --name terraform-state \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$STORAGE_KEY"

# Step 4: Initialize Terraform
echo -e "${YELLOW}Step 4: Initializing Terraform...${NC}"
terraform init \
    -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
    -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate"

# Step 5: Validate Terraform configuration
echo -e "${YELLOW}Step 5: Validating Terraform configuration...${NC}"
terraform validate

# Step 6: Plan Terraform deployment
echo -e "${YELLOW}Step 6: Planning Terraform deployment...${NC}"
terraform plan \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -var="location=$LOCATION" \
    -var="project_name=$PROJECT_NAME" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -out=tfplan

# Step 7: Apply Terraform deployment
echo -e "${YELLOW}Step 7: Applying Terraform deployment...${NC}"
terraform apply tfplan

# Step 8: Get ACR credentials
echo -e "${YELLOW}Step 8: Getting ACR credentials...${NC}"
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(az acr credential show \
    --name $(echo "$ACR_LOGIN_SERVER" | cut -d'.' -f1) \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query passwords[0].value -o tsv)

echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "ACR Username: $ACR_USERNAME"

# Step 9: Login to ACR
echo -e "${YELLOW}Step 9: Logging in to ACR...${NC}"
echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin

# Step 10: Build Docker image
echo -e "${YELLOW}Step 10: Building Docker image...${NC}"
cd ../..
docker build -t "$PROJECT_NAME:$DOCKER_IMAGE_TAG" .

# Step 11: Tag Docker image for ACR
echo -e "${YELLOW}Step 11: Tagging Docker image for ACR...${NC}"
docker tag "$PROJECT_NAME:$DOCKER_IMAGE_TAG" "$ACR_LOGIN_SERVER/$PROJECT_NAME:$DOCKER_IMAGE_TAG"

# Step 12: Push Docker image to ACR
echo -e "${YELLOW}Step 12: Pushing Docker image to ACR...${NC}"
docker push "$ACR_LOGIN_SERVER/$PROJECT_NAME:$DOCKER_IMAGE_TAG"

# Step 13: Update App Service with new image
echo -e "${YELLOW}Step 13: Updating App Service with new image...${NC}"
cd terraform/azure
terraform apply \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -var="location=$LOCATION" \
    -var="project_name=$PROJECT_NAME" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -auto-approve

# Step 14: Get App Service URL
echo -e "${YELLOW}Step 14: Getting App Service URL...${NC}"
APP_SERVICE_URL=$(terraform output -raw app_service_default_hostname)

# Step 15: Wait for deployment to be ready
echo -e "${YELLOW}Step 15: Waiting for deployment to be ready...${NC}"
echo "This may take 5-10 minutes..."
sleep 30

# Check if service is healthy
for i in {1..30}; do
    if curl -f -s "https://$APP_SERVICE_URL/" > /dev/null 2>&1; then
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
echo "App Service URL: https://$APP_SERVICE_URL"
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "Key Vault URI: $(terraform output -raw key_vault_uri)"
echo "Application Insights Key: $(terraform output -raw application_insights_instrumentation_key)"
echo ""
echo -e "${YELLOW}To destroy the deployment, run: ./destroy-azure.sh${NC}"
echo "=========================================="
