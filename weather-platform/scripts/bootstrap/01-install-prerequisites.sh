#!/bin/bash
set -e

# 01-install-prerequisites.sh
# Installs core dependencies: Docker, Kubectl, Terraform, and system packages

echo "=========================================="
echo "Bootstrap Step 1: Installing Prerequisites"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root using sudo."
  exit 1
fi

# Update package index and install basic tools
apt-get update
apt-get install -y curl wget git unzip gnupg lsb-release ca-certificates apt-transport-https software-properties-common

# Set up Docker repository
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Set up Kubectl repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

# Set up Terraform repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list

# Update package index and install CLIs
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin kubectl terraform

# Configure docker group
groupadd docker || true
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
fi

echo "=========================================="
echo "Prerequisites step complete!"
echo "=========================================="
