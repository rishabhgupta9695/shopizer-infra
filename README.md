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
- GitHub token with `read:packages` scope

## Deploy (one command)

```bash
./deploy.sh
```

The script will:
1. Start Colima with Kubernetes (if not running)
2. Prompt for your GitHub token to pull images from GHCR
3. Deploy MySQL, backend, shop frontend and admin dashboard
4. Set up port-forwards so all apps are accessible on localhost

## Access the apps

After running `deploy.sh`:

| App | URL | Credentials |
|-----|-----|-------------|
| Backend API / Swagger | http://localhost:8080/swagger-ui.html | admin@shopizer.com / password |
| Shop Frontend | http://localhost:30200 | - |
| Admin Dashboard | http://localhost:30300 | admin@shopizer.com / password |

## Check status

```bash
kubectl get pods -n shopizer
kubectl get svc -n shopizer
```

## Update to latest images after a CI build

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
