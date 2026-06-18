# AWS Enterprise Real-Time Deployment Pipeline

This folder contains a complete, automated DevOps setup mimicking a real production workflow inside major MNC companies. It uses **Python, Terraform, Docker, ECR, and AWS Systems Manager (SSM)** to deploy an application to isolated Development and Production EC2 servers without using any SSH Keys!

---

## Direct Link to Code Files
- **Terraform Configuration**: [terraform/main.tf](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/terraform/main.tf)
- **App Dockerfile**: [app/Dockerfile](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/app/Dockerfile)
- **Python Orchestrator**: [aws_orchestrator.py](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/aws_orchestrator.py)

---

## Why this is "MNC-Standard" Architecture

1. **Security Isolation (VPC)**: The resources are deployed inside a custom VPC (`10.20.0.0/16`) to isolate them from other projects.
2. **Keyless Deployment (SSM)**: We do NOT use SSH keys to deploy code. Instead, we use **AWS Systems Manager (SSM) Run Command**. This is a massive enterprise security standard because:
   - We don't have to manage SSH keys (`.pem` files).
   - We don't need to expose Port 22 to the public internet.
   - The deployment is triggered directly by the secure AWS SSM Agent running inside the EC2 instance.
3. **Role-Based Security (IAM Instance Profile)**: The EC2 instances are attached to an IAM Role (`devops-ec2-ecr-pull-role`) that has policies to pull images from **Amazon ECR** and register with **SSM**. We do not hardcode any credentials inside the instances!

---

## How to Run the pipeline

### Prerequisites
1. **AWS CLI** configured (`aws configure` completed).
2. **Docker Desktop** running locally (required to build and push the Docker image).
3. **Python 3.x** installed.

### Execution Steps

1. Open your terminal and navigate to the project directory:
   ```bash
   cd C:\Users\Hitesh\.gemini\antigravity\scratch\devops-mastery\aws-production-pipeline
   ```

2. Run the master Python orchestrator:
   ```bash
   python aws_orchestrator.py
   ```

3. Select **Option 1**:
   - The script will prompt you for an AWS Key Pair name. (You can press Enter to use the default dummy key, as SSH is not required for SSM deployment).
   - Terraform will deploy the VPC, IAM roles, ECR repository, and Dev/Prod EC2 instances.
   - The script will extract output variables (Registry URL, Public IPs).
   - It will log your local Docker client into AWS ECR, build the `./app` image, and push it to ECR.
   - It will wait for the EC2 instances to boot and report Online in AWS Systems Manager.
   - It will trigger SSM Run Command to deploy the Docker container to the Dev instance (Port 8080) and Prod instance (Port 80).
   - It prints the live URLs.

4. Select **Option 2** (Teardown):
   - To clean up and delete all AWS resources to avoid any charges, run the script and select Option 2. It will execute `terraform destroy` to clear everything.
