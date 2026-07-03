#!/bin/bash
set -e

# 03-install-ingress.sh
# Deploys Nginx Ingress Controller using Helm

echo "=========================================="
echo "Bootstrap Step 3: Installing Ingress Controller"
echo "=========================================="

# Add ingress-nginx helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress-nginx controller
echo "Deploying ingress-nginx controller..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace kube-system \
  --set controller.service.type=NodePort \
  --set controller.watchIngressWithoutClass=true

echo "Waiting for Ingress controller pods to be ready..."
kubectl rollout status deployment/ingress-nginx-controller -n kube-system --timeout=180s || echo "Warning: Timeout waiting for ingress controller rollout."

echo "=========================================="
echo "Ingress controller setup complete!"
echo "=========================================="
