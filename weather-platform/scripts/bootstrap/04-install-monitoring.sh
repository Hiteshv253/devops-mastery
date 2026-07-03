#!/bin/bash
set -e

# 04-install-monitoring.sh
# Installs Prometheus & Grafana monitoring stack using Helm

echo "=========================================="
echo "Bootstrap Step 4: Installing Monitoring Stack"
echo "=========================================="

# Add prometheus-community helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
echo "Deploying kube-prometheus-stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelix=false

echo "Waiting for monitoring components to roll out..."
kubectl rollout status deployment/prometheus-grafana -n monitoring --timeout=180s || echo "Warning: Timeout waiting for Grafana rollout."

echo "=========================================="
echo "Monitoring stack setup complete!"
echo "=========================================="
