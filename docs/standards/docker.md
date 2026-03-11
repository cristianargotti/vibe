<!-- last-reviewed: 2026-03-11 -->

# Docker Standards

Tier 2 reference for containerization at Dafiti. All services MUST be containerized following these patterns.

## Multi-Stage Dockerfile — Node.js

```dockerfile
# ---- Base ----
FROM node:20-alpine AS base
WORKDIR /app
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# ---- Dependencies ----
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# ---- Development ----
FROM base AS dev
COPY --from=deps /app/node_modules ./node_modules
COPY . .
USER appuser
EXPOSE 3000
CMD ["npm", "run", "dev"]

# ---- Build ----
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build && npm prune --production

# ---- Production ----
FROM node:20-alpine AS prod
WORKDIR /app
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser

COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
```

## Multi-Stage Dockerfile — Python

```dockerfile
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

FROM base AS deps
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM base AS prod
RUN groupadd -g 1001 appgroup && useradd -u 1001 -g appgroup -m appuser
COPY --from=deps /install /usr/local
COPY --chown=appuser:appgroup . .
USER appuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["gunicorn", "app.main:app", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

## .dockerignore

Every project MUST include a `.dockerignore` to keep images lean and avoid leaking secrets.

```
node_modules
.git
.github
.env*
*.md
coverage
.nyc_output
dist
__pycache__
*.pyc
.venv
.terraform
*.tfstate*
docker-compose*.yml
Dockerfile*
.dockerignore
```

## Docker Compose — Development with Hot Reload

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: dev
    volumes:
      - .:/app
      - /app/node_modules # anonymous volume prevents overwrite
    ports:
      - "3000:3000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: dafiti_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  pgdata:
```

## Docker Compose — Test

```yaml
# docker-compose.test.yml
services:
  test:
    build:
      context: .
      target: dev
    command: npm run test:ci
    environment:
      DATABASE_URL: postgres://test:test@db:5432/dafiti_test
      NODE_ENV: test
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: dafiti_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    tmpfs:
      - /var/lib/postgresql/data # RAM-backed for speed
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test"]
      interval: 3s
      timeout: 2s
      retries: 10
```

## Docker Compose — Production-Like

```yaml
# docker-compose.prod.yml
services:
  app:
    build:
      context: .
      target: prod
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M
    ports:
      - "3000:3000"
```

## Layer Caching Optimization

Order Dockerfile instructions from least to most frequently changed.

```dockerfile
# GOOD — dependencies cached separately from source code
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# BAD — any source change invalidates the npm ci cache
COPY . .
RUN npm ci
```

## Secrets Handling in Build

Never bake secrets into images. Use BuildKit secrets for build-time needs.

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
COPY . .
RUN npm run build
```

```bash
# Build command
DOCKER_BUILDKIT=1 docker build --secret id=npm_token,src=.npm_token .
```

At runtime pass secrets via environment variables or mounted files — never `COPY` them.

## Key Rules

- Always pin base image tags to major-minor (e.g. `node:20-alpine`, not `node:latest`).
- Production images MUST run as non-root.
- Every service MUST define a HEALTHCHECK.
- Use `npm ci` (not `npm install`) in CI/Docker builds for reproducibility.
- Set resource limits in compose and orchestrator manifests.
