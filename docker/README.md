# Docker Containerization & Observability Stack

This module provides the technical documentation for all containerization manifests, multi-stage build specifications, Docker Compose service configurations, and the production Prometheus/Grafana observability stack in **SnapDev**.

---

## Technical File Audit

| File Name | Targeted Role | Key Configurations & Parameters |
| --- | --- | --- |
| [`Dockerfile`](../Dockerfile) | Single-Stage Developer Build | Base: `python:3.11-slim`<br>WORKDIR: `/app`<br>Exposes: `5000`<br>CMD: `["python", "app.py"]` |
| [`Dockerfile-multi`](../Dockerfile-multi) | Multi-Stage Distroless Production Build | Stage 1: `python:3.9-slim as builder`<br>Stage 2: `gcr.io/distroless/python3-debian13`<br>ENV: `PYTHONPATH="/app/deps"` |
| [`docker-compose.yml`](../docker-compose.yml) | Standalone Application Compose | Service: `app`<br>Image: `kumar3472/snapdev:latest`<br>Container: `snapdev-app`<br>Ports: `5000:5000`<br>Restart: `unless-stopped` |
| [`docker-compose-observability.yml`](../docker-compose-observability.yml) | Full 6-Service Observability Stack | Services: `app`, `redis`, `cadvisor`, `node-exporter`, `prometheus`, `grafana`<br>Network: `snapnet`<br>Volumes: `prometheus_data`, `grafana-storage` |
| [`prometheus.yml`](../prometheus.yml) | Prometheus Scraping Specification | Global Scrape Interval: `15s`<br>Jobs: `prometheus` (`:9090`), `cAdvisor-docker` (`cadvisor:8080`), `NodeExporter` (`node-exporter:9100`) |

---

## Deep Dive: Single-Stage vs. Multi-Stage Containerization

### 1. Standard Single-Stage Dockerfile (`Dockerfile`)

The standard [`Dockerfile`](../Dockerfile) utilizes Docker's layer-caching optimization by copying `requirements.txt` independently prior to copying the application source code:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

#### Line-by-Line Technical Analysis:
- `FROM python:3.11-slim`: Selects a lightweight Debian-based Python 3.11 base image (~120MB) to reduce base layer overhead compared to full Debian.
- `WORKDIR /app`: Establishes `/app` as the absolute working directory inside the container.
- `COPY requirements.txt .`: Copies dependency definitions prior to application code so that modifying `app.py` does not invalidate the `pip install` cached layer.
- `RUN pip install -r requirements.txt`: Installs dependencies (`Flask==3.0.0`, etc.) into the container python environment.
- `COPY . .`: Copies application source code (`app.py`, `templates/`, `static/`).
- `EXPOSE 5000`: Informs container runtime that the container listens on port 5000 at runtime.
- `CMD ["python", "app.py"]`: Specifies default entrypoint command using JSON array syntax.

---

### 2. Optimized Distroless Multi-Stage Build (`Dockerfile-multi`)

The multi-stage build [`Dockerfile-multi`](../Dockerfile-multi) leverages a build stage to compile dependencies and a minimal Google Distroless runtime image to eliminate OS attack vectors:

```dockerfile
FROM python:3.9-slim as builder

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt --target=/app/deps

FROM gcr.io/distroless/python3-debian13

WORKDIR /app

COPY --from=builder /app/deps /app/deps
COPY --from=builder /app .

EXPOSE 5000

ENV PYTHONPATH="/app/deps"

CMD ["app.py"]
```

#### Line-by-Line Technical Analysis:
- `FROM python:3.9-slim as builder`: Declares Stage 1 named `builder` containing build tools, compilers, and pip package manager.
- `RUN pip install -r requirements.txt --target=/app/deps`: Installs packages into isolated directory `/app/deps` rather than global system paths.
- `FROM gcr.io/distroless/python3-debian13`: Declares Stage 2 using Google's audited Distroless Python image. Distroless images contain *only* Python runtime binaries and root certificates — omitting OS shells (`/bin/sh`, `/bin/bash`), package managers (`apt`, `dpkg`), and standard GNU utilities.
- `COPY --from=builder /app/deps /app/deps`: Copies isolated Python packages from Stage 1 into Stage 2.
- `COPY --from=builder /app .`: Copies application source code from Stage 1 into Stage 2.
- `ENV PYTHONPATH="/app/deps"`: Sets Python search path environment variable so Python imports packages from `/app/deps`.
- `CMD ["app.py"]`: Distroless entrypoint automatically passes `app.py` to the embedded Python binary.

