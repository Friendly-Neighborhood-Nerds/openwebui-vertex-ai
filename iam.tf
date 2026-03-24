# ---------------------------------------------------------------------------
# Service accounts & IAM bindings
# ---------------------------------------------------------------------------

# --- Open WebUI service account ---
resource "google_service_account" "openwebui" {
  account_id   = "${var.resource_prefix}-webui"
  display_name = "Open WebUI Cloud Run"
  project      = var.project_id
}

# --- LiteLLM service account ---
resource "google_service_account" "litellm" {
  account_id   = "${var.resource_prefix}-litellm"
  display_name = "LiteLLM Proxy Cloud Run"
  project      = var.project_id
}

# LiteLLM needs to call Vertex AI
resource "google_project_iam_member" "litellm_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.litellm.email}"
}

# Both service accounts need to read secrets
resource "google_project_iam_member" "litellm_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.litellm.email}"
}

resource "google_project_iam_member" "openwebui_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.openwebui.email}"
}

# Open WebUI needs Cloud SQL access
resource "google_project_iam_member" "openwebui_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.openwebui.email}"
}
