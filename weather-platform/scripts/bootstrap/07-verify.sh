#!/bin/bash
set -e

# 07-verify.sh
# Verifies all bootstrapped components are installed and healthy

echo "=========================================="
echo "Bootstrap Step 7: Verifying Cluster Health"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_deployment() {
  local dep=$1
  local ns=$2
  echo -n "Checking deployment $dep in namespace $ns... "
  if kubectl get deployment "$dep" -n "$ns" >/dev/null 2>&1; then
    status=$(kubectl get deployment "$dep" -n "$ns" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [ "$status" = "True" ]; then
      echo -e "${GREEN}HEALTHY${NC}"
    else
      echo -e "${RED}UNHEALTHY / PROGRESSING${NC}"
    fi
  else
    echo -e "${YELLOW}NOT FOUND${NC}"
  fi
}

echo "1. Checking Kubernetes Nodes:"
kubectl get nodes

echo -n "2. Checking Storage Classes... "
if kubectl get storageclass | grep -q "(default)"; then
  echo -e "${GREEN}Default StorageClass exists:${NC}"
  kubectl get storageclass
else
  echo -e "${YELLOW}No default StorageClass found.${NC}"
fi

echo "3. Checking Core Deployments:"
check_deployment "ingress-nginx-controller" "kube-system"
check_deployment "prometheus-grafana" "monitoring"
check_deployment "prometheus-kube-state-metrics" "monitoring"
check_deployment "argocd-server" "argocd"
check_deployment "local-path-provisioner" "local-path-storage"
check_deployment "weather-platform" "weather"

echo ""
echo "4. Checking Pod Status in weather namespace:"
kubectl get pods -n weather || echo "No pods in weather namespace yet."

echo "=========================================="
echo "Verification complete!"
echo "=========================================="
