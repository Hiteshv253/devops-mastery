# Automated Multi-Environment EC2 Deployment (Dev vs. Prod)

This example demonstrates how to deploy code dynamically to two EC2 instances (**Development** and **Production**) using a single **GitHub Actions Pipeline**.

---

## Architecture Flow

```text
Developer pushes code
       │
       ├───> Push to 'develop' branch ───> GHA Pipeline ───> Deploy to DEV EC2 (Port 8080)
       │
       └───> Push to 'main' branch ──────> GHA Pipeline ───> Deploy to PROD EC2 (Port 80)
```

---

## Step 1: Provision the EC2 Instances using Terraform
Navigate to [terraform/main.tf](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/example-ec2-pipeline/terraform/main.tf).

Run these commands to spin up the servers:
```bash
cd example-ec2-pipeline/terraform
terraform init
terraform apply -var="key_pair_name=your-aws-ssh-key"
```
*Take note of the Public IPs generated for both the Dev and Prod instances.*

---

## Step 2: Configure GitHub Repository Secrets
To allow GitHub Actions to safely connect to your EC2 servers, go to your GitHub repository:
**Settings -> Secrets and variables -> Actions -> New repository secret**

Create these 3 secrets:
1. `DEV_EC2_IP`: The Public IP of the Dev EC2 instance.
2. `PROD_EC2_IP`: The Public IP of the Prod EC2 instance.
3. `EC2_SSH_PRIVATE_KEY`: The raw content of your AWS Private Key (`.pem` file) used to access the instances.

---

## Step 3: How the Pipeline Works
Open the workflow configuration: [deploy-ec2.yml](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/example-ec2-pipeline/.github/workflows/deploy-ec2.yml).

- **Dynamic Environment Selection**:
  The pipeline checks the branch that triggered the action:
  - If `develop`: Target Host is `DEV_EC2_IP`, Target Port is `8080`.
  - If `main`: Target Host is `PROD_EC2_IP`, Target Port is `80`.
- **SFTP Code Sync**:
  Uses `appleboy/scp-action` to securely copy built code files directly into `/home/ec2-user/app` on the target EC2.
- **Docker Orchestration via SSH**:
  Uses `appleboy/ssh-action` to connect to the target EC2, stop any running app container, and restart it with the new code mounted on the correct environment port.

---

## AWS CodePipeline Alternative (MNC-Grade Native Deployment)
In large AWS enterprise environments, instead of raw SSH, MNCs often use **AWS CodeDeploy** for EC2 deployments:

### How it works:
1. **AWS CodeDeploy Agent** is installed on the EC2 instances.
2. An **`appspec.yml`** file is placed in your code root to define lifecycle hooks (e.g., `BeforeInstall`, `AfterInstall`, `ApplicationStart`).
3. GitHub Actions builds the code, packages it, uploads it to an **S3 Bucket**, and calls CodeDeploy API.
4. CodeDeploy tells the EC2 Agent to pull the package from S3 and run the scripts in `appspec.yml`.
5. **Advantage**: Safe rollbacks, blue/green deployments, and centralized health checking inside AWS Console.
