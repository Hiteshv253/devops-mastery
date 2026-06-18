#!/usr/bin/env python3
"""
MNC-Grade DevOps Bootstrap & Orchestration Script
Author: Hitesh Vishwakarma (DevOps & Platform Engineer)

This script automates the deployment workflow of all phases:
1. Terraform (Infrastructure Provisioning)
2. Docker (Container Builds & Compose Stack)
3. Kubernetes (Manifest Rollout)
4. AI Validation (Running Log Analyzer on outputs)
"""

import os
import sys
import subprocess
import shutil

# Color Codes for Terminal Outputs
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

def check_prerequisite(binary_name):
    """Checks if a required tool is installed in the system PATH."""
    path = shutil.which(binary_name)
    if path:
        log_info(f"Prerequisite satisfied: '{binary_name}' found at {path}")
        return True
    else:
        log_warn(f"Prerequisite missing: '{binary_name}' is not installed or not in PATH.")
        return False

def run_command(command_list, cwd=None):
    """Runs a system command and returns status code + output."""
    try:
        process = subprocess.run(
            command_list,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            shell=True if sys.platform == "win32" else False
        )
        return process.returncode, process.stdout, process.stderr
    except Exception as e:
        return -1, "", str(e)

def run_terraform():
    log_info("Starting Phase 1: Terraform Deployment...")
    tf_dir = os.path.join(os.getcwd(), "phase1-terraform", "envs", "dev")
    
    if not os.path.exists(tf_dir):
        log_error(f"Directory not found: {tf_dir}")
        return False

    log_info("Initializing Terraform...")
    code, out, err = run_command(["terraform", "init"], cwd=tf_dir)
    if code != 0:
        log_error("Terraform Init Failed!")
        print(err)
        return False

    log_info("Applying Terraform configuration (Dry-run plan shown in logs)...")
    # Using local backend for safety. For real AWS deployment, ensure AWS CLI is configured.
    code, out, err = run_command(["terraform", "apply", "-auto-approve"], cwd=tf_dir)
    if code != 0:
        log_error("Terraform Apply Failed!")
        print(err)
        # Call AI analyzer automatically
        analyze_with_ai(err, "Terraform Apply Error")
        return False
    
    log_info("Terraform resources deployed successfully!")
    print(out[:500] + "\n... (truncated)")
    return True

def run_docker():
    log_info("Starting Phase 2: Docker Builds...")
    docker_dir = os.path.join(os.getcwd(), "phase2-docker")
    
    if not os.path.exists(docker_dir):
        log_error(f"Directory not found: {docker_dir}")
        return False

    log_info("Building local multi-stage Docker image...")
    code, out, err = run_command(
        ["docker", "build", "-t", "devops_laravel_app:latest", "."],
        cwd=docker_dir
    )
    if code != 0:
        log_error("Docker build failed!")
        print(err)
        analyze_with_ai(err, "Docker Build Error")
        return False
    
    log_info("Image built successfully! Starting Docker Compose local stack...")
    code, out, err = run_command(["docker-compose", "up", "-d"], cwd=docker_dir)
    if code != 0:
        log_error("Docker Compose failed to spin up!")
        print(err)
        return False

    log_info("Docker stack running locally at http://localhost:8080")
    return True

def run_kubernetes():
    log_info("Starting Phase 3: Kubernetes Deployment...")
    k8s_dir = os.path.join(os.getcwd(), "phase3-kubernetes", "manifests")
    
    if not os.path.exists(k8s_dir):
        log_error(f"Directory not found: {k8s_dir}")
        return False

    log_info("Applying raw manifests using kubectl...")
    # Apply configs first, then secrets, services, deployment
    files = ["configmap.yaml", "secrets.yaml", "service.yaml", "deployment.yaml", "hpa.yaml", "ingress.yaml"]
    for file in files:
        file_path = os.path.join(k8s_dir, file)
        if os.path.exists(file_path):
            code, out, err = run_command(["kubectl", "apply", "-f", file])
            if code != 0:
                log_error(f"Failed to apply manifest: {file}")
                print(err)
                analyze_with_ai(err, f"Kubernetes apply failed for {file}")
                return False
            else:
                log_info(f"Applied: {file}")
    
    log_info("Kubernetes workloads deployed successfully!")
    return True

