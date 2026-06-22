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