# How to Connect Local System to AWS and Run Terraform

To deploy the Terraform resources we created in `phase1-terraform/envs/dev` to your AWS account, follow this step-by-step guide.

---

## Step 1: Install AWS CLI on your Local System

Before Terraform can talk to AWS, you need the **AWS Command Line Interface (CLI)** installed.

1. **Download and Install**:
   - **Windows (PowerShell)**: Run this command to install via `msiexec`:
     ```powershell
     msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi /qn
     ```
     *(Or download the installer manually from [AWS CLI Installer](https://aws.amazon.com/cli/))*
2. **Verify Installation**:
   Open a new terminal window and run:
   ```bash
   aws --version
   ```

---

## Step 2: Create IAM User and Credentials in AWS Console

Terraform needs programmatic access to your AWS Account.

1. Log into your **AWS Management Console**.
2. Search for **IAM** (Identity and Access Management).
3. Go to **Users** -> **Create User**.
   - **User name**: `terraform-developer`
4. Assign Permissions:
   - For learning, attach the policy **`PowerUserAccess`** or **`AdministratorAccess`** directly. *(In MNCs, we use strict least-privilege IAM policies).*
5. Create the User.
6. Click on the created user -> **Security credentials** tab.
7. Scroll down to **Access keys** -> **Create access key**.
   - Select **Command Line Interface (CLI)**.
   - Click Next and Create.
8. **Copy the Credentials**: Copy the `Access key ID` and `Secret access key`. Keep them safe!

---

## Step 3: Configure AWS Credentials Locally

Now configure your local system to use these credentials.

Run the configure command in your terminal:
```bash
aws configure
```

It will prompt you to enter the details:
```text
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE (Enter your Access Key)
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY (Enter your Secret Key)
Default region name [None]: us-east-1 (Enter your preferred region)
Default output format [None]: json
```

### Verification
Verify that the connection works by querying your AWS Identity:
```bash
aws sts get-caller-identity
```
If this returns your Account ID and User ARN, your local system is successfully connected to AWS!

---

## Step 4: Run Terraform to Create Resources

Now you can initialize and apply the code we wrote.

1. Open your terminal and navigate to the dev environment folder:
   ```bash
   cd C:\Users\Hitesh\.gemini\antigravity\scratch\devops-mastery\phase1-terraform\envs\dev
   ```
2. **Initialize Terraform**:
   Downloads the AWS provider plugins and sets up the local state.
   ```bash
   terraform init
   ```
3. **Generate Dry-Run Plan**:
   Shows you what resources Terraform will create, edit, or delete without actually making changes yet.
   ```bash
   terraform plan
   ```
4. **Apply Changes (Create Resources)**:
   Deploys the VPC, Subnets, Route Tables, and Security Groups to your AWS account.
   ```bash
   terraform apply
   ```
   *Type `yes` when prompted to confirm.*

5. **Clean Up (Delete Resources)**:
   When you are done learning and want to avoid AWS costs, destroy the resources:
   ```bash
   terraform destroy
   ```
   *Type `yes` when prompted.*
