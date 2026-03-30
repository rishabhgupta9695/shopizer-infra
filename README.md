# Shopizer Kubernetes Deployment

## Prerequisites
- Colima running with Kubernetes enabled
- kubectl installed

## One-time setup

### 1. Start Colima with Kubernetes
```bash
colima start --cpu 4 --memory 6 --disk 60 --kubernetes
```

### 2. Create ghcr.io pull secret
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=rishabhgupta9695 \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=shopizer
```

## Deploy all apps

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/shopizer.yaml
kubectl apply -f k8s/shopizer-admin.yaml
kubectl apply -f k8s/shopizer-shop.yaml
```

## Check pods (should see 3 pods per app)

```bash
kubectl get pods -n shopizer
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS
mysql-xxx                         1/1     Running   0
shopizer-xxx-1                    1/1     Running   0
shopizer-xxx-2                    1/1     Running   0
shopizer-xxx-3                    1/1     Running   0
shopizer-admin-xxx-1              1/1     Running   0
shopizer-admin-xxx-2              1/1     Running   0
shopizer-admin-xxx-3              1/1     Running   0
shopizer-shop-xxx-1               1/1     Running   0
shopizer-shop-xxx-2               1/1     Running   0
shopizer-shop-xxx-3               1/1     Running   0
```

## Access the apps

```bash
# get colima IP
colima status | grep address
```

| App | URL |
|-----|-----|
| Backend | http://COLIMA_IP:8080/swagger-ui.html |
| Admin | http://COLIMA_IP:30200 |
| Shop | http://COLIMA_IP:30300 |

## After a new CI build (update to latest image)

```bash
kubectl rollout restart deployment/shopizer -n shopizer
kubectl rollout restart deployment/shopizer-admin -n shopizer
kubectl rollout restart deployment/shopizer-shop -n shopizer
```

## Tear down

```bash
kubectl delete namespace shopizer
```
