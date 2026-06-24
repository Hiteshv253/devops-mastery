# Cloud Deployment Guide - Weather Platform

This guide provides step-by-step instructions for deploying the Weather Platform to AWS and Azure using Terraform with one-click deployment scripts.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [AWS Deployment](#aws-deployment)
- [Azure Deployment](#azure-deployment)
- [Architecture Overview](#architecture-overview)
- [Cost Estimation](#cost-estimation)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### For AWS Deployment

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   ```bash
   # Install AWS CLI
   pip install awscli
   
   # Configure AWS CLI
   aws configure
   ```

3. **Terraform** installed (>= 1.0)
   ```bash
   # Download from: https://www.terraform.io/downloads.html
   # Or use: brew install terraform (macOS)
   # Or use: choco install terraform (Windows)
   ```

4. **Docker** installed and running
5. **Git** installed

### For Azure Deployment

1. **Azure Account** with appropriate permissions
2. **Azure CLI** installed and configured
   ```bash
   # Install Azure CLI
   # Windows: winget install -e --id Microsoft.AzureCLI
   # macOS: brew install azure-cli
   # Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Login to Azure
   az login
   ```

3. **Terraform** installed (>= 1.0)
4. **Docker** installed and running
5. **Git** installed

### Common Prerequisites

- **GROQ API Key** - Set as environment variable
  ```bash
  export GROQ_API_KEY=your_api_key_here
  ```

---

## AWS Deployment

### Quick Start (One-Click Deployment)

```bash
# Navigate to project directory
cd weather-platform

# Set required environment variables
export GROQ_API_KEY=your_api_key_here
export AWS_REGION=us-east-1

# Run deployment script
chmod +x deploy-aws.sh
./deploy-aws.sh
```

### Manual Deployment Steps

#### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter default output format (json)
```

#### Step 2: Set Environment Variables

```bash
export GROQ_API_KEY=your_api_key_here
export AWS_REGION=us-east-1
export ENVIRONMENT=production
export DOCKER_IMAGE_TAG=latest
```

#### Step 3: Navigate to AWS Terraform Directory

```bash
cd terraform/aws
```

#### Step 4: Initialize Terraform

```bash
terraform init \
    -backend-config="bucket=weather-platform-terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate" \
    -backend-config="region=$AWS_REGION"
```

#### Step 5: Plan Deployment

```bash
terraform plan \
    -var="aws_region=$AWS_REGION" \
    -var="project_name=weather-platform" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -out=tfplan
```

#### Step 6: Apply Deployment

```bash
terraform apply tfplan
```

#### Step 7: Build and Push Docker Image

```bash
# Get ECR repository URL
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REPO_URL

# Build image
cd ../..
docker build -t weather-platform:$DOCKER_IMAGE_TAG .

# Tag image
docker tag weather-platform:$DOCKER_IMAGE_TAG $ECR_REPO_URL:$DOCKER_IMAGE_TAG

# Push image
docker push $ECR_REPO_URL:$DOCKER_IMAGE_TAG
```

#### Step 8: Update ECS Service

```bash
cd terraform/aws
terraform apply -auto-approve
```

### AWS Resources Created

- **VPC** with public and private subnets
- **Application Load Balancer** for traffic distribution
- **ECS Cluster** with Fargate
- **ECR Repository** for Docker images
- **Auto Scaling** (2-5 instances based on CPU/memory)
- **CloudWatch** for logs and monitoring
- **Secrets Manager** for API keys
- **SNS Topic** for alerts

### Access Your Application

```bash
# Get Load Balancer DNS
terraform output load_balancer_dns

# Access application
http://<load-balancer-dns>/
```

### Destroy AWS Resources

```bash
# Using destroy script
chmod +x destroy-aws.sh
./destroy-aws.sh

# Or manually
cd terraform/aws
terraform destroy -auto-approve
```

---

## Azure Deployment

### Quick Start (One-Click Deployment)

```bash
# Navigate to project directory
cd weather-platform

# Set required environment variables
export GROQ_API_KEY=your_api_key_here
export LOCATION=EastUS

# Run deployment script
chmod +x deploy-azure.sh
./deploy-azure.sh
```

### Manual Deployment Steps

#### Step 1: Login to Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

#### Step 2: Set Environment Variables

```bash
export GROQ_API_KEY=your_api_key_here
export LOCATION=EastUS
export RESOURCE_GROUP_NAME=weather-platform-rg
export ENVIRONMENT=production
export DOCKER_IMAGE_TAG=latest
```

#### Step 3: Navigate to Azure Terraform Directory

```bash
cd terraform/azure
```

#### Step 4: Create Resource Group

```bash
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION
```

#### Step 5: Create Storage Account for Terraform State

```bash
STORAGE_ACCOUNT_NAME="weatherplatformtfstate"
az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --sku Standard_LRS
```

#### Step 6: Initialize Terraform

```bash
terraform init \
    -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
    -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=terraform-state" \
    -backend-config="key=weather-platform/terraform.tfstate"
```

#### Step 7: Plan Deployment

```bash
terraform plan \
    -var="resource_group_name=$RESOURCE_GROUP_NAME" \
    -var="location=$LOCATION" \
    -var="project_name=weather-platform" \
    -var="environment=$ENVIRONMENT" \
    -var="docker_image_tag=$DOCKER_IMAGE_TAG" \
    -var="groq_api_key=$GROQ_API_KEY" \
    -out=tfplan
```

#### Step 8: Apply Deployment

```bash
terraform apply tfplan
```

#### Step 9: Build and Push Docker Image

```bash
# Get ACR credentials
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(az acr credential show \
    --name $(echo $ACR_LOGIN_SERVER | cut -d'.' -f1) \
    --resource-group $RESOURCE_GROUP_NAME \
    --query passwords[0].value -o tsv)

# Login to ACR
echo $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER -u $ACR_USERNAME --password-stdin

# Build image
cd ../..
docker build -t weather-platform:$DOCKER_IMAGE_TAG .

# Tag image
docker tag weather-platform:$DOCKER_IMAGE_TAG $ACR_LOGIN_SERVER/weather-platform:$DOCKER_IMAGE_TAG

# Push image
docker push $ACR_LOGIN_SERVER/weather-platform:$DOCKER_IMAGE_TAG
```

#### Step 10: Update App Service

```bash
cd terraform/azure
terraform apply -auto-approve
```

### Azure Resources Created

- **Resource Group** for organizing resources
- **Container Registry (ACR)** for Docker images
- **App Service Plan** with Linux
- **Web App** for container hosting
- **Key Vault** for secrets management
- **Application Insights** for monitoring
- **Log Analytics Workspace** for logs
- **Auto Scaling** (2-5 instances based on CPU)
- **Virtual Network** with subnet

### Access Your Application

```bash
# Get App Service URL
terraform output app_service_default_hostname

# Access application
https://<app-service-name>.azurewebsites.net/
```

### Destroy Azure Resources

```bash
# Using destroy script
chmod +x destroy-azure.sh
./destroy-azure.sh

# Or manually
cd terraform/azure
terraform destroy -auto-approve
az group delete --name $RESOURCE_GROUP_NAME --yes
```

---

## Architecture Overview

### AWS Architecture

```
                    Internet
                        |
                        v
                [Load Balancer]
                        |
            +-----------+-----------+
            |                       |
        [Public Subnet 1]      [Public Subnet 2]
            |                       |
        [NAT Gateway 1]        [NAT Gateway 2]
            |                       |
        [Private Subnet 1]     [Private Subnet 2]
            |                       |
    +-------+-------+       +-------+-------+
    |               |       |               |
[ECS Task 1]   [ECS Task 2] [ECS Task 3] [ECS Task 4]
    |               |       |               |
    +-------+-------+       +-------+-------+
            |
    [Secrets Manager]
            |
    [CloudWatch Logs]
```

### Azure Architecture

```
                    Internet
                        |
                        v
                [Azure Front Door]
                        |
                        v
                [App Service]
                        |
            +-----------+-----------+
            |                       |
        [Instance 1]           [Instance 2]
            |                       |
            +-----------+-----------+
                        |
                [Key Vault]
                        |
                [Application Insights]
```

---

## Cost Estimation

### AWS Monthly Cost Estimate (us-east-1)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| ECS Fargate | 2-5 instances, 0.5 vCPU, 1GB | $20-50 |
| Application Load Balancer | Standard | $18-20 |
| NAT Gateway | 2 gateways | $32-35 |
| ECR | 500GB storage | $5-10 |
| CloudWatch Logs | 5GB logs | $2-5 |
| Secrets Manager | 1 secret | $0.40 |
| Data Transfer | 100GB | $9 |
| **Total** | | **$86-129/month** |

### Azure Monthly Cost Estimate (East US)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| App Service Plan | S1 (1 core, 1.75GB) | $74-90 |
| Container Registry | Standard | $5-10 |
| Application Insights | Basic | $0-25 |
| Key Vault | Standard | $0.03 |
| Log Analytics | 5GB data | $10-15 |
| Data Transfer | 100GB | $8-12 |
| **Total** | | **$97-152/month** |

*Note: Costs are estimates and may vary based on usage and region*

---

## Configuration Options

### AWS Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region |
| `project_name` | weather-platform | Project name |
| `environment` | production | Environment name |
| `docker_image_tag` | latest | Docker image tag |
| `instance_type` | t3.medium | EC2 instance type |
| `min_instances` | 2 | Minimum instances |
| `max_instances` | 5 | Maximum instances |

### Azure Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | East US | Azure region |
| `resource_group_name` | weather-platform-rg | Resource group name |
| `project_name` | weather-platform | Project name |
| `environment` | production | Environment name |
| `docker_image_tag` | latest | Docker image tag |
| `sku_tier` | Standard | App Service tier |
| `sku_size` | S1 | App Service size |
| `min_instances` | 2 | Minimum instances |
| `max_instances` | 5 | Maximum instances |

---

## Monitoring and Logging

### AWS Monitoring

- **CloudWatch Logs**: View application logs
  ```bash
  aws logs tail /ecs/weather-platform --follow
  ```

- **CloudWatch Metrics**: View CPU, memory metrics
  ```bash
  aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=weather-platform-service
  ```

- **SNS Alerts**: Configure email notifications in Terraform

### Azure Monitoring

- **Application Insights**: View logs and metrics in Azure Portal
- **Log Analytics**: Query logs using KQL
  ```kql
  AppLogs
  | where TimeGenerated > ago(1h)
  | order by TimeGenerated desc
  ```

- **Alert Rules**: Auto-configured for high CPU/memory

---

## Troubleshooting

### AWS Issues

#### ECS Tasks Not Starting

```bash
# Check task status
aws ecs describe-tasks \
    --cluster weather-platform-cluster \
    --tasks <task-id>

# Check task logs
aws logs tail /ecs/weather-platform --follow
```

#### Load Balancer Health Checks Failing

```bash
# Check target group health
aws elbv2 describe-target-health \
    --target-group-arn <target-group-arn>

# Verify security groups allow traffic
aws ec2 describe-security-groups \
    --group-ids <security-group-id>
```

#### ECR Push Fails

```bash
# Verify ECR login
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin <ecr-url>

# Check image exists
aws ecr describe-images --repository-name weather-platform
```

### Azure Issues

#### App Service Not Starting

```bash
# Check app service logs
az webapp log tail \
    --name weather-platform-app \
    --resource-group weather-platform-rg

# Check deployment status
az webapp config container show \
    --name weather-platform-app \
    --resource-group weather-platform-rg
```

#### ACR Pull Fails

```bash
# Verify ACR login
az acr login --name <acr-name>

# Check image exists
az acr repository show-tags \
    --name <acr-name> \
    --repository weather-platform
```

#### Key Vault Access Issues

```bash
# Check managed identity
az webapp identity show \
    --name weather-platform-app \
    --resource-group weather-platform-rg

# Verify key vault access policy
az keyvault show \
    --name <key-vault-name> \
    --resource-group weather-platform-rg
```

---

## Security Best Practices

1. **Never commit API keys** - Use environment variables or secret managers
2. **Enable VPC endpoints** for AWS to keep traffic private
3. **Use managed identities** for Azure instead of service principals
4. **Enable encryption** at rest and in transit
5. **Regularly rotate secrets** and credentials
6. **Use least privilege** IAM/RBAC policies
7. **Enable audit logging** for all resources
8. **Scan Docker images** for vulnerabilities

---

## Advanced Configuration

### Custom Domain (AWS)

```bash
# Add custom domain to load balancer
aws elbv2 add-tags \
    --resource-arns <load-balancer-arn> \
    --tags Key=Domain,Value=example.com

# Configure Route53
aws route53 change-resource-record-sets \
    --hosted-zone-id <zone-id> \
    --change-batch file://route53.json
```

### Custom Domain (Azure)

```bash
# Add custom domain to app service
az webapp config hostname add \
    --name weather-platform-app \
    --resource-group weather-platform-rg \
    --hostname example.com

# Configure SSL certificate
az webapp config ssl bind \
    --name weather-platform-app \
    --resource-group weather-platform-rg \
    --certificate-thumbprint <thumbprint>
```

### CI/CD Integration

#### GitHub Actions (AWS)

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-region: us-east-1
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}

- name: Deploy to AWS
  run: ./deploy-aws.sh
```

#### GitHub Actions (Azure)

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}

- name: Deploy to Azure
  run: ./deploy-azure.sh
```

---

## Support

For issues or questions:
- Check Terraform logs in `terraform/aws/` or `terraform/aws/`
- Review CloudWatch/Application Insights logs
- Verify all prerequisites are met
- Ensure API keys are correctly set

---

## License

This deployment configuration is provided as-is for the Weather Platform project.
