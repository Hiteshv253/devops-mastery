-pyhon-------------------------------------------------

.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

source .venv/bin/activate

deactivate

pip install -r requirements.txt

uvicorn app.main:app --reload

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




cleaup folders
find . \
  \( -name "__pycache__" \
  -o -name ".pytest_cache" \
  -o -name ".mypy_cache" \
  -o -name ".ruff_cache" \) \
  -type d -exec rm -rf {} + && \
find . \( -name "*.pyc" -o -name "*.pyo" \) -type f -delete



python3 -m py_compile devops_bootstrap.py // compail a code

-k8s-----------------------------------------
export KUBECONFIG=$HOME/.kube/config
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
source ~/.bashrc
kubectl get nodes
kubectl config view --minify

-Docker-----------------------------------------


docker build -t weather-platform .

docker run -d -p 8000:8000 --name weather-platform weather-platform

docker ps

docker compose up -d
docker compose down



kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

kubectl apply -f k8s/


kubectl get ns

kubectl get deploy -n weather

kubectl get pods -n weather

kubectl get svc -n weather

kubectl get ingress -n weather

kubectl get hpa -n weather