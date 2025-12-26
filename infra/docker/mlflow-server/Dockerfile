FROM python:3.10-slim-bullseye AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && npm install --global yarn \
  && rm -rf /var/lib/apt/lists/*

# Copy source
COPY . .

# Build JS frontend
WORKDIR /build/mlflow/server/js
RUN yarn install --frozen-lockfile && yarn build

# Build MLflow wheel
WORKDIR /build
RUN pip install --no-cache-dir build && python -m build --wheel

# --- Runtime stage ---
FROM python:3.10-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copy and install the wheel
COPY --from=builder /build/dist/*.whl /tmp/
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir /tmp/*.whl psycopg2-binary google-cloud-storage \
  && rm /tmp/*.whl

EXPOSE 8080

CMD ["bash", "-lc", "mlflow server --host 0.0.0.0 --port ${PORT:-8080} --backend-store-uri \"$MLFLOW_BACKEND_STORE_URI\" --default-artifact-root \"$MLFLOW_DEFAULT_ARTIFACT_ROOT\""]
