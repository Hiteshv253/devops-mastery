#!/bin/bash
set -e

# 02-install-helm.sh
# Installs Helm 3 binary

echo "=========================================="
echo "Bootstrap Step 2: Installing Helm"
echo "=========================================="

if ! command -v helm &> /dev/null; then
  echo "Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "Helm is already installed: $(helm version --short)"
fi

echo "=========================================="
echo "Helm installation step complete!"
echo "=========================================="
