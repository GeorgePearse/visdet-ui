provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  # Some GCP resources have short name limits; keep suffixes compact.
  service_name   = "${var.name_prefix}-server"
  artifacts_name = replace(var.name_prefix, "_", "-")
}

resource "google_project_service" "services" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "docker" {
  depends_on = [google_project_service.services]

  location      = var.region
  repository_id = "${local.artifacts_name}-docker"
  description   = "Docker images for MLflow tracking server"
  format        = "DOCKER"
  labels        = var.labels
}

resource "google_storage_bucket" "artifacts" {
  depends_on = [google_project_service.services]

  name                        = "${var.project_id}-${local.artifacts_name}-artifacts"
  location                    = var.artifact_bucket_location
  uniform_bucket_level_access = true
  force_destroy               = var.artifact_bucket_force_destroy

  versioning {
    enabled = false
  }

  labels = var.labels
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "db_password" {
  depends_on = [google_project_service.services]

  secret_id = "${local.artifacts_name}-db-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_sql_database_instance" "mlflow" {
  depends_on = [google_project_service.services]

  name                = "${local.artifacts_name}-sql"
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = var.cloudsql_deletion_protection

  settings {
    tier              = var.cloudsql_tier
    disk_size         = var.cloudsql_disk_size_gb
    disk_type         = var.cloudsql_disk_type
    activation_policy = "ALWAYS"

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = false
    }

    user_labels = var.labels
  }
}

resource "google_sql_database" "mlflow" {
  name     = var.mlflow_db_name
  instance = google_sql_database_instance.mlflow.name
}

resource "google_sql_user" "mlflow" {
  name     = var.mlflow_db_user
  instance = google_sql_database_instance.mlflow.name
  password = random_password.db_password.result
}

resource "google_service_account" "mlflow" {
  depends_on = [google_project_service.services]

  account_id   = substr(replace("${local.artifacts_name}-sa", "_", "-"), 0, 28)
  display_name = "MLflow Cloud Run runtime"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.mlflow.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mlflow.email}"
}

resource "google_storage_bucket_iam_member" "artifacts_rw" {
  bucket = google_storage_bucket.artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.mlflow.email}"
}

resource "google_cloud_run_v2_service" "mlflow" {
  depends_on = [
    google_project_service.services,
    google_project_iam_member.cloudsql_client,
    google_project_iam_member.secret_accessor,
    google_storage_bucket_iam_member.artifacts_rw,
  ]

  name     = local.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.mlflow.email
    max_instance_request_concurrency = var.cloud_run_concurrency

    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    containers {
      image = var.container_image

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
      }

      env {
        name  = "MLFLOW_DB_USER"
        value = var.mlflow_db_user
      }

      env {
        name  = "MLFLOW_DB_NAME"
        value = var.mlflow_db_name
      }

      env {
        name  = "MLFLOW_DB_CONNECTION_NAME"
        value = google_sql_database_instance.mlflow.connection_name
      }

      env {
        name = "MLFLOW_DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "MLFLOW_DEFAULT_ARTIFACT_ROOT"
        value = "gs://${google_storage_bucket.artifacts.name}/mlflow"
      }

      env {
        name  = "MLFLOW_SERVER_ALLOWED_HOSTS"
        value = var.mlflow_server_allowed_hosts
      }

      dynamic "env" {
        for_each = var.mlflow_server_cors_allowed_origins == null || var.mlflow_server_cors_allowed_origins == "" ? [] : [1]
        content {
          name  = "MLFLOW_SERVER_CORS_ALLOWED_ORIGINS"
          value = var.mlflow_server_cors_allowed_origins
        }
      }

      env {
        name  = "MLFLOW_SERVER_ENABLE_JOB_EXECUTION"
        value = "false"
      }

      # Cloud Run sets $PORT
      command = ["bash", "-lc"]
      args = [
        join(" ", [
          "mlflow server",
          "--host 0.0.0.0",
          "--port $PORT",
          "--backend-store-uri \"postgresql+psycopg2://$MLFLOW_DB_USER:$MLFLOW_DB_PASSWORD@/$MLFLOW_DB_NAME?host=/cloudsql/$MLFLOW_DB_CONNECTION_NAME\"",
          "--default-artifact-root \"$MLFLOW_DEFAULT_ARTIFACT_ROOT\"",
        ]),
      ]

      ports {
        container_port = 8080
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.mlflow.connection_name]
      }
    }
  }

  labels = var.labels
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.cloud_run_allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.mlflow.name
  location = google_cloud_run_v2_service.mlflow.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_billing_budget" "project_monthly" {
  provider = google-beta
  count    = var.enable_budget_alerts ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "${var.project_id} monthly budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(floor(var.monthly_budget_usd))
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }
}
