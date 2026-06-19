# AWS Terraform Learning Lab (UAT & Production EC2)

Welcome! This folder contains a **simplified, beginner-friendly** project to help you learn the core concepts of Terraform and Infrastructure as Code (IaC) lifecycle operations.

Instead of writing complex network and security parameters, this setup uses AWS's default network settings to quickly spin up two EC2 servers:
1. **UAT EC2 Server**
2. **Production EC2 Server**

---

## What is inside this project?

- **[terraform/main.tf](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/terraform/main.tf)**: Defines the AWS EC2 resources and a simple security group.
- **[terraform/variables.tf](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/terraform/variables.tf)**: Contains default values for AWS Region, AMI ID, and Instance size.
- **[terraform/outputs.tf](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/terraform/outputs.tf)**: Outputs the Public IP addresses and Instance IDs of your deployed servers.
- **[aws_orchestrator.py](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/aws-production-pipeline/aws_orchestrator.py)**: A simple Python script that acts as a control panel to run CREATE, READ, UPDATE, and DELETE operations.

---

## How to use this project

### Step 1: Configure your AWS credentials
Open your terminal (PowerShell or Command Prompt) and configure your AWS CLI keys:
```bash
aws configure
```
Enter your AWS Access Key, Secret Key, and default region (e.g., `us-east-1`).

### Step 2: Run the Orchestrator
Launch the Python script:
```bash
python aws_orchestrator.py
```

You will see the control menu:
```text
1) CREATE: Provision UAT & Prod EC2 Servers
2) READ/INFO: View live resource details & Public IPs
3) EDIT/UPDATE: Change Instance Type (e.g. t2.micro -> t2.small)
4) DELETE: Destroy all UAT & Prod resources
5) Exit
```

---

## Understanding the Lifecycle Concepts

### 1. CREATE (Option 1)
When you choose **Option 1**, the Python script runs:
- `terraform init`: Downloads the AWS plugin provider.
- `terraform apply -auto-approve`: Tells AWS to provision the security group and the 2 EC2 instances. It creates a local state file called `terraform.tfstate`.

### 2. READ / INFO (Option 2)
When you choose **Option 2**, the script queries the local `terraform.tfstate` database to read the live Public IPs and resource IDs. It displays them directly on your screen.

### 3. EDIT / UPDATE (Option 3)
When you choose **Option 3**, you can change the instance size (from `t2.micro` to `t2.small`). The script runs:
- `terraform apply -var="instance_type=t2.small"`
- **How Terraform handles updates**:
  Terraform compares the new configuration (size = `t2.small`) with the existing state file. Since changing the instance type on AWS does not require deleting the server (it only requires stopping and resizing it), Terraform will **update the instance size in-place** without creating new EC2 instances!

### 4. DELETE (Option 4)
When you choose **Option 4**, the script runs:
- `terraform destroy -auto-approve`: Tells AWS to terminate both EC2 instances and delete the security group. This ensures you do not incur any AWS charges.
