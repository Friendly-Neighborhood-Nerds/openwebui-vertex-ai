# ---------------------------------------------------------------------------
# Cloud SQL – PostgreSQL (persistent storage for Open WebUI)
# ---------------------------------------------------------------------------

resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "${var.resource_prefix}-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_size         = 10

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false # set to true for production

  depends_on = [google_service_networking_connection.private_vpc]
}

resource "google_sql_database" "openwebui" {
  name     = "openwebui"
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "google_sql_user" "openwebui" {
  name     = "openwebui"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
  project  = var.project_id
}
