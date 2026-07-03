#!/usr/bin/env python3

import os
import subprocess
import sys
import time

def run(cmd):
    print(f"\n>>> {cmd}")
    # Run commands with shell and check status
    subprocess.run(cmd, shell=True, check=True)

if os.geteuid() != 0:
    print("Run with: sudo python3 devops_bootstrap.py")
    sys.exit(1)

print("Starting Enterprise DevOps Bootstrap Installation...")

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
    "| gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg"
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
    "| gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
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
run("curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash")

# --------------------------------------------------
# Terraform
# --------------------------------------------------
run(
    "curl -fsSL https://apt.releases.hashicorp.com/gpg "
    "| gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
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
# Ansible (Configuration Management)
# --------------------------------------------------
print("\nInstalling Ansible...")
run("apt install -y ansible")

# --------------------------------------------------
# Trivy (Security Scanner / DevSecOps)
# --------------------------------------------------
print("\nInstalling Trivy...")
run(
    "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key "
    "| gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg"
)
run(
    'sh -c \'echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] '
    'https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" '
    '> /etc/apt/sources.list.d/trivy.list\''
)
run("apt update")
run("apt install -y trivy")

# --------------------------------------------------
# AWS CLI (Cloud)
# --------------------------------------------------
print("\nInstalling AWS CLI...")
if not os.path.exists("/usr/local/bin/aws"):
    run("curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"")
    run("unzip -q -o awscliv2.zip")
    run("./aws/install")
    run("rm -rf awscliv2.zip aws")
else:
    print("AWS CLI already installed")

# --------------------------------------------------
# Azure CLI (Cloud)
# --------------------------------------------------
print("\nInstalling Azure CLI...")
run("curl -sL https://aka.ms/InstallAzureCLIDeb | bash")

# --------------------------------------------------
# K9s (Kubernetes Terminal UI)
# --------------------------------------------------
print("\nInstalling K9s UI...")
run("curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar -xz -C /usr/local/bin k9s")

# --------------------------------------------------
# K3s Kubernetes Cluster
# --------------------------------------------------
print("\nInstalling K3s Kubernetes Cluster...")
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

# Current script session kubeconfig
os.environ["KUBECONFIG"] = "/etc/rancher/k3s/k3s.yaml"

# --------------------------------------------------
# Jenkins CI/CD Container
# --------------------------------------------------
print("\nStarting Jenkins CI/CD...")
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
# Helm Repositories Addition
# --------------------------------------------------
print("\nConfiguring Helm Repositories...")
run("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts")
run("helm repo add argo https://argoproj.github.io/argo-helm")
run("helm repo update")

# --------------------------------------------------
# Wait for Kubernetes cluster to be online
# --------------------------------------------------
print("\nWaiting for Kubernetes API to be ready...")
for i in range(30):
    result = subprocess.run(
        "kubectl get nodes",
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode == 0:
        print("Kubernetes is online and ready!")
        break
    print(f"Waiting for control plane... {i+1}/30")
    time.sleep(5)
else:
    print("Kubernetes did not respond in time. Exiting.")
    sys.exit(1)

# --------------------------------------------------
# Monitoring (kube-prometheus-stack: Grafana + Prometheus)
# --------------------------------------------------
print("\nDeploying Monitoring Stack (kube-prometheus-stack)...")
run("kubectl create namespace monitoring || true")
run(
    "helm upgrade --install prometheus prometheus-community/kube-prometheus-stack "
    "-n monitoring --create-namespace "
    "--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelix=false"
)

# --------------------------------------------------
# ArgoCD (GitOps CD)
# --------------------------------------------------
print("\nDeploying ArgoCD (GitOps)...")
run("kubectl create namespace argocd || true")
run(
    "helm upgrade --install argocd argo/argo-cd "
    "-n argocd --create-namespace"
)

print("\n===============================================")
print("ENTERPRISE DEVOPS INSTALLATION COMPLETE")
print("===============================================")
print("Docker            : docker --version")
print("Kubectl           : kubectl version --client")
print("Helm              : helm version")
print("Terraform         : terraform version")
print("Ansible           : ansible --version")
print("Trivy Scanner     : trivy --version")
print("AWS CLI           : aws --version")
print("Azure CLI         : az --version")
print("K9s Kubectl UI    : Run 'k9s' as normal user")
print("Jenkins CI/CD     : http://localhost:8080")
print("ArgoCD GitOps     : Run 'kubectl get svc -n argocd'")
print("Prometheus/Grafana: Run 'kubectl get svc -n monitoring'")
print("\nNote: Logout and log back in to apply Docker group permissions.")
print("===============================================")