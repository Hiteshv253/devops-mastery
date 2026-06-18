#!/usr/bin/env python3
"""
AWS Enterprise Deployment Orchestrator
Automates: Terraform Apply -> Docker Build -> ECR Push -> AWS SSM Keyless Deploy -> Teardown

Author: Hitesh Vishwakarma (DevOps & Platform Engineer)
"""

import os
import sys
import json
import time
import subprocess
import shutil

# Formatting Colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
RESET = "\033[0m"

def log_info(msg):
    print(f"{GREEN}[INFO] {msg}{RESET}")

def log_warn(msg):
    print(f"{YELLOW}[WARN] {msg}{RESET}")

def log_error(msg):
    print(f"{RED}[ERROR] {msg}{RESET}")

def run_cmd(command, cwd=None, hide_output=False):
    """Executes a system shell command and returns output."""
    try:
        process = subprocess.run(
            command,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True
        )
        return process.returncode, process.stdout.strip(), process.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def verify_credentials():
    log_info("Verifying local AWS credentials...")
    code, out, err = run_cmd("aws sts get-caller-identity")
    if code != 0:
        log_error("AWS CLI credentials check failed! Run 'aws configure' first.")
        print(err)
        sys.exit(1)
    
    identity = json.loads(out)
    log_info(f"Connected to AWS Account: {identity.get('Account')} as User: {identity.get('Arn').split('/')[-1]}")

def build_infrastructure():
    log_info("Step 1: Deploying AWS Cloud Infrastructure via Terraform...")
    tf_dir = os.path.join(os.getcwd(), "terraform")
    
    # Prompt for Key Pair Name (Required by EC2 configuration)
    key_name = input("Enter AWS Key Pair Name (or press Enter if none / using SSM): ").strip()
    if not key_name:
        key_name = "dummy-key-for-ssm"
        log_warn("No key name supplied. Defaulting to 'dummy-key-for-ssm' (SSM deployment will still work).")

    log_info("Initializing Terraform...")
    code, out, err = run_cmd("terraform init", cwd=tf_dir)
    if code != 0:
        log_error("Terraform Init failed!")
        print(err)
        sys.exit(1)

    log_info("Applying Terraform templates to AWS (This might take 2-3 minutes)...")
    apply_cmd = f'terraform apply -auto-approve -var="key_pair_name={key_name}"'
    code, out, err = run_cmd(apply_cmd, cwd=tf_dir)
    if code != 0:
        log_error("Terraform Apply failed!")
        print(err)
        sys.exit(1)
        
    log_info("Terraform provisioning completed successfully!")

def get_outputs():
    tf_dir = os.path.join(os.getcwd(), "terraform")
    code, out, err = run_cmd("terraform output -json", cwd=tf_dir)
    if code != 0:
        log_error("Failed to read Terraform outputs!")
        print(err)
        sys.exit(1)
    
    outputs = json.loads(out)
    return {
        "ecr_url": outputs["ecr_repository_url"]["value"],
        "dev_ip": outputs["dev_instance_public_ip"]["value"],
        "prod_ip": outputs["prod_instance_public_ip"]["value"],
        "dev_id": outputs["dev_instance_id"]["value"],
        "prod_id": outputs["prod_instance_id"]["value"]
    }

def push_to_ecr(ecr_url):
    log_info("Step 2: Authenticating with AWS ECR & Pushing Docker Image...")
    
    # Extract AWS Registry URL and Region
    # e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/devops-realtime-app
    registry_domain = ecr_url.split('/')[0]
    region = ecr_url.split('.')[3]
    
    log_info("Logging in to AWS Elastic Container Registry...")
    login_cmd = f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {registry_domain}"
    code, out, err = run_cmd(login_cmd)
    if code != 0:
        log_error("ECR Login failed!")
        print(err)
        sys.exit(1)
    
    log_info("Building local Docker image from ./app...")
    build_cmd = "docker build -t devops-realtime-app:latest ./app"
    code, out, err = run_cmd(build_cmd)
    if code != 0:
        log_error("Docker build failed!")
        print(err)
        sys.exit(1)
        
    log_info("Tagging image for ECR...")
    tag_cmd = f"docker tag devops-realtime-app:latest {ecr_url}:latest"
    code, out, err = run_cmd(tag_cmd)
    if code != 0:
        log_error("Docker tag failed!")
        sys.exit(1)

    log_info("Pushing image to ECR repository...")
    push_cmd = f"docker push {ecr_url}:latest"
    code, out, err = run_cmd(push_cmd)
    if code != 0:
        log_error("Docker ECR push failed!")
        print(err)
        sys.exit(1)
        
    log_info("Docker image successfully pushed to AWS ECR!")

def wait_for_ssm(instance_id):
    """Waits for an EC2 instance to register and become Online in SSM."""
    log_info(f"Waiting for EC2 Instance '{instance_id}' to register with AWS Systems Manager (SSM)...")
    check_cmd = f"aws ssm describe-instance-information --filters \"Key=InstanceIds,Values={instance_id}\""
    
    for attempt in range(20):
        code, out, err = run_cmd(check_cmd)
        if code == 0 and out:
            info = json.loads(out)
            inst_list = info.get("InstanceInformationList", [])
            if inst_list and inst_list[0].get("PingStatus") == "Online":
                log_info(f"EC2 Instance '{instance_id}' is ONLINE in SSM.")
                return True
        time.sleep(15)
        log_info(f"Checking SSM registration... (Attempt {attempt + 1}/20)")
    
    log_error(f"Timed out waiting for EC2 '{instance_id}' to report Online in SSM.")
    return False

