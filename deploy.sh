#!/bin/bash
set -e

GITHUB_USER="rishabhgupta9695"
NAMESPACE="shopizer"

echo "==> Starting Colima..."
colima start --cpu 4 --memory 6 --disk 60 --kubernetes 2>/dev/null || echo "Colima already running"

echo "==> Logging into ghcr.io..."
echo "Enter your GitHub token (read:packages scope):"
read -s GITHUB_TOKEN
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

echo "==> Pulling latest images..."
docker pull ghcr.io/$GITHUB_USER/shopizer:latest
docker pull ghcr.io/$GITHUB_USER/shopizer-frontend:latest

echo "==> Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "==> Creating image pull secret..."
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USER \
  --docker-password=$GITHUB_TOKEN \
  --namespace=$NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Deploying MySQL..."
kubectl apply -f k8s/mysql.yaml

echo "==> Cleaning up any stuck MySQL pods..."
kubectl delete pod -n $NAMESPACE -l app=mysql --field-selector=status.phase=Failed 2>/dev/null || true
# delete crash-looping pods (restarts > 5)
kubectl get pods -n $NAMESPACE -l app=mysql --no-headers | awk '$4 > 5 {print $1}' | xargs -r kubectl delete pod -n $NAMESPACE 2>/dev/null || true

echo "==> Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=120s 2>/dev/null || \
  echo "MySQL already running, continuing..."

echo "==> Deploying backend..."
kubectl apply -f k8s/shopizer.yaml

echo "==> Deploying frontend..."
kubectl apply -f k8s/shopizer-frontend.yaml

echo "==> Restarting deployments to pick up latest images..."
kubectl rollout restart deployment/shopizer -n $NAMESPACE
kubectl rollout restart deployment/shopizer-frontend -n $NAMESPACE

echo "==> Waiting for rollout..."
kubectl rollout status deployment/shopizer -n $NAMESPACE --timeout=600s
kubectl rollout status deployment/shopizer-frontend -n $NAMESPACE --timeout=120s

echo ""
echo "✅ All apps deployed!"
echo ""
echo "   Backend  → http://localhost:30080/swagger-ui.html"
echo "   Shop     → http://localhost:30200/"
echo "   Admin    → http://localhost:30200/admin/"
echo ""
kubectl get pods -n $NAMESPACE
