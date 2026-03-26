# Pod-Based Deployment Diagram (Kubernetes on Colima)

```
╔═══════════════════════════════════════════════════════════════════════════════════════╗
║                            YOUR MAC  (Colima + Kubernetes)                           ║
║                                                                                       ║
║  ┌─────────────────────────────────────────────────────────────────────────────────┐  ║
║  │                          Namespace: shopizer                                    │  ║
║  │                                                                                 │  ║
║  │  ┌──────────────────┐   ┌───────────────────────────────────────────────────┐  │  ║
║  │  │   MySQL (x1)     │   │            Deployment: shopizer  (x3)             │  │  ║
║  │  │                  │   │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │  │  ║
║  │  │  ┌────────────┐  │   │  │   Pod 1     │ │   Pod 2     │ │   Pod 3     │ │  │  ║
║  │  │  │   pod      │  │◄──│  │  :8080      │ │  :8080      │ │  :8080      │ │  │  ║
║  │  │  │  mysql:8.0 │  │   │  │ Spring Boot │ │ Spring Boot │ │ Spring Boot │ │  │  ║
║  │  │  └────────────┘  │   │  └─────────────┘ └─────────────┘ └─────────────┘ │  │  ║
║  │  │  PVC: 5Gi data   │   └───────────────────────────────────────────────────┘  │  ║
║  │  └──────────────────┘                        Service: shopizer:8080             │  ║
║  │                                                                                 │  ║
║  │  ┌───────────────────────────────────────────────────────────────────────────┐  │  ║
║  │  │              Deployment: shopizer-frontend  (x3)                          │  │  ║
║  │  │         Single nginx image serving BOTH admin and shop                    │  │  ║
║  │  │                                                                           │  │  ║
║  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │  │  ║
║  │  │  │     Pod 1       │  │     Pod 2       │  │     Pod 3       │          │  │  ║
║  │  │  │  nginx:80       │  │  nginx:80       │  │  nginx:80       │          │  │  ║
║  │  │  │                 │  │                 │  │                 │          │  │  ║
║  │  │  │ /admin → Angular│  │ /admin → Angular│  │ /admin → Angular│          │  │  ║
║  │  │  │ /shop  → React  │  │ /shop  → React  │  │ /shop  → React  │          │  │  ║
║  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘          │  │  ║
║  │  └───────────────────────────────────────────────────────────────────────────┘  │  ║
║  │                         NodePort: 30200 → localhost:30200                       │  ║
║  │                                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════╝
              ▲                              ▲
              │        kubectl apply -f k8s/ │
              │                             │
╔═════════════╪═════════════════════════════╪══════════════════════════════════════════╗
║             │   ghcr.io (GitHub Container Registry)                                 ║
║  ┌──────────┴───────────┐        ┌────────┴─────────────────────────────────┐       ║
║  │  shopizer:latest     │        │       shopizer-frontend:latest           │       ║
║  │  (Spring Boot)       │        │  built from nginx/Dockerfile             │       ║
║  │                      │        │  copies admin + shop into one image      │       ║
║  └──────────────────────┘        └──────────────────────────────────────────┘       ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
              ▲                              ▲
              │                             │
   shopizer repo CI                shopizer-infra CI
   (auto on push)            ("Build Frontend Image" workflow)
              ▲                             ▲
              │                            pulls from
   git push shopizer             shopizer-admin:latest
                                 shopizer-shop:latest


ACCESS URLS
───────────
  Admin panel  →  http://localhost:30200/admin
  Storefront   →  http://localhost:30200/shop
  Backend API  →  http://localhost:8080/swagger-ui.html


POD COUNT SUMMARY
─────────────────
  mysql               1 pod   (stateful, single instance with PVC)
  shopizer            3 pods  (load balanced via ClusterIP service)
  shopizer-frontend   3 pods  (nginx, serves /admin + /shop via NodePort 30200)
  ─────────────────────────────────────────────────────────────────
  Total               7 pods


DEPLOY COMMANDS
───────────────
  colima start --cpu 4 --memory 6 --disk 60 --kubernetes
  kubectl apply -f k8s/namespace.yaml
  kubectl apply -f k8s/mysql.yaml
  kubectl apply -f k8s/shopizer.yaml
  kubectl apply -f k8s/shopizer-frontend.yaml
  kubectl get pods -n shopizer

UPDATE AFTER NEW CI BUILD
──────────────────────────
  kubectl rollout restart deployment/shopizer -n shopizer
  kubectl rollout restart deployment/shopizer-frontend -n shopizer
```