def deploy_via_ssm(instance_id, ecr_url, host_port):
    """Deploys the Docker image onto the EC2 instance keylessly using AWS SSM Run Command."""
    log_info(f"Deploying application to EC2 '{instance_id}' on port {host_port}...")
    
    # Extract Region from ECR
    region = ecr_url.split('.')[3]
    registry_domain = ecr_url.split('/')[0]

    # Command list executed on the remote EC2 instance as ROOT user:
    commands = [
        "dnf install -y docker",
        "systemctl start docker",
        # Authenticate Docker on the EC2 instance using the instance profile
        f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {registry_domain}",
        # Stop and remove any existing container
        "docker stop app || true",
        "docker rm app || true",
        # Pull latest ECR image
        f"docker pull {ecr_url}:latest",
        # Run new container routing host port to container port 80
        f"docker run -d --name app -p {host_port}:80 {ecr_url}:latest"
    ]
    
    commands_json = json.dumps(commands)
    # Trigger AWS Systems Manager Run Command
    ssm_cmd = f'aws ssm send-command --instance-ids "{instance_id}" --document-name "AWS-RunShellScript" --parameters commands=\'{commands_json}\' --region {region}'
    
    code, out, err = run_cmd(ssm_cmd)
    if code != 0:
        log_error(f"SSM command dispatch failed for instance {instance_id}!")
        print(err)
        return False

    cmd_info = json.loads(out)
    command_id = cmd_info["Command"]["CommandId"]
    log_info(f"SSM Command '{command_id}' dispatched. Waiting for execution completion...")
    
    # Poll for command status
    status_cmd = f'aws ssm get-command-invocation --command-id "{command_id}" --instance-id "{instance_id}" --region {region}'
    for _ in range(10):
        time.sleep(5)
        c_code, c_out, c_err = run_cmd(status_cmd)
        if c_code == 0:
            invocation = json.loads(c_out)
            status = invocation.get("Status")
            if status in ["Success"]:
                log_info(f"Deployment succeeded on EC2 '{instance_id}'!")
                return True
            elif status in ["Failed", "TimedOut", "Cancelled"]:
                log_error(f"SSM Deployment execution failed with status: {status}")
                print(invocation.get("StandardErrorContent"))
                return False
    
    log_warn("SSM Command is taking longer than expected. Please verify manually on the AWS console.")
    return True

def destroy_infrastructure():
    log_warn("Step 5: Destroying all provisioned AWS Resources...")
    tf_dir = os.path.join(os.getcwd(), "terraform")
    code, out, err = run_cmd("terraform destroy -auto-approve", cwd=tf_dir)
    if code == 0:
        log_info("All AWS infrastructure terminated successfully!")
    else:
        log_error("Terraform Destroy failed!")
        print(err)

def main():
    print("=" * 60)
    print("      AWS ENTERPRISE REAL-TIME DEPLOYMENT PIPELINE")
    print("=" * 60)
    
    # 1. AWS Credentials Verification
    verify_credentials()
    
    print("\nSelect Action:")
    print("1) Deploy Complete Infrastructure & Application (Dev & Prod)")
    print("2) Teardown / Destroy AWS Infrastructure (Avoid Costs)")
    print("3) Exit")
    
    choice = input("Enter choice [1-3]: ").strip()
    
    if choice == "1":
        # Create Infrastructure
        build_infrastructure()
        
        # Read parameters
        cfg = get_outputs()
        
        # ECR Push
        push_to_ecr(cfg["ecr_url"])
        
        # Wait for SSM agent registration (Amazon Linux boots and runs user_data to start Docker)
        log_info("Giving EC2 instances 45 seconds to initialize and start SSM agents...")
        time.sleep(45)
        
        dev_ready = wait_for_ssm(cfg["dev_id"])
        prod_ready = wait_for_ssm(cfg["prod_id"])
        
        if dev_ready and prod_ready:
            # Keyless deployment using SSM Run Command
            dev_deploy = deploy_via_ssm(cfg["dev_id"], cfg["ecr_url"], "8080")
            prod_deploy = deploy_via_ssm(cfg["prod_id"], cfg["ecr_url"], "80")
            
            if dev_deploy and prod_deploy:
                print("\n" + "=" * 60)
                log_info("DEPLOYMENT STATUS: SUCCESSFUL!")
                print(f"Development Environment: http://{cfg['dev_ip']}:8080")
                print(f"Production Environment:  http://{cfg['prod_ip']}:80")
                print("=" * 60 + "\n")
        else:
            log_error("One or more EC2 instances did not register with AWS SSM.")
            
    elif choice == "2":
        destroy_infrastructure()
    else:
        print("Exiting.")
        sys.exit(0)

if __name__ == "__main__":
    main()
