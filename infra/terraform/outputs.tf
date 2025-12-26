output "artifact_bucket" {
  description = "GCS bucket for MLflow artifacts"
  value       = google_storage_bucket.artifacts.name
}

output "cloudsql_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.mlflow.connection_name
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.mlflow.name
}

output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.mlflow.uri
}

output "artifact_registry_repo" {
  description = "Artifact Registry Docker repository"
  value       = google_artifact_registry_repository.docker.id
}
