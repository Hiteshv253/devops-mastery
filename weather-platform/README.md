# Weather Platform - Fully Automated Deployment

A modern weather application with AI-powered chat capabilities, deployed using platform engineering best practices with fully automated CI/CD pipeline.

## 🚀 Features

- FastAPI-based weather application
- AI chat integration using Groq API
- Fully automated CI/CD pipeline with GitHub Actions
- GitOps deployment with ArgoCD
- Kubernetes deployment with auto-scaling (HPA)
- Prometheus & Grafana monitoring
- Health checks and readiness probes
- Resource limits and requests
- Secrets management

## 📋 Prerequisites

### Local Development
- Python 3.12+
- Docker & Docker Compose
- Git

### Production Deployment
- Kubernetes cluster (K3s/minikube/AKS/GKE)
- kubectl configured
- GitHub account with Container Registry enabled
- ArgoCD installed in cluster
- Prometheus Operator installed (for ServiceMonitor)

## 🔧 Local Development Setup

### 1. Clone the Repository
```bash
git clone https://github.com/Hiteshv253/devops-mastery.git
cd devops-mastery/weather-platform
```

### 2. Set Up Virtual Environment
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Set Environment Variables
```bash
export GROQ_API_KEY=your_api_key_here
```

### 4. Run Locally
```bash
uvicorn app.main:app --reload
```

Access at: http://localhost:8000

### 5. Run with Docker Compose
```bash
# Build and run
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

## 🚢 Production Deployment

### Option 1: Automated CI/CD Pipeline (Recommended)

#### GitHub Secrets Configuration
Add the following secrets to your GitHub repository:

1. **KUBE_CONFIG**: Base64-encoded kubeconfig file
   ```bash
   cat ~/.kube/config | base64 -w 0
   ```

2. **ARGOCD_SERVER**: ArgoCD server URL (e.g., `argocd.example.com`)

3. **ARGOCD_TOKEN**: ArgoCD authentication token
   ```bash
   argocd account generate-token --account <username>
   ```

#### Pipeline Triggers
- **Push to main**: Triggers full CI/CD pipeline (test → build → deploy)
- **Pull Request**: Triggers tests only

#### Pipeline Stages
1. **Test**: Runs pytest tests
2. **Build & Push**: Builds Docker image and pushes to GHCR
3. **Deploy to K8s**: Applies Kubernetes manifests
4. **ArgoCD Sync**: Syncs application with GitOps

### Option 2: Manual Kubernetes Deployment

#### 1. Install DevOps Tools (Bootstrap)
```bash
sudo python3 devops_bootstrap.py
```

This installs:
- Docker
- kubectl
- Helm
- Terraform
- K3s (lightweight Kubernetes)
- Jenkins
- Prometheus & Grafana
- ArgoCD

#### 2. Configure Secrets
```bash
# Edit the secrets file with your actual API key
kubectl create namespace weather
kubectl apply -f k8s/secrets.yaml
```

Or create secret manually:
```bash
kubectl create secret generic weather-secrets \
  --from-literal=groq-api-key=your_actual_api_key \
  -n weather
```

#### 3. Deploy to Kubernetes
```bash
# Apply all manifests
kubectl apply -f k8s/

# Or apply individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/servicemonitor.yaml
```

#### 4. Verify Deployment
```bash
# Check pods
kubectl get pods -n weather

# Check services
kubectl get svc -n weather

# Check ingress
kubectl get ingress -n weather

# Check HPA
kubectl get hpa -n weather

# Check deployment status
kubectl rollout status deployment/weather-app -n weather
```

### Option 3: GitOps with ArgoCD

#### 1. Install ArgoCD (if not already installed)
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 2. Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Default credentials:
- Username: `admin`
- Password: (get with: `argocd admin initial-password -n argocd`)

#### 3. Create Application
```bash
kubectl apply -f k8s/application.yaml
```

Or via CLI:
```bash
argocd app create weather-platform \
  --repo https://github.com/Hiteshv253/devops-mastery.git \
  --path weather-platform/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace weather \
  --sync-policy automated
```

## 📊 Monitoring

### Access Grafana
```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```

Access at: http://localhost:3000

### Access Prometheus
```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

Access at: http://localhost:9090

### View Metrics
The application includes a ServiceMonitor for Prometheus integration. Metrics are automatically scraped from the `/` endpoint.

## 🔍 Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n weather
kubectl logs <pod-name> -n weather
```

### Image Pull Errors
Ensure the image tag in `k8s/deployment.yaml` matches the built image:
```bash
kubectl get deployment weather-app -n weather -o yaml | grep image:
```

### Secret Issues
Verify secret exists:
```bash
kubectl get secret weather-secrets -n weather
kubectl describe secret weather-secrets -n weather
```

### HPA Not Scaling
Check metrics server:
```bash
kubectl top pods -n weather
kubectl get hpa weather-app -n weather -o yaml
```

## 🛠️ Architecture

### Components
- **FastAPI Application**: Weather & chat services
- **Kubernetes**: Container orchestration
- **ArgoCD**: GitOps continuous delivery
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **HPA**: Horizontal Pod Autoscaler

### Deployment Flow
```
Git Push → GitHub Actions → Build Image → Push to GHCR → Update K8s → ArgoCD Sync → Application Deployed
```

## 📝 Configuration Files

- **`.github/workflows/ci-cd.yml`**: CI/CD pipeline
- **`k8s/deployment.yaml`**: Kubernetes deployment with health checks
- **`k8s/service.yaml`**: Kubernetes service
- **`k8s/ingress.yaml`**: Ingress configuration
- **`k8s/hpa.yaml`**: Horizontal Pod Autoscaler
- **`k8s/secrets.yaml`**: API key secrets
- **`k8s/servicemonitor.yaml`**: Prometheus monitoring
- **`k8s/application.yaml`**: ArgoCD application manifest
- **`Dockerfile`**: Container image definition
- **`docker-compose.yml`**: Local development setup

## 🔐 Security Best Practices

1. **Never commit secrets**: Use Kubernetes secrets or GitHub secrets
2. **Use image tags**: Avoid `:latest` in production
3. **Resource limits**: Prevent resource exhaustion
4. **Network policies**: Restrict pod-to-pod communication
5. **RBAC**: Limit Kubernetes permissions
6. **Scan images**: Use tools like Trivy for vulnerability scanning

## 🚀 Scaling

The HPA is configured to:
- **Min replicas**: 2
- **Max replicas**: 5
- **Target CPU utilization**: 70%

Adjust in `k8s/hpa.yaml` as needed.

## 📞 Support

For issues or questions:
- Check pod logs: `kubectl logs -n weather`
- Check ArgoCD sync status: `argocd app get weather-platform`
- Review GitHub Actions logs in your repository

## 🔄 Updating the Application

### Automatic (GitOps)
Simply push to the main branch. ArgoCD will automatically sync the changes.

### Manual
```bash
git pull
kubectl apply -f k8s/
kubectl rollout restart deployment/weather-app -n weather
```

## 📚 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argoproj.github.io/argo-cd/)
- [Prometheus Documentation](https://prometheus.io/docs/)
