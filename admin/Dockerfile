# Vite bakes VITE_* env vars in at build time (see src/lib/apiClient.ts),
# so the backend's real URL has to be a build ARG, not a runtime env var —
# docker-compose.prod.yml passes it through from the host .env file.
FROM node:20-alpine AS build
WORKDIR /app
ARG VITE_API_BASE_URL=http://localhost:3000
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
# 127.0.0.1, not localhost — nginx only binds IPv4 by default in this
# image, but `localhost` resolves to ::1 first inside the container,
# so wget hits "connection refused" against a healthy server (confirmed
# the hard way: nginx was serving the real build correctly the whole time).
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
