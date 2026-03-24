# ---------------------------------------------------------------------------
# Artifact Registry – remote repository proxying ghcr.io
# Cloud Run only allows images from GCR, Artifact Registry, or Docker Hub.
# ---------------------------------------------------------------------------

resource "google_artifact_registry_repository" "ghcr_remote" {
  location      = var.region
  repository_id = "${var.resource_prefix}-ghcr"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  project       = var.project_id

  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }
  }

  depends_on = [google_project_service.apis]
}
