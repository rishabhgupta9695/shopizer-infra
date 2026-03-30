# Shopizer Kubernetes Deployment

## Architecture

| Component | Image | Replicas | Port |
|-----------|-------|----------|------|
| Backend (shopizer) | ghcr.io/rishabhgupta9695/shopizer:latest | 3 | 30080 |
| Frontend (shop) | ghcr.io/rishabhgupta9695/shopizer-frontend:latest | 3 | 30200 |
| Admin | ghcr.io/rishabhgupta9695/shopizer-admin:latest | 1 | 30300 |
| MySQL | mysql:8.0 | 1 | 3306 (internal) |

## Prerequisites
- Colima running with Kubernetes enabled
- kubectl installed

## One-time setup

### 1. Start Colima with Kubernetes
```bash
colima start --cpu 4 --memory 6 --disk 60 --kubernetes
```

### 2. Create GHCR pull secret
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=rishabhgupta9695 \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=shopizer
```

## Deploy

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/shopizer.yaml
kubectl apply -f k8s/shopizer-frontend.yaml
```

### Deploy Admin (Order Stats dashboard)
```bash
kubectl apply -n shopizer -f - <<EOF
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
      containers:
      - name: shopizer-admin
        image: ghcr.io/rishabhgupta9695/shopizer-admin:latest
        ports:
        - containerPort: 80
        env:
        - name: APP_BASE_URL
          value: "http://shopizer:8080/api"
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
```

## Check status

```bash
kubectl get pods -n shopizer
kubectl get svc -n shopizer
```

Expected services:
```
NAME                TYPE        PORT(S)
mysql               ClusterIP   3306/TCP
shopizer            NodePort    8080:30080/TCP
shopizer-frontend   NodePort    80:30200/TCP
shopizer-admin      NodePort    80:30300/TCP
```

## Access the apps

Colima runs in a VM — use port-forward to access from your Mac:

```bash
kubectl port-forward svc/shopizer 8080:8080 -n shopizer &
kubectl port-forward svc/shopizer-frontend 30200:80 -n shopizer &
kubectl port-forward svc/shopizer-admin 30300:80 -n shopizer &
```

| App | URL | Credentials |
|-----|-----|-------------|
| Backend API / Swagger | http://localhost:8080/swagger-ui.html | admin@shopizer.com / password |
| Shop Frontend | http://localhost:30200 | - |
| Admin Dashboard | http://localhost:30300 | admin@shopizer.com / password |

> **Note:** When using port-forward, update the admin backend URL:
> ```bash
> kubectl set env deployment/shopizer-admin APP_BASE_URL=http://localhost:8080/api -n shopizer
> ```

## Update to latest image after CI build

```bash
kubectl rollout restart deployment/shopizer -n shopizer
kubectl rollout restart deployment/shopizer-frontend -n shopizer
kubectl rollout restart deployment/shopizer-admin -n shopizer
```

## Seed order data (for Order Stats dashboard)

```bash
MYSQL_POD=$(kubectl get pod -n shopizer -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n shopizer $MYSQL_POD -- mysql -ushopizer -pshopizer-password SALESMANAGER -e "
INSERT IGNORE INTO CUSTOMER (CUSTOMER_ID,BILLING_FIRST_NAME,BILLING_LAST_NAME,CUSTOMER_EMAIL_ADDRESS,BILLING_COUNTRY_ID,LANGUAGE_ID,MERCHANT_ID,CUSTOMER_ANONYMOUS)
VALUES (1,'Test','User','test@example.com',1,1,1,0);
INSERT IGNORE INTO ORDERS (ORDER_ID,MERCHANTID,CUSTOMER_ID,CUSTOMER_EMAIL_ADDRESS,BILLING_FIRST_NAME,BILLING_LAST_NAME,BILLING_COUNTRY_ID,ORDER_STATUS,CURRENCY_ID,ORDER_TOTAL,DATE_PURCHASED,PAYMENT_TYPE,PAYMENT_MODULE_CODE,CONFIRMED_ADDRESS,CUSTOMER_AGREED) VALUES
(1001,1,1,'test@example.com','Test','User',1,'DELIVERED',1,120.00,DATE_SUB(NOW(),INTERVAL 1 DAY),'FREE','free',1,1),
(1002,1,1,'test@example.com','Test','User',1,'ORDERED',1,200.00,DATE_SUB(NOW(),INTERVAL 3 DAY),'FREE','free',1,1),
(1003,1,1,'test@example.com','Test','User',1,'CANCELED',1,50.00,DATE_SUB(NOW(),INTERVAL 5 DAY),'FREE','free',1,1);
"
```

## Tear down

```bash
kubectl delete namespace shopizer
```
