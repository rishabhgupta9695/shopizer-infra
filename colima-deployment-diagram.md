# Local CI-CD Deployment Diagram

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                          YOUR MAC  (Colima VM)                                 ║
║                                                                                  ║
║   ┌─────────────────────────────────────────────────────────────────────────┐   ║
║   │                        docker-compose up                                │   ║
║   └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                  ║
║  ┌──────────────┐    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    ║
║  │   🟡 MySQL   │    │  🟢 Backend  │   │  🔵  Admin   │   │  🟠  Shop   │    ║
║  │              │    │              │   │              │   │              │    ║
║  │  mysql:8.0   │◄───│  shopizer    │   │shopizer-admin│   │shopizer-shop │    ║
║  │              │    │  :8080       │   │  :4200       │   │  :3000       │    ║
║  │  stores all  │    │  Spring Boot │   │  Angular     │   │  React       │    ║
║  │  order data  │    │  REST API    │   │  Admin UI    │   │  Storefront  │    ║
║  └──────────────┘    └──────────────┘   └──────────────┘   └──────────────┘    ║
║                             ▲                  ▲                  ▲             ║
╚═════════════════════════════╪══════════════════╪══════════════════╪═════════════╝
                              │                  │                  │
                              │    pulls images  │                  │
                              ▼                  ▼                  ▼
╔══════════════════════════════════════════════════════════════════════════════════╗
║                         ghcr.io  (GitHub Container Registry)                   ║
║                                                                                  ║
║   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐             ║
║   │  📦 shopizer     │  │  📦 shopizer     │  │  📦 shopizer     │             ║
║   │     :latest      │  │   -admin:latest  │  │   -shop:latest   │             ║
║   └──────────────────┘  └──────────────────┘  └──────────────────┘             ║
╚══════════════════════════════════════════════════════════════════════════════════╝
                              ▲                  ▲                  ▲
                              │   pushes images  │                  │
                              │                  │                  │
╔══════════════════════════════════════════════════════════════════════════════════╗
║                         GitHub Actions  (CI Pipeline)                           ║
║                                                                                  ║
║   ┌────────────────┐    ┌────────────────┐    ┌────────────────┐                ║
║   │  1. Checkout   │    │  1. Checkout   │    │  1. Checkout   │                ║
║   │  2. Build JAR  │    │  2. npm build  │    │  2. npm build  │                ║
║   │  3. Run tests  │    │  3. Run tests  │    │  3. Run tests  │                ║
║   │  4. Docker     │    │  4. Docker     │    │  4. Docker     │                ║
║   │     build+push │    │     build+push │    │     build+push │                ║
║   │                │    │                │    │                │                ║
║   │  shopizer repo │    │ shopizer-admin │    │  shopizer-shop │                ║
║   └────────────────┘    └────────────────┘    └────────────────┘                ║
╚══════════════════════════════════════════════════════════════════════════════════╝
                              ▲                  ▲                  ▲
                              │    git push      │                  │
                              │                  │                  │
╔══════════════════════════════════════════════════════════════════════════════════╗
║                              YOU  (Developer)                                   ║
║                                                                                  ║
║        git push main          docker-compose pull && docker-compose up -d       ║
║        ─────────────►                    ◄──────────────────────────────        ║
║        triggers CI                       deploys latest to localhost             ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

## Layer Summary

| Layer | What it is |
|-------|-----------|
| Your Mac (Colima) | Where the apps actually run locally |
| ghcr.io | Where Docker images are stored |
| GitHub Actions | Where code gets built and packaged |
| You | Where it all starts |

## The two actions you do

1. `git push` → triggers CI → image lands in ghcr.io
2. `docker-compose pull && docker-compose up -d` → pulls from ghcr.io → runs on your Mac
