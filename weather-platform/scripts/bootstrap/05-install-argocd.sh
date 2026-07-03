#!/bin/bash
set -e

# 05-install-argocd.sh
# Installs ArgoCD GitOps engine using Helm

echo "=========================================="
echo "Bootstrap Step 5: Installing ArgoCD"
echo "=========================================="

# Add argo helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install argo-cd
echo "Deploying ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP

echo "Waiting for ArgoCD server to roll out..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s || echo "Warning: Timeout waiting for ArgoCD rollout."

# Output initial password retrieval instruction
echo ""
echo "ArgoCD admin initial password retrieval command:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"

echo "=========================================="
echo "ArgoCD setup complete!"
echo "=========================================="
