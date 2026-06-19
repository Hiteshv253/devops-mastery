#!/usr/bin/env python3
"""
Simple AWS EC2 Orchestrator for Learning Terraform Lifecycle
Author: Hitesh Vishwakarma

This script demonstrates Terraform's lifecycle:
1. CREATE (terraform apply)
2. READ/INFO (terraform show & outputs)
3. EDIT/UPDATE (terraform apply with new variables)
4. DELETE (terraform destroy)
"""

import os
import sys
import subprocess
import json

# Terminal Colors
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

def run_cmd(command, cwd=None):
    """Executes a system shell command and prints live output."""
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

def check_aws_cli():
    """Verify AWS CLI is working and authenticated."""
    log_info("Checking AWS Connection...")
    code, out, err = run_cmd("aws sts get-caller-identity")
    if code != 0:
        log_error("AWS CLI connection failed. Please run 'aws configure' first!")
        print(err)
        sys.exit(1)
    
    identity = json.loads(out)
    log_info(f"AWS Authenticated! Account ID: {identity.get('Account')}")

def main():
    tf_dir = os.path.join(os.getcwd(), "terraform")
    
    if not os.path.exists(tf_dir):
        log_error(f"Terraform directory not found at: {tf_dir}")
        sys.exit(1)

    check_aws_cli()
    
    # Track the current instance type variable state
    current_instance_type = "t2.micro"

    while True:
        print("\n" + "=" * 50)
        print("          TERRAFORM LIFECYCLE LEARN LAB")
        print("=" * 50)
        print(f"Current Instance Type configured: {YELLOW}{current_instance_type}{RESET}")
        print("1) CREATE: Provision UAT & Prod EC2 Servers")
        print("2) READ/INFO: View live resource details & Public IPs")
        print("3) EDIT/UPDATE: Change Instance Type (e.g. t2.micro -> t2.small)")
        print("4) DELETE: Destroy all UAT & Prod resources")
        print("5) Exit")
        print("=" * 50)

        try:
            choice = input("Select operation [1-5]: ").strip()
        except KeyboardInterrupt:
            print("\nExited.")
            break

        if choice == "1":
            log_info("Initializing Terraform plugins...")
            run_cmd("terraform init", cwd=tf_dir)
            
            log_info("Creating UAT & Prod EC2 instances (terraform apply)...")
            cmd = f'terraform apply -auto-approve -var="instance_type={current_instance_type}"'
            code, out, err = run_cmd(cmd, cwd=tf_dir)
            if code == 0:
                log_info("EC2 Instances created successfully!")
                print(out[-800:]) # Show last part of success output
            else:
                log_error("Failed to create resources!")
                print(err)

        elif choice == "2":
            log_info("Reading current resources from Terraform state (terraform output)...")
            code, out, err = run_cmd("terraform output -json", cwd=tf_dir)
            if code == 0 and out:
                try:
                    outputs = json.loads(out)
                    print(f"\n{GREEN}--- Live EC2 Status ---{RESET}")
                    print(f"UAT Instance ID:   {outputs['uat_instance_id']['value']}")
                    print(f"UAT Public IP:     {outputs['uat_public_ip']['value']}")
                    print(f"Prod Instance ID:  {outputs['prod_instance_id']['value']}")
                    print(f"Prod Public IP:    {outputs['prod_public_ip']['value']}")
                    print(f"{GREEN}-----------------------{RESET}")
                except Exception as ex:
                    log_warn("No active outputs found. Resources might not be deployed yet.")
            else:
                log_warn("No outputs found. Please run CREATE (1) first.")

        elif choice == "3":
            print("\nChoose new size:")
            print("1) t2.micro (Free Tier)")
            print("2) t2.small (Slightly larger, demonstrating modification)")
            size_choice = input("Select [1-2]: ").strip()
            
            if size_choice == "1":
                current_instance_type = "t2.micro"
            elif size_choice == "2":
                current_instance_type = "t2.small"
            else:
                log_error("Invalid selection.")
                continue

            log_info(f"Updating AWS resources to '{current_instance_type}' (terraform apply)...")
            cmd = f'terraform apply -auto-approve -var="instance_type={current_instance_type}"'
            code, out, err = run_cmd(cmd, cwd=tf_dir)
            if code == 0:
                log_info(f"Resources successfully updated to {current_instance_type}!")
                print(out[-800:])
            else:
                log_error("Update operation failed!")
                print(err)

        elif choice == "4":
            log_warn("Destroying all resources (terraform destroy)...")
            code, out, err = run_cmd("terraform destroy -auto-approve", cwd=tf_dir)
            if code == 0:
                log_info("All UAT and Prod instances terminated successfully!")
            else:
                log_error("Failed to destroy resources!")
                print(err)

        elif choice == "5":
            print("Goodbye!")
            break
        else:
            log_error("Invalid choice. Enter 1-5.")

if __name__ == "__main__":
    main()
