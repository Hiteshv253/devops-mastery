#!/bin/bash
# -----------------------------------------------------------------------------
# DevOps Unified Run Script for Weather Platform
# -----------------------------------------------------------------------------
set -e

# Terminal Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_usage() {
    echo -e "${YELLOW}Usage: ./run.sh [start|stop|status]${NC}"
    echo "  start  - Builds the Docker image, loads it into Kubernetes (K3s), and deploys via Helm"
    echo "  stop   - Removes the application from the cluster"
    echo "  status - Shows the current status of all app resources in Kubernetes"
}

start_app() {
    echo -e "${BLUE}=== [1/3] Building Local Docker Image ===${NC}"
    docker build -t weather-platform:latest .

    echo -e "${BLUE}=== [2/3] Importing Image to K3s Container Runtime ===${NC}"
    # Save the docker image and pipe it directly to K3s containerd namespace (k8s.io)
    docker save weather-platform:latest | sudo k3s ctr images import -

    echo -e "${BLUE}=== [3/3] Deploying to Kubernetes via Helm ===${NC}"
    # Create namespace if it does not exist
    kubectl create namespace weather --dry-run=client -o yaml | kubectl apply -f -

    # Deploy the application using Helm
    # We override image repository and set pull policy to Never so it loads from the local imported image
    helm upgrade --install weather-platform ./helm/weather-platform \
      --namespace weather \
      --values ./helm/weather-platform/values-local.yaml \
      --set image.repository=weather-platform \
      --set image.tag=latest \
      --set image.pullPolicy=Never \
      --set secrets.groqApiKey="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"

    echo -e "${GREEN}======================================================="
    echo "            DEPLOYMENT COMPLETED SUCCESSFULLY"
    echo -e "=======================================================${NC}"
    echo -e "To access your application, run the port-forward command:"
    echo -e "  ${YELLOW}kubectl port-forward svc/weather-platform -n weather 8080:80${NC}"
    echo -e "Then open: ${GREEN}http://localhost:8080${NC} in your browser."
    echo -e "======================================================="
}

stop_app() {
    echo -e "${BLUE}=== Uninstalling Weather Platform ===${NC}"
    helm uninstall weather-platform -n weather || true
    kubectl delete namespace weather --ignore-not-found || true
    echo -e "${GREEN}Application uninstalled successfully!${NC}"
}

status_app() {
    echo -e "${BLUE}=== Application Status (Namespace: weather) ===${NC}"
    kubectl get all -n weather
}

# Check argument
ACTION=${1:-start}

case "$ACTION" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    status)
        status_app
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