def destroy_resources(tf_installed, docker_installed, kubectl_installed):
    log_warn("Initiating teardown/destruction of all deployed resources...")
    
    # 1. Teardown Kubernetes Workloads
    if kubectl_installed:
        k8s_dir = os.path.join(os.getcwd(), "phase3-kubernetes", "manifests")
        if os.path.exists(k8s_dir):
            log_info("Deleting Kubernetes workloads...")
            files = ["ingress.yaml", "hpa.yaml", "deployment.yaml", "service.yaml", "secrets.yaml", "configmap.yaml"]
            for file in files:
                file_path = os.path.join(k8s_dir, file)
                if os.path.exists(file_path):
                    run_command(["kubectl", "delete", "-f", file])
            log_info("Kubernetes workloads deleted.")

    # 2. Teardown Docker Stack
    if docker_installed:
        docker_dir = os.path.join(os.getcwd(), "phase2-docker")
        if os.path.exists(docker_dir):
            log_info("Stopping and removing Docker Compose containers...")
            run_command(["docker-compose", "down", "-v"], cwd=docker_dir)
            log_info("Docker stack terminated.")

    # 3. Teardown Terraform Infrastructure
    if tf_installed:
        tf_dir = os.path.join(os.getcwd(), "phase1-terraform", "envs", "dev")
        if os.path.exists(tf_dir):
            log_info("Destroying Terraform provisioned infrastructure...")
            code, out, err = run_command(["terraform", "destroy", "-auto-approve"], cwd=tf_dir)
            if code == 0:
                log_info("Terraform infrastructure destroyed successfully.")
            else:
                log_error("Terraform destroy failed!")
                print(err)
                analyze_with_ai(err, "Terraform Destroy Error")

    log_info("Teardown process completed.")

def analyze_with_ai(error_message, context_name):
    """Triggers the Phase 5 Gemini AI tool to analyze script failure logs."""
    log_warn("Triggering Phase 5 AI Log Analyzer to diagnose this failure...")
    ai_script = os.path.join(os.getcwd(), "phase5-ai-devops", "ai_devops_tool.py")
    temp_err_file = "temp_bootstrap_error.log"
    
    # Save the error output to a temp file
    with open(temp_err_file, "w", encoding="utf-8") as f:
        f.write(f"Context: {context_name}\n\nError Output:\n{error_message}")

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        log_error("Cannot auto-analyze: GEMINI_API_KEY environment variable is not set.")
        if os.path.exists(temp_err_file):
            os.remove(temp_err_file)
        return

    # Call the Phase 5 Python AI Tool
    code, out, err = run_command([sys.executable, ai_script, temp_err_file])
    print(out)
    
    # Cleanup
    if os.path.exists(temp_err_file):
        os.remove(temp_err_file)

def main():
    print("=" * 60)
    print("      MNC DEVOPS PIPELINE BOOTSTRAP ORCHESTRATOR")
    print("=" * 60)

    # 1. Check Prereqs
    log_info("Checking system dependencies...")
    tf_installed = check_prerequisite("terraform")
    docker_installed = check_prerequisite("docker")
    kubectl_installed = check_prerequisite("kubectl")
    print("-" * 60)

    # 2. Interactive Menu
    print("Select deployment scope:")
    print("1) Run Phase 1: Terraform Infrastructure only")
    print("2) Run Phase 2: Build & Start Docker Stack")
    print("3) Run Phase 3: Deploy Kubernetes workloads")
    print("4) Deploy ALL (Full Pipeline)")
    print("5) DESTROY ALL Resources (Teardown)")
    print("6) Exit")
    
    try:
        choice = input("Enter choice [1-6]: ").strip()
    except KeyboardInterrupt:
        print("\nExited.")
        sys.exit(0)

    if choice == "1":
        if tf_installed:
            run_terraform()
        else:
            log_error("Cannot run Terraform: command not found.")
    elif choice == "2":
        if docker_installed:
            run_docker()
        else:
            log_error("Cannot run Docker: command not found.")
    elif choice == "3":
        if kubectl_installed:
            run_kubernetes()
        else:
            log_error("Cannot run Kubernetes: kubectl command not found.")
    elif choice == "4":
        success = True
        if tf_installed:
            success = run_terraform()
        if success and docker_installed:
            success = run_docker()
        if success and kubectl_installed:
            success = run_kubernetes()
        
        if success:
            log_info("All phases deployed successfully!")
    elif choice == "5":
        destroy_resources(tf_installed, docker_installed, kubectl_installed)
    elif choice == "6":
        print("Goodbye!")
        sys.exit(0)
    else:
        log_error("Invalid selection.")

if __name__ == "__main__":
    main()
