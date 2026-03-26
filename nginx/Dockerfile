# Stage 1: copy admin build from CI image
FROM ghcr.io/rishabhgupta9695/shopizer-admin:latest AS admin

# Stage 2: copy shop build from CI image
FROM ghcr.io/rishabhgupta9695/shopizer-shop:latest AS shop

# Stage 3: single nginx serving both
FROM nginx:stable-alpine

# Copy admin dist into /usr/share/nginx/admin
COPY --from=admin /usr/share/nginx/html /usr/share/nginx/admin

# Copy shop dist into /usr/share/nginx/shop
COPY --from=shop /usr/share/nginx/html /usr/share/nginx/shop

# Use combined nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
