#!/usr/bin/env python3

import os
import subprocess
import sys


def run(cmd):
    print(f"\n>>> {cmd}")
    subprocess.run(cmd, shell=True, check=False)


if os.geteuid() != 0:
    print("Run with: sudo python3 devops_cleanup.py")
    sys.exit(1)

print("Starting DevOps Cleanup...")

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
# Grafana
# --------------------------------------------------

run("helm uninstall grafana -n monitoring")

# --------------------------------------------------
# Prometheus
# --------------------------------------------------

run("helm uninstall prometheus -n monitoring")
run("kubectl delete namespace monitoring --ignore-not-found")

# --------------------------------------------------
# K3s
# --------------------------------------------------

run("/usr/local/bin/k3s-uninstall.sh")

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

run("""
apt remove -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin
""")

run("apt autoremove -y")

# --------------------------------------------------
# Remove repositories
# --------------------------------------------------

run("rm -f /etc/apt/sources.list.d/docker.list")
run("rm -f /etc/apt/sources.list.d/kubernetes.list")
run("rm -f /etc/apt/sources.list.d/hashicorp.list")

run("rm -f /etc/apt/keyrings/docker.gpg")
run("rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg")
run("rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg")

# --------------------------------------------------
# Cleanup
# --------------------------------------------------

run("apt update")
run("apt autoremove -y")
run("apt autoclean")

print("\n====================================")
print("DevOps Cleanup Completed")
print("====================================")