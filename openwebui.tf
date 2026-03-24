# ---------------------------------------------------------------------------
# Cloud Run – Open WebUI  (public-facing, connects to Vertex AI + Cloud SQL)
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "openwebui" {
  name     = "${var.resource_prefix}-webui"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.openwebui.email

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ghcr_remote.repository_id}/${var.openwebui_image_path}"

      ports {
        container_port = 8080
      }

      # Point Open WebUI at LiteLLM as its "OpenAI" backend
      env {
        name  = "OPENAI_API_BASE_URL"
        value = "${google_cloud_run_v2_service.litellm.uri}/v1"
      }

      env {
        name = "OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.litellm_master_key.secret_id
            version = "latest"
          }
        }
      }

      # PostgreSQL connection
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url.secret_id
            version = "latest"
          }
        }
      }

      # Session encryption key
      env {
        name = "WEBUI_SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.webui_secret_key.secret_id
            version = "latest"
          }
        }
      }

      # Disable Ollama (we only use OpenAI-compatible via Vertex AI)
      env {
        name  = "ENABLE_OLLAMA_API"
        value = "false"
      }

      env {
        name  = "OLLAMA_BASE_URL"
        value = ""
      }

      # Skip downloading sentence-transformer models at startup (blocks for minutes)
      env {
        name  = "RAG_EMBEDDING_ENGINE"
        value = "openai"
      }

      # Writable directories for Open WebUI (Cloud Run filesystem is read-only)
      env {
        name  = "DATA_DIR"
        value = "/tmp/data"
      }

      env {
        name  = "HOME"
        value = "/tmp/home"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }

      # TCP probe — just check the port is listening
      startup_probe {
        tcp_socket {
          port = 8080
        }
        initial_delay_seconds = 30
        period_seconds        = 10
        failure_threshold     = 30
        timeout_seconds       = 5
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  depends_on = [
    google_project_service.apis,
    google_cloud_run_v2_service.litellm,
    google_secret_manager_secret_version.litellm_master_key,
    google_secret_manager_secret_version.database_url,
    google_secret_manager_secret_version.webui_secret_key,
    google_project_iam_member.openwebui_secrets,
  ]
}

# Public access – Open WebUI has its own user authentication
resource "google_cloud_run_v2_service_iam_member" "openwebui_public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.openwebui.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
