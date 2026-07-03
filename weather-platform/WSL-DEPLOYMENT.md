# 🚀 Beginner's DevOps Learning Roadmap on WSL: Weather Platform

Welcome! This guide is designed for **DevOps beginners** ("freshers") to learn DevOps and Platform Engineering step-by-step using this **Weather Platform** project on a local WSL (Windows Subsystem for Linux) setup.

We will cover:
1. **Phase 0: Run FastAPI Locally** (Direct Python execution)
2. **Phase 1: Learn Docker** (Containerization, `Dockerfile`, `docker-compose.yml`)
3. **Phase 2: Learn Kubernetes (k8s)** (Cluster setup with `kind`, `kubectl`, and Helm charts)
4. **Phase 3: Learn Monitoring** (Prometheus & Grafana stack)
5. **Phase 4: Learn CI/CD** (GitHub Actions workflows)

---

## 🛠️ Step 0: Install WSL and Prerequisites

First, open your WSL (Ubuntu) terminal and install the basic requirements:

```bash
# Update Ubuntu package index
sudo apt-get update
sudo apt-get install -y curl wget git unzip gnupg lsb-release ca-certificates apt-transport-https software-properties-common
```

---

## ⚡ Quickstart: Run Project in a Single Command

If you want to quickly build and deploy the entire project onto your local Kubernetes cluster in one go, you can use the unified `run.sh` script in the root of the project:

### 1. Start the entire project
```bash
./run.sh start
```
This single command will:
1. Build the local Docker image `weather-platform:latest`.
2. Save and import the image directly into K3s container runtime.
3. Create the namespace and deploy the application secrets and Helm chart automatically.

### 2. View running status
```bash
./run.sh status
```

### 3. Access the application
Run the port-forward command:
```bash
kubectl port-forward svc/weather-platform -n weather 8080:80
```
Then open `http://localhost:8080` in your web browser.

### 4. Stop and Clean up
To stop and uninstall the application and clear namespaces:
```bash
./run.sh stop
```

---

## 🐍 Phase 0: Run the FastAPI App Locally (Python)

Let's run the app directly in Python to make sure it works.

### 1. Set Up Virtual Environment and Install Dependencies
Navigate to the project folder inside WSL:
```bash
cd /mnt/d/Azure-Resource/devops-mastery/weather-platform
```
Create and activate a Python virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
```
Install all required Python packages:
```bash
pip install -r requirements.txt
```

### 2. Export Groq API Key
The app uses the Groq API for its AI Chat feature. Export the API key as an environment variable:
```bash
export GROQ_API_KEY="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"
```

### 3. Run FastAPI App
Run the FastAPI development server:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Open your web browser on Windows and go to: `http://localhost:8000`. You should see the Weather Platform UI!

*To stop the app, press `Ctrl + C` in the terminal. Type `deactivate` to exit the virtual environment.*

---

## 🐳 Phase 1: Learn Docker (Containerization)

**Why Docker?** Docker packages the application code, runtime, and system libraries together into a "container" so it runs the exact same way on any machine (developer laptop, WSL, or AWS/Azure cloud).
 
### 1. View the `Dockerfile`
The `Dockerfile` contains a list of instructions on how to build the container image:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Build the Docker Image
Compile your application files into a reusable Docker image tag `weather-platform:latest`:
```bash
docker build -t weather-platform:latest .
```
Verify the image was built and is saved locally:
```bash
docker images
```

### 3. Run as a Docker Container
Run the container in detached (background) mode, mapping port 8000:
```bash
docker run -d -p 8000:8000 --name weather-app --env GROQ_API_KEY="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" weather-platform:latest
```
Check running containers:
```bash
docker ps
```
Open `http://localhost:8000` on your browser to test it.

To stop and remove the container:
```bash
docker stop weather-app
docker rm weather-app
```

### 4. Run with Docker Compose
**Why Docker Compose?** It helps run multi-container applications easily using a simple `docker-compose.yml` file.

To start the app:
```bash
docker compose up -d
```
Check running services and container health:
```bash
docker compose ps
```
To stop the app and clean up resources:
```bash
docker compose down
```

---

## ☸️ Phase 2: Learn Kubernetes (k8s)

**Why Kubernetes?** While Docker is great for running individual containers, Kubernetes manages containers across multiple machines. It handles scaling, automatic recovery (healing), load balancing, and zero-downtime updates.

