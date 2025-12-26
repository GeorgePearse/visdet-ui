FROM python:3.10-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system deps only if needed by wheels.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install MLflow from PyPI (includes pre-built UI)
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir mlflow psycopg2-binary google-cloud-storage

EXPOSE 8080

CMD ["bash", "-lc", "mlflow server --host 0.0.0.0 --port ${PORT:-8080} --backend-store-uri \"$MLFLOW_BACKEND_STORE_URI\" --default-artifact-root \"$MLFLOW_DEFAULT_ARTIFACT_ROOT\""]
