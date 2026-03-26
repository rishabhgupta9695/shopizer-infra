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
║  │  │                   Deployment: shopizer-admin  (x3)                        │  │  ║
║  │  │  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐             │  │  ║
║  │  │  │   Pod 1     │       │   Pod 2     │       │   Pod 3     │             │  │  ║
║  │  │  │  nginx:80   │       │  nginx:80   │       │  nginx:80   │             │  │  ║
║  │  │  │  Angular    │       │  Angular    │       │  Angular    │             │  │  ║
║  │  │  └─────────────┘       └─────────────┘       └─────────────┘             │  │  ║
║  │  └───────────────────────────────────────────────────────────────────────────┘  │  ║
║  │                              NodePort: 30200 → localhost:30200                  │  ║
║  │                                                                                 │  ║
║  │  ┌───────────────────────────────────────────────────────────────────────────┐  │  ║
║  │  │                   Deployment: shopizer-shop  (x3)                         │  │  ║
║  │  │  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐             │  │  ║
║  │  │  │   Pod 1     │       │   Pod 2     │       │   Pod 3     │             │  │  ║
║  │  │  │  nginx:80   │       │  nginx:80   │       │  nginx:80   │             │  │  ║
║  │  │  │   React     │       │   React     │       │   React     │             │  │  ║
║  │  │  └─────────────┘       └─────────────┘       └─────────────┘             │  │  ║
║  │  └───────────────────────────────────────────────────────────────────────────┘  │  ║
║  │                              NodePort: 30300 → localhost:30300                  │  ║
║  │                                                                                 │  ║
║  └─────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                       ║
╚═══════════════════════════════════════════════════════════════════════════════════════╝
              ▲                    ▲                    ▲
              │           kubectl apply -f k8s/         │
              │                                         │
╔═════════════╪═════════════════════════════════════════╪═════════════════════════════╗
║             │      ghcr.io (GitHub Container Registry)│                             ║
║  ┌──────────┴───────┐  ┌──────────────────┐  ┌───────┴──────────┐                 ║
║  │ shopizer:latest  │  │shopizer-admin:   │  │ shopizer-shop:   │                 ║
║  │                  │  │      latest      │  │     latest       │                 ║
║  └──────────────────┘  └──────────────────┘  └──────────────────┘                 ║
╚═════════════════════════════════════════════════════════════════════════════════════╝
              ▲                    ▲                    ▲
              │         GitHub Actions pushes images    │
              └────────────────────┴────────────────────┘


ACCESS URLS
───────────
  Admin panel  →  http://localhost:30200
  Storefront   →  http://localhost:30300
  Backend API  →  http://localhost:8080/swagger-ui.html


POD COUNT SUMMARY
─────────────────
  mysql           1 pod   (stateful, single instance)
  shopizer        3 pods  (load balanced via ClusterIP service)
  shopizer-admin  3 pods  (load balanced via NodePort 30200)
  shopizer-shop   3 pods  (load balanced via NodePort 30300)
  ─────────────────────────────────────────────────────
  Total           10 pods


DEPLOY COMMANDS
───────────────
  colima start --cpu 4 --memory 6 --disk 60 --kubernetes
  kubectl apply -f k8s/namespace.yaml
  kubectl apply -f k8s/mysql.yaml
  kubectl apply -f k8s/shopizer.yaml
  kubectl apply -f k8s/shopizer-admin.yaml
  kubectl apply -f k8s/shopizer-shop.yaml
  kubectl get pods -n shopizer

UPDATE AFTER NEW CI BUILD
──────────────────────────
  kubectl rollout restart deployment/shopizer -n shopizer
  kubectl rollout restart deployment/shopizer-admin -n shopizer
  kubectl rollout restart deployment/shopizer-shop -n shopizer
```
