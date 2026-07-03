#!/usr/bin/env python3

import os
import subprocess
import sys

def run(cmd):
    print(f"\n>>> {cmd}")
    # Running cleanup tasks with check=False as resources might not exist
    subprocess.run(cmd, shell=True, check=False)

if os.geteuid() != 0:
    print("Run with: sudo python3 devops_cleanup.py")
    sys.exit(1)

print("Starting Enterprise DevOps Cleanup...")

# --------------------------------------------------
# Jenkins
# --------------------------------------------------
run("docker rm -f jenkins")
run("docker volume rm jenkins_home")

# --------------------------------------------------
# ArgoCD
# --------------------------------------------------
run("helm uninstall argocd -n argocd")
run("kubectl delete namespace argocd --ignore-not-found")

# --------------------------------------------------
# Monitoring (kube-prometheus-stack)
# --------------------------------------------------
run("helm uninstall prometheus -n monitoring")
run("kubectl delete namespace monitoring --ignore-not-found")

# --------------------------------------------------
# K3s Kubernetes Cluster
# --------------------------------------------------
if os.path.exists("/usr/local/bin/k3s-uninstall.sh"):
    run("/usr/local/bin/k3s-uninstall.sh")
else:
    print("K3s uninstaller not found, skipping")

# --------------------------------------------------
# K9s CLI UI
# --------------------------------------------------
run("rm -f /usr/local/bin/k9s")

# --------------------------------------------------
# AWS CLI
# --------------------------------------------------
run("rm -rf /usr/local/aws-cli /usr/local/bin/aws /usr/local/bin/aws_completer")

# --------------------------------------------------
# Azure CLI
# --------------------------------------------------
run("apt remove -y azure-cli")

# --------------------------------------------------
# Trivy
# --------------------------------------------------
run("apt remove -y trivy")

# --------------------------------------------------
# Ansible
# --------------------------------------------------
run("apt remove -y ansible")

# --------------------------------------------------
# Terraform
# --------------------------------------------------
run("apt remove -y terraform")

# --------------------------------------------------
# Helm
# --------------------------------------------------
run("rm -f /usr/local/bin/helm")

# --------------------------------------------------
# kubectl
# --------------------------------------------------
run("apt remove -y kubectl")

# --------------------------------------------------
# Docker
# --------------------------------------------------
run("docker system prune -af --volumes")
run(
    "apt remove -y "
    "docker-ce docker-ce-cli containerd.io "
    "docker-buildx-plugin docker-compose-plugin"
)

# --------------------------------------------------
# Remove Added Repository Source Lists
# --------------------------------------------------
run("rm -f /etc/apt/sources.list.d/docker.list")
run("rm -f /etc/apt/sources.list.d/kubernetes.list")
run("rm -f /etc/apt/sources.list.d/hashicorp.list")
run("rm -f /etc/apt/sources.list.d/trivy.list")

# --------------------------------------------------
# Remove Added GPG Keys
# --------------------------------------------------
run("rm -f /etc/apt/keyrings/docker.gpg")
run("rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg")
run("rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg")
run("rm -f /usr/share/keyrings/trivy.gpg")

# --------------------------------------------------
# APT Cleanup
# --------------------------------------------------
run("apt update")
run("apt autoremove -y")
run("apt autoclean")

# Remove user kube config
if os.environ.get("SUDO_USER"):
    user = os.environ["SUDO_USER"]
    run(f"rm -rf /home/{user}/.kube")

print("\n====================================")
print("Enterprise DevOps Cleanup Completed")
print("====================================")