---

## Deep Dive: Docker Compose Service Architectures

### 1. Standalone Application Compose (`docker-compose.yml`)

The standalone [`docker-compose.yml`](../docker-compose.yml) manages container deployment declaratively:

```yaml
services:
  app:
    image: kumar3472/snapdev:latest
    container_name: snapdev-app
    restart: unless-stopped

    ports:
      - "5000:5000"

    pull_policy: always
```

- `restart: unless-stopped`: Ensures automatic container recovery if the application crashes or if the host machine reboots.
- `pull_policy: always`: Instructs Docker Compose to query DockerHub for updated layer digests before starting, guaranteeing deployment of the newest image.

---

### 2. Full 6-Service Observability Stack (`docker-compose-observability.yml`)

The production monitoring configuration [`docker-compose-observability.yml`](../docker-compose-observability.yml) orchestrates 6 containers on custom bridge network `snapnet`:

```yaml
services:
  app:
    image: kumar3472/snapdev:latest
    container_name: snapdev-app
    restart: unless-stopped
    ports:
      - "5000:5000"
    pull_policy: always
    networks:
      - snapnet

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - snapnet
    depends_on:
      - redis

  redis:
    image: redis:latest
    container_name: redis
    ports:
      - "6379:6379"
    networks:
      - snapnet

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    expose:
      - 9100
    ports:
      - "9100:9100"
    networks:
      - snapnet

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    expose:
      - 9090
    ports:
      - "9090:9090"
    networks:
      - snapnet

  grafana:
    image: grafana/grafana-enterprise
    container_name: grafana
    restart: unless-stopped
    ports:
      - '3000:3000'
    networks:
      - snapnet
    volumes:
      - grafana-storage:/var/lib/grafana

networks:
  snapnet:

volumes:
  prometheus_data: {}
  grafana-storage: {}
```

#### Key Technical Volume & Command Parameters:
- **cAdvisor Volume Mounts**: Read-only access to `/rootfs`, `/sys`, `/var/lib/docker`, and read-write access to `/var/run` enables real-time sampling of Linux cgroups (`/sys/fs/cgroup`) and Docker socket events.
- **Node Exporter Host Path Commands**: `--path.procfs=/host/proc` and `--path.sysfs=/host/sys` force Node Exporter to read host OS hardware metrics rather than isolated container metrics.
- **Prometheus `--web.enable-lifecycle`**: Enables dynamic HTTP POST reload of configuration (`curl -X POST http://localhost:9090/-/reload`) without service downtime.

---

## Deep Dive: Prometheus Configuration (`prometheus.yml`)

The Prometheus scraper configuration [`prometheus.yml`](../prometheus.yml) defines timeseries collection intervals and endpoints:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
        labels:
          app: "prometheus"
    scrape_native_histograms: true

  - job_name: "cAdvisor-docker"
    static_configs:
      - targets: ["cadvisor:8080"]
        labels:
          app: "docker"

  - job_name: "NodeExporter"
    static_configs:
      - targets: ["node-exporter:9100"]
        labels:
          app: "node"
```

---

## Verification & Operational Commands

```bash
# Build standard image
docker build -t snapdev:latest .

# Build distroless image
docker build -f Dockerfile-multi -t snapdev:distroless .

# Launch full observability stack
docker compose -f docker-compose-observability.yml up -d

# Verify container health across snapnet bridge network
docker compose -f docker-compose-observability.yml ps

# View real-time logs for Prometheus target
docker logs -f prometheus

# Verify Prometheus hot reload
curl -X POST http://localhost:9090/-/reload
```
