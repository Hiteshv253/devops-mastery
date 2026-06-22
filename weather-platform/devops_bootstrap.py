#!/usr/bin/env python3

import os
import subprocess
import sys


def run(cmd):
    print(f"\n>>> {cmd}")
    subprocess.run(cmd, shell=True, check=True)


if os.geteuid() != 0:
    print("Run with: sudo python3 devops_bootstrap.py")
    sys.exit(1)

print("Starting DevOps Bootstrap Installation...")


# --------------------------------------------------
# Base Packages
# --------------------------------------------------

run("apt update")
run(
    "apt install -y curl wget git unzip gnupg lsb-release "
    "ca-certificates apt-transport-https software-properties-common"
)

# --------------------------------------------------
# Docker
# --------------------------------------------------

run("mkdir -p /etc/apt/keyrings")

run(
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg "
    "| gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
)

run(
    'sh -c \'echo "deb [arch=$(dpkg --print-architecture) '
    'signed-by=/etc/apt/keyrings/docker.gpg] '
    'https://download.docker.com/linux/ubuntu '
    '$(lsb_release -cs) stable" '
    '> /etc/apt/sources.list.d/docker.list\''
)

run("apt update")

run(
    "apt install -y docker-ce docker-ce-cli "
    "containerd.io docker-buildx-plugin docker-compose-plugin"
)

run("groupadd docker || true")

if os.environ.get("SUDO_USER"):
    run(f"usermod -aG docker {os.environ['SUDO_USER']}")

# --------------------------------------------------
# kubectl
# --------------------------------------------------

run("mkdir -p -m 755 /etc/apt/keyrings")

run(
    "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key "
    "| gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
)

run(
    'sh -c \'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] '
    'https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" '
    '> /etc/apt/sources.list.d/kubernetes.list\''
)

run("apt update")
run("apt install -y kubectl")

# --------------------------------------------------
# Helm
# --------------------------------------------------

run(
    "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
)

# --------------------------------------------------
# Terraform
# --------------------------------------------------

run(
    "curl -fsSL https://apt.releases.hashicorp.com/gpg "
    "| gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
)

run(
    'sh -c \'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] '
    'https://apt.releases.hashicorp.com '
    '$(lsb_release -cs) main" '
    '> /etc/apt/sources.list.d/hashicorp.list\''
)

run("apt update")
run("apt install -y terraform")

# --------------------------------------------------
# K3s
# --------------------------------------------------

# --------------------------------------------------
# K3s
# --------------------------------------------------

run("curl -sfL https://get.k3s.io | sh -")

# Configure kubectl for root
run("mkdir -p /root/.kube")
run("cp /etc/rancher/k3s/k3s.yaml /root/.kube/config")
run("chmod 600 /root/.kube/config")

# Configure kubectl for sudo user
if os.environ.get("SUDO_USER"):
    user = os.environ["SUDO_USER"]

    run(f"mkdir -p /home/{user}/.kube")
    run(f"cp /etc/rancher/k3s/k3s.yaml /home/{user}/.kube/config")
    run(f"chown -R {user}:{user} /home/{user}/.kube")

    run(
        f"grep -qxF 'export KUBECONFIG=$HOME/.kube/config' "
        f"/home/{user}/.bashrc || "
        f"echo 'export KUBECONFIG=$HOME/.kube/config' >> /home/{user}/.bashrc"
    )

# Current script session ke liye
os.environ["KUBECONFIG"] = "/etc/rancher/k3s/k3s.yaml"

# --------------------------------------------------
# Jenkins
# --------------------------------------------------

run("docker volume create jenkins_home || true")
run("docker rm -f jenkins || true")

run(
    "docker run -d "
    "--name jenkins "
    "--restart unless-stopped "
    "-p 8080:8080 "
    "-p 50000:50000 "
    "-v jenkins_home:/var/jenkins_home "
    "jenkins/jenkins:lts"
)

# --------------------------------------------------
# Helm Repositories
# --------------------------------------------------

run(
    "helm repo add prometheus-community "
    "https://prometheus-community.github.io/helm-charts"
)

run(
    "helm repo add grafana "
    "https://grafana.github.io/helm-charts"
)

run(
    "helm repo add argo "
    "https://argoproj.github.io/argo-helm"
)

run("helm repo update")


import time

print("Waiting for Kubernetes API...")

for i in range(30):
    result = subprocess.run(
        "kubectl get nodes",
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    if result.returncode == 0:
        print("Kubernetes Ready")
        break

    print(f"Waiting... {i+1}/30")
    time.sleep(10)
else:
    print("Kubernetes not ready. Skipping monitoring installation.")
    sys.exit(1)

# --------------------------------------------------
# Monitoring
# --------------------------------------------------

run("kubectl create namespace monitoring || true")

run(
    "helm upgrade --install prometheus "
    "prometheus-community/prometheus "
    "-n monitoring --create-namespace"
)

run(
    "helm upgrade --install grafana "
    "grafana/grafana "
    "-n monitoring --create-namespace"
)

# --------------------------------------------------
# ArgoCD
# --------------------------------------------------

run("kubectl create namespace argocd || true")

run(
    "helm upgrade --install argocd "
    "argo/argo-cd "
    "-n argocd --create-namespace"
)

print("\n==============================")
print("INSTALLATION COMPLETED")
print("==============================")
print("Docker      : docker --version")
print("Kubectl     : kubectl version --client")
print("Helm        : helm version")
print("Terraform   : terraform version")
print("Jenkins     : http://SERVER-IP:8080")
print("Grafana     : kubectl get svc -n monitoring")
print("Prometheus  : kubectl get pods -n monitoring")
print("ArgoCD      : kubectl get svc -n argocd")
print("\nLogout/Login required for Docker group permissions.")
print("==============================")