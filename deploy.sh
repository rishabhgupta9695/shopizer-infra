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
docker pull ghcr.io/$GITHUB_USER/shopizer-admin:latest

echo "==> Cleaning up existing deployments..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true
kubectl wait --for=delete namespace/$NAMESPACE --timeout=60s 2>/dev/null || true

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
kubectl get pods -n $NAMESPACE -l app=mysql --no-headers | awk '$4 > 5 {print $1}' | xargs -r kubectl delete pod -n $NAMESPACE 2>/dev/null || true

echo "==> Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=120s 2>/dev/null || \
  echo "MySQL already running, continuing..."

echo "==> Deploying backend..."
kubectl apply -f k8s/shopizer.yaml

echo "==> Deploying frontend (shop)..."
kubectl apply -f k8s/shopizer-frontend.yaml

echo "==> Deploying admin dashboard..."
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shopizer-admin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shopizer-admin
  template:
    metadata:
      labels:
        app: shopizer-admin
    spec:
      imagePullSecrets:
      - name: ghcr-secret
      containers:
      - name: shopizer-admin
        image: ghcr.io/$GITHUB_USER/shopizer-admin:latest
        ports:
        - containerPort: 80
        env:
        - name: APP_BASE_URL
          value: "http://localhost:8080/api"
---
apiVersion: v1
kind: Service
metadata:
  name: shopizer-admin
spec:
  type: NodePort
  selector:
    app: shopizer-admin
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30300
EOF

echo "==> Restarting deployments to pick up latest images..."
kubectl rollout restart deployment/shopizer -n $NAMESPACE
kubectl rollout restart deployment/shopizer-frontend -n $NAMESPACE
kubectl rollout restart deployment/shopizer-admin -n $NAMESPACE

echo "==> Waiting for rollout..."
kubectl rollout status deployment/shopizer -n $NAMESPACE --timeout=600s 2>/dev/null || true
kubectl rollout status deployment/shopizer-frontend -n $NAMESPACE --timeout=120s
kubectl rollout status deployment/shopizer-admin -n $NAMESPACE --timeout=120s

echo "==> Setting up port-forwards..."
kubectl port-forward svc/shopizer 8080:8080 -n $NAMESPACE > /tmp/pf-backend.log 2>&1 &
kubectl port-forward svc/shopizer-frontend 30200:80 -n $NAMESPACE > /tmp/pf-frontend.log 2>&1 &
kubectl port-forward svc/shopizer-admin 30300:80 -n $NAMESPACE > /tmp/pf-admin.log 2>&1 &

echo ""
echo "✅ All apps deployed!"
echo ""
echo "   Backend API  → http://localhost:8080/swagger-ui.html"
echo "   Shop         → http://localhost:30200"
echo "   Admin        → http://localhost:30300"
echo ""
kubectl get pods -n $NAMESPACE
