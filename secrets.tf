# ---------------------------------------------------------------------------
# Secret Manager – secrets consumed by Cloud Run services
# ---------------------------------------------------------------------------

# ---------- Random keys ----------

resource "random_password" "litellm_master_key" {
  length  = 32
  special = false
}

resource "random_password" "webui_secret_key" {
  length  = 32
  special = false
}

# ---------- LiteLLM config (YAML) ----------

resource "google_secret_manager_secret" "litellm_config" {
  secret_id = "${var.resource_prefix}-litellm-config"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "litellm_config" {
  secret = google_secret_manager_secret.litellm_config.id

  secret_data = yamlencode({
    model_list = [for model in var.vertex_ai_models : {
      model_name = model
      litellm_params = {
        model           = "vertex_ai/${model}"
        vertex_project  = var.project_id
        vertex_location = var.vertex_ai_region
      }
    }]
  })
}

# ---------- LiteLLM master key (shared with Open WebUI as API key) ----------

resource "google_secret_manager_secret" "litellm_master_key" {
  secret_id = "${var.resource_prefix}-litellm-master-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "litellm_master_key" {
  secret      = google_secret_manager_secret.litellm_master_key.id
  secret_data = random_password.litellm_master_key.result
}

# ---------- Database URL ----------

resource "google_secret_manager_secret" "database_url" {
  secret_id = "${var.resource_prefix}-database-url"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "database_url" {
  secret = google_secret_manager_secret.database_url.id

  secret_data = join("", [
    "postgresql://",
    google_sql_user.openwebui.name,
    ":",
    random_password.db_password.result,
    "@",
    google_sql_database_instance.main.private_ip_address,
    ":5432/",
    google_sql_database.openwebui.name,
  ])
}

# ---------- Open WebUI session secret ----------

resource "google_secret_manager_secret" "webui_secret_key" {
  secret_id = "${var.resource_prefix}-webui-secret-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "webui_secret_key" {
  secret      = google_secret_manager_secret.webui_secret_key.id
  secret_data = random_password.webui_secret_key.result
}
