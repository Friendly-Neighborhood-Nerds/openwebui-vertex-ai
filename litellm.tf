# ---------------------------------------------------------------------------
# Cloud Run – LiteLLM Proxy  (internal-only, translates OpenAI API → Vertex AI)
# Handles OAuth2 token refresh automatically via the service account.
# ---------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "litellm" {
  name     = "${var.resource_prefix}-litellm"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.litellm.email

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ghcr_remote.repository_id}/berriai/litellm:main-latest"

      args = ["--config", "/etc/litellm/config.yaml", "--port", "4000"]

      ports {
        container_port = 4000
      }

      env {
        name = "LITELLM_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.litellm_master_key.secret_id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "litellm-config"
        mount_path = "/etc/litellm"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      startup_probe {
        tcp_socket {
          port = 4000
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 24
        timeout_seconds       = 3
      }
    }

    volumes {
      name = "litellm-config"
      secret {
        secret = google_secret_manager_secret.litellm_config.secret_id
        items {
          version = "latest"
          path    = "config.yaml"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.litellm_config,
    google_secret_manager_secret_version.litellm_master_key,
    google_project_iam_member.litellm_secrets,
  ]
}

# Allow unauthenticated calls from within the VPC (API-level auth via master key)
resource "google_cloud_run_v2_service_iam_member" "litellm_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.litellm.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