### 1. Install kubectl & kind (Kubernetes in Docker)
Inside WSL, run:
```bash
# Install kubectl
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version
```

### 2. Create a Local Kubernetes Cluster
Create a 2-node cluster (1 Control Plane, 1 Worker Node):
```bash
cat > kind-config.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
EOF

kind create cluster --name weather-local --config kind-config.yaml
```
Verify the nodes are running:
```bash
kubectl get nodes
```

### 3. Load the Local Docker Image into Kind
Since we built our image locally, we must tell `kind` about it so it doesn't try to pull it from the public internet (GitHub/DockerHub):
```bash
kind load docker-image weather-platform:latest --name weather-local
```

### 4. Install Helm
**Why Helm?** Helm is a package manager for Kubernetes (like `npm` for Node.js or `pip` for Python). It allows grouping multiple Kubernetes resource files (Deployments, Services, ConfigMaps, Secrets) into a single "Chart" and managing them as a single release package.

Install Helm CLI:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 5. Deploy App using Helm Chart
Deploy the app into the `weather` namespace using the Helm chart at `helm/weather-platform/`:
```bash
# Create namespace
kubectl create namespace weather

# Deploy with Helm using local overrides
helm upgrade --install weather-platform ./helm/weather-platform \
  --namespace weather \
  --values ./helm/weather-platform/values-local.yaml \
  --set image.repository=weather-platform \
  --set image.tag=latest \
  --set secrets.groqApiKey="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"
```
Verify pods and services are deployed:
```bash
kubectl get all -n weather
```

### 6. Access the Application
Since we are using WSL/kind, we can use port-forwarding to access the app:
```bash
kubectl port-forward svc/weather-platform -n weather 8080:80
```
Open `http://localhost:8080` in your web browser. 

*Press `Ctrl + C` in the terminal to stop port forwarding.*

---

## 📊 Phase 3: Learn Monitoring (Prometheus & Grafana)

**Why Monitoring?** To know how much CPU/Memory the app uses, how many users are accessing it, and whether any errors or crashes are happening.

### 1. Deploy the Monitoring Stack
Add the Prometheus community Helm repository:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
Install the Prometheus & Grafana stack:
```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelix=false
```
Wait a few minutes for pods to start:
```bash
kubectl get pods -n monitoring
```

### 2. Access Grafana Dashboard
Port-forward Grafana to access its UI:
```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```
Open `http://localhost:3000` in your browser.
- **Username**: `admin`
- **Password**: `4Pk67AC014VO5Gm3RFzYZH2510tFOTdVg2vJ11bQ` (Retrieve using secret decode if needed)

Here you can view default Kubernetes dashboards showing node CPU usage, memory usage, and cluster health!

---

## 🐙 Phase 4: Learn GitOps (ArgoCD)

**Why ArgoCD?** ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It monitors your Git repository for changes to your Helm/Kubernetes files and automatically syncs them to your cluster.

### 1. Retrieve the ArgoCD Admin Password
ArgoCD generates a random password on setup. Run the following command in WSL to retrieve it:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode ; echo
```
*(Decoded default password for your current deployment: `cTiwfh1N4mXecHc5`)*

### 2. Access the ArgoCD Web UI
Port-forward the ArgoCD server:
```bash
kubectl port-forward svc/argocd-server -n argocd 8083:443
```
Open **`https://localhost:8083`** in your browser. (Accept the self-signed certificate warning).
* **Username**: `admin`
* **Password**: `cTiwfh1N4mXecHc5`

### 3. Deploy App via GitOps
Apply the ArgoCD Application manifest provided in the project root:
```bash
kubectl apply -f argocd-app.yaml
```
ArgoCD will automatically download the Helm chart configurations from your Git repository and deploy/sync the application under the `weather` namespace!

---

## 🔄 Phase 5: Learn CI/CD (GitHub Actions)

**Why CI/CD?** Instead of building images and deploying manually, CI/CD pipelines automate this on every code commit.

Explore the `.github/workflows/application.yml` file. It automatically runs:
1. **Linter & Tests**: Runs Python code checks.
2. **Docker Build**: Builds the docker image on Git push.
3. **Security Scan**: Checks for vulnerabilities using Trivy.
4. **Deploy**: Deploys/upgrades the helm chart automatically.

---

## 🧹 Teardown (Clean up Everything)

To delete all Kubernetes resources and clean up your computer:

```bash
# Delete kind cluster
kind delete cluster --name weather-local
```
