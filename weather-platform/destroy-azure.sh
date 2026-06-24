#!/bin/bash

# Azure Destroy Script for Weather Platform
# This script destroys all Azure resources created by Terraform

set -e

echo "=========================================="
echo "Weather Platform - Azure Destroy"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-"weather-platform-rg"}
STORAGE_ACCOUNT_NAME="weatherplatformtfstate"

# Check Azure CLI
echo -e "${YELLOW}Checking Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not installed${NC}"
    exit 1
fi

# Check Azure login
echo -e "${YELLOW}Checking Azure login...${NC}"
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

# Navigate to Azure Terraform directory
cd terraform/azure

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init \
    -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
    -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate"

# Warning
echo -e "${RED}WARNING: This will destroy all Azure resources in $RESOURCE_GROUP_NAME${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destroy cancelled."
    exit 0
fi

# Destroy Terraform resources
echo -e "${YELLOW}Destroying Terraform resources...${NC}"
terraform destroy \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -auto-approve

# Delete storage account
echo -e "${YELLOW}Deleting storage account...${NC}"
az storage account delete \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --yes

# Delete resource group
echo -e "${YELLOW}Deleting resource group...${NC}"
az group delete \
    --name "$RESOURCE_GROUP_NAME" \
    --yes

echo ""
echo "=========================================="
echo -e "${GREEN}Destroy Complete!${NC}"
echo "=========================================="
echo "All Azure resources have been destroyed."
echo "=========================================="
