variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for resource names (kept short)"
  type        = string
  default     = "visdet-mlflow"
}

variable "labels" {
  description = "Labels applied to supported resources"
  type        = map(string)
  default = {
    app = "mlflow"
  }
}

variable "artifact_bucket_location" {
  description = "GCS bucket location (region or multi-region)"
  type        = string
  default     = "US"
}

variable "artifact_bucket_force_destroy" {
  description = "Allow Terraform destroy to delete all objects"
  type        = bool
  default     = false
}

variable "cloudsql_tier" {
  description = "Cloud SQL tier. Keep small to limit cost."
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_disk_size_gb" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 10
}

variable "cloudsql_disk_type" {
  description = "Cloud SQL disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_HDD"
}

variable "cloudsql_deletion_protection" {
  description = "Protect Cloud SQL instance from deletion"
  type        = bool
  default     = true
}

variable "mlflow_db_name" {
  description = "Database name for MLflow"
  type        = string
  default     = "mlflow"
}

variable "mlflow_db_user" {
  description = "Database user for MLflow"
  type        = string
  default     = "mlflow"
}

variable "cloud_run_cpu" {
  description = "Cloud Run CPU"
  type        = string
  default     = "1"
}

variable "cloud_run_memory" {
  description = "Cloud Run memory"
  type        = string
  default     = "1Gi"
}

variable "cloud_run_min_instances" {
  description = "Min instances (0 reduces idle spend)"
  type        = number
  default     = 0
}

variable "cloud_run_max_instances" {
  description = "Max instances (caps spend)"
  type        = number
  default     = 2
}

variable "cloud_run_concurrency" {
  description = "Max concurrent requests per instance"
  type        = number
  default     = 80
}

variable "cloud_run_allow_unauthenticated" {
  description = "If true, allow public access to Cloud Run service"
  type        = bool
  default     = false
}

variable "mlflow_server_allowed_hosts" {
  description = "Value for MLFLOW_SERVER_ALLOWED_HOSTS. Set to restrict host header validation."
  type        = string
  # Cloud Run default domains are like *.a.run.app. Keep this permissive enough to work,
  # but not fully open by default.
  default = "*.a.run.app"
}

variable "mlflow_server_cors_allowed_origins" {
  description = "Value for MLFLOW_SERVER_CORS_ALLOWED_ORIGINS. Leave null/empty to keep default localhost-only."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Container image URI for the MLflow server (Artifact Registry recommended)"
  type        = string
}

variable "enable_budget_alerts" {
  description = "If true, create a billing budget (alerts only)"
  type        = bool
  default     = false
}

variable "billing_account_id" {
  description = "Billing account ID (required for budgets). Format: 000000-000000-000000"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_budget_alerts || (var.billing_account_id != null && var.billing_account_id != "")
    error_message = "billing_account_id must be set when enable_budget_alerts is true."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly budget amount in USD (alerts only)"
  type        = number
  default     = 50
}
