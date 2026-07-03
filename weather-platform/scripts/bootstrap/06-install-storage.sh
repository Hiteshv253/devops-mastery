#!/bin/bash
set -e

# 06-install-storage.sh
# Installs storage provisioner for local development (Rancher Local Path Provisioner)

echo "=========================================="
echo "Bootstrap Step 6: Installing Local Storage"
echo "=========================================="

echo "Applying Rancher Local Path Provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml

echo "Setting local-path storageclass as default..."
# Patch local-path storageclass to be the default
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

# Wait for local path provisioner pods
kubectl rollout status deployment/local-path-provisioner -n local-path-storage --timeout=120s || echo "Warning: Local storage provisioner rollout timeout."

echo "=========================================="
echo "Local Storage installation complete!"
echo "=========================================="
