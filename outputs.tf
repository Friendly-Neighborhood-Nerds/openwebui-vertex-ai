# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "openwebui_url" {
  description = "Open WebUI URL (open in browser to set up admin account)"
  value       = google_cloud_run_v2_service.openwebui.uri
}

output "cloud_sql_instance" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.main.connection_name
}